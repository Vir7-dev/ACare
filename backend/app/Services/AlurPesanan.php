<?php

namespace App\Services;

use App\Models\DetailPesanan;
use App\Models\Pembayaran;
use App\Models\Pendapatan;
use App\Models\Pesanan;
use App\Models\Teknisi;
use App\Support\Jarak;
use Illuminate\Support\Facades\DB;

/**
 * Perpindahan status pesanan yang melibatkan lebih dari satu pihak:
 * pembayaran lunas, pencarian dan tawaran teknisi, biaya tambahan, selesai.
 *
 * Batas waktu (tawaran 30 detik, persetujuan biaya 5 menit, pencarian
 * 15 menit) diperiksa lewat perbarui(): dipanggil setiap ada permintaan
 * yang menyangkut pesanan itu, dan tiap menit oleh perintah pesanan:proses.
 */
class AlurPesanan
{
    /** Teknisi dengan lokasi lebih lama dari ini dianggap tidak aktif. */
    public const LOKASI_KEDALUWARSA_MENIT = 30;

    /** Jarak terjauh teknisi yang ditawari pesanan. */
    public const RADIUS_KM = 20;

    // ---------- Pembayaran ----------

    /** Dipanggil saat pembayaran lunas (webhook Xendit atau simulasi). */
    public function pembayaranBerhasil(Pembayaran $pembayaran, ?string $metode = null): void
    {
        if ($pembayaran->status_pembayaran === Pembayaran::BERHASIL) {
            return; // webhook yang sama bisa datang lebih dari sekali
        }

        DB::transaction(function () use ($pembayaran, $metode) {
            $pembayaran->update([
                'status_pembayaran' => Pembayaran::BERHASIL,
                'waktu_pembayaran' => now(),
                'metode_pembayaran' => $metode ?? $pembayaran->metode_pembayaran,
            ]);
            $pesanan = $pembayaran->pesanan;

            if ($pembayaran->jenis_pembayaran === Pembayaran::AWAL) {
                if ($pesanan->status_pesanan === Pesanan::MENCARI_TEKNISI) {
                    $pesanan->update(['pencarian_dimulai_pada' => now(), 'teknisi_menolak' => []]);
                    $this->tawarkanBerikutnya($pesanan);
                } elseif ($pesanan->status_pesanan === Pesanan::DIBATALKAN) {
                    // Dibayar setelah dibatalkan: dana ditahan untuk refund.
                    $pembayaran->update(['status_pembayaran' => Pembayaran::TERTAHAN]);
                }
            } elseif ($pesanan->status_pesanan === Pesanan::MENUNGGU_PEMBAYARAN) {
                $this->selesai($pesanan);
            }
        });
    }

    // ---------- Pencarian dan tawaran teknisi ----------

    /**
     * Periksa batas waktu pesanan ini lalu jalankan langkah berikutnya.
     * Aman dipanggil berulang kali.
     */
    public function perbarui(Pesanan $pesanan): Pesanan
    {
        if ($pesanan->status_pesanan === Pesanan::MENCARI_TEKNISI && $pesanan->pencarian_dimulai_pada) {
            $this->perbaruiPencarian($pesanan);
        } elseif ($pesanan->batasPersetujuanLewat()) {
            $this->tanggapiBiaya($pesanan, false);
        }

        return $pesanan;
    }

    private function perbaruiPencarian(Pesanan $pesanan): void
    {
        DB::transaction(function () use ($pesanan) {
            $pesanan = Pesanan::query()->lockForUpdate()->find($pesanan->id_pesanan) ?? $pesanan;
            if ($pesanan->status_pesanan !== Pesanan::MENCARI_TEKNISI) {
                return;
            }

            $ditawari = $pesanan->id_teknisi_ditawari;
            if ($ditawari && $pesanan->batas_tawaran?->isPast()) {
                // Tidak dijawab dalam batas waktu = dianggap menolak.
                $this->catatMenolak($pesanan, $ditawari);
                $ditawari = null;
            }

            if ($pesanan->pencarian_dimulai_pada->copy()->addMinutes(Pesanan::BATAS_PENCARIAN_MENIT)->isPast()) {
                $this->batalkanTanpaTeknisi($pesanan);

                return;
            }

            if (! $ditawari) {
                $this->tawarkanBerikutnya($pesanan);
            }
        });
    }

    /** Tawarkan ke teknisi terdekat yang tersedia dan belum menolak. */
    public function tawarkanBerikutnya(Pesanan $pesanan): ?Teknisi
    {
        $teknisi = $this->teknisiTerdekat($pesanan);

        $pesanan->update([
            'id_teknisi_ditawari' => $teknisi?->id_pengguna,
            'batas_tawaran' => $teknisi ? now()->addSeconds(Pesanan::BATAS_TAWARAN_DETIK) : null,
        ]);

        return $teknisi;
    }

    private function teknisiTerdekat(Pesanan $pesanan): ?Teknisi
    {
        $lokasi = $pesanan->lokasi;
        $menolak = $pesanan->teknisi_menolak ?? [];

        // Teknisi yang sedang mengerjakan atau sedang ditawari pesanan lain.
        $sibuk = Pesanan::query()->whereIn('status_pesanan', Pesanan::STATUS_DIKERJAKAN_TEKNISI)
            ->whereNotNull('id_teknisi')->pluck('id_teknisi');
        $sedangDitawari = Pesanan::query()->where('status_pesanan', Pesanan::MENCARI_TEKNISI)
            ->whereKeyNot($pesanan->id_pesanan)
            ->whereNotNull('id_teknisi_ditawari')->pluck('id_teknisi_ditawari');

        return Teknisi::query()
            ->where('status_verifikasi', 'terverifikasi')
            ->where('status_ketersediaan', 'tersedia')
            ->whereNotNull('latitude')
            ->where('lokasi_diperbarui_pada', '>=', now()->subMinutes(self::LOKASI_KEDALUWARSA_MENIT))
            ->whereNotIn('id_pengguna', [...$menolak, ...$sibuk, ...$sedangDitawari])
            ->whereHas('pengguna', fn ($q) => $q->where('status_akun', 'aktif'))
            ->get()
            ->map(fn (Teknisi $t) => [$t, Jarak::km(
                (float) $lokasi->latitude, (float) $lokasi->longitude,
                (float) $t->latitude, (float) $t->longitude,
            )])
            ->filter(fn ($p) => $p[1] <= self::RADIUS_KM)
            ->sortBy(fn ($p) => $p[1])
            ->first()[0] ?? null;
    }

    public function terimaTawaran(Pesanan $pesanan, Teknisi $teknisi): bool
    {
        return DB::transaction(function () use ($pesanan, $teknisi) {
            $p = Pesanan::query()->lockForUpdate()->find($pesanan->id_pesanan);
            $masihBerlaku = $p
                && $p->status_pesanan === Pesanan::MENCARI_TEKNISI
                && (int) $p->id_teknisi_ditawari === (int) $teknisi->id_pengguna
                && $p->batas_tawaran?->isFuture();
            if (! $masihBerlaku) {
                return false;
            }

            $p->update([
                'id_teknisi' => $teknisi->id_pengguna,
                'id_teknisi_ditawari' => null,
                'batas_tawaran' => null,
                'status_pesanan' => Pesanan::MENUJU_LOKASI,
                'diterima_pada' => now(),
            ]);

            return true;
        });
    }

    public function tolakTawaran(Pesanan $pesanan, Teknisi $teknisi): void
    {
        DB::transaction(function () use ($pesanan, $teknisi) {
            $p = Pesanan::query()->lockForUpdate()->find($pesanan->id_pesanan);
            if ($p && (int) $p->id_teknisi_ditawari === (int) $teknisi->id_pengguna) {
                $this->catatMenolak($p, $teknisi->id_pengguna);
                $this->tawarkanBerikutnya($p);
            }
        });
    }

    private function catatMenolak(Pesanan $pesanan, int $idTeknisi): void
    {
        $pesanan->teknisi_menolak = array_values(array_unique([...($pesanan->teknisi_menolak ?? []), $idTeknisi]));
        $pesanan->id_teknisi_ditawari = null;
        $pesanan->batas_tawaran = null;
        $pesanan->save();
    }

    private function batalkanTanpaTeknisi(Pesanan $pesanan): void
    {
        $pesanan->update([
            'status_pesanan' => Pesanan::DIBATALKAN,
            'dibatalkan_pada' => now(),
            'alasan_pembatalan' => 'Tidak ada teknisi yang menerima dalam batas waktu',
            'id_teknisi_ditawari' => null,
            'batas_tawaran' => null,
        ]);
        $pesanan->pembayaran()->where('status_pembayaran', Pembayaran::BERHASIL)
            ->update(['status_pembayaran' => Pembayaran::TERTAHAN]);
    }

    // ---------- Biaya tambahan ----------

    /**
     * Teknisi mengajukan rincian biaya perbaikan setelah pengecekan.
     *
     * @param  array<int, array{nama: string, jenis: string, harga: int|float, jumlah?: int}>  $item
     */
    public function ajukanBiaya(Pesanan $pesanan, array $item, ?string $catatan): void
    {
        DB::transaction(function () use ($pesanan, $item, $catatan) {
            foreach ($item as $i) {
                $pesanan->detail()->create([
                    'jenis_item' => $i['jenis'],
                    'nama_item' => $i['nama'],
                    'jumlah' => $i['jumlah'] ?? 1,
                    'harga' => $i['harga'],
                ]);
            }
            $pesanan->catatan_biaya = $catatan;
            $pesanan->ajukanBiaya();
            $pesanan->save();
        });
    }

    /**
     * Pelanggan menyetujui atau menolak biaya (menolak juga terjadi otomatis
     * bila lewat 5 menit). Setelah itu teknisi melanjutkan pekerjaan.
     */
    public function tanggapiBiaya(Pesanan $pesanan, bool $setuju): void
    {
        DB::transaction(function () use ($pesanan, $setuju) {
            $pesanan->status_biaya = $setuju ? Pesanan::BIAYA_DISETUJUI : Pesanan::BIAYA_DITOLAK;
            $pesanan->biaya_ditanggapi_pada = now();
            $pesanan->status_pesanan = Pesanan::DIKERJAKAN;
            $pesanan->dikerjakan_pada = now();
            $pesanan->save();
            $pesanan->update(['total_biaya' => $pesanan->hitungTotalBiaya()]);
        });
    }

    // ---------- Selesai ----------

    /**
     * Teknisi selesai bekerja. Bila ada biaya perbaikan yang belum dibayar,
     * pelanggan diminta melunasi; bila tidak, pesanan langsung selesai.
     */
    public function selesaiDikerjakan(Pesanan $pesanan, ?string $catatan): void
    {
        DB::transaction(function () use ($pesanan, $catatan) {
            $total = $pesanan->hitungTotalBiaya();
            $pesanan->update(['catatan_pengerjaan' => $catatan, 'total_biaya' => $total]);
            $sisa = round($total - $pesanan->totalDibayar(), 2);

            if ($sisa <= 0) {
                $this->selesai($pesanan);

                return;
            }

            $pesanan->update([
                'status_pesanan' => Pesanan::MENUNGGU_PEMBAYARAN,
                'menunggu_pembayaran_pada' => now(),
            ]);
            $pesanan->pembayaran()->create([
                'jenis_pembayaran' => Pembayaran::PELUNASAN,
                'jumlah_bayar' => $sisa,
                'status_pembayaran' => Pembayaran::MENUNGGU,
            ]);
        });
    }

    /** Pesanan selesai; komisi platform dan pendapatan teknisi dicatat. */
    private function selesai(Pesanan $pesanan): void
    {
        $pesanan->update(['status_pesanan' => Pesanan::SELESAI, 'selesai_pada' => now()]);

        $layanan = $pesanan->detail()->where('jenis_item', DetailPesanan::JENIS_LAYANAN)->first()?->layanan;
        $persen = (float) ($layanan?->persentase_platform ?? 10);

        Pendapatan::query()->firstOrCreate(
            ['id_pesanan' => $pesanan->id_pesanan],
            [
                'id_teknisi' => $pesanan->id_teknisi,
                'persentase_platform' => $persen,
                ...Pendapatan::hitung($pesanan->totalDibayar(), $persen),
            ],
        );
    }
}
