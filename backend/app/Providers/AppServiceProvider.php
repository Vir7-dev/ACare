<?php

namespace App\Providers;

use App\Http\Controllers\Admin\PencairanController;
use App\Http\Controllers\Admin\PengaduanController;
use App\Http\Controllers\Admin\PenggunaController;
use App\Http\Controllers\Admin\TransaksiController;
use App\Http\Controllers\Admin\UlasanController;
use App\Models\DetailPesanan;
use App\Models\Pesanan;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    private static function indeksCari(): array
    {
        $hasil = [];

        foreach (TransaksiController::daftarTransaksi() as $t) {
            $hasil[] = ['jenis' => 'Transaksi', 'id' => $t['id'], 'judul' => $t['id'].' · '.$t['pelanggan'], 'info' => $t['layanan'].' · '.$t['status']];
        }
        foreach (PenggunaController::daftarPengguna() as $p) {
            $hasil[] = ['jenis' => 'Pengguna', 'id' => $p['id'], 'judul' => $p['nama'], 'info' => $p['peran'].' · '.$p['id']];
        }
        foreach (PengaduanController::daftarPengaduan() as $a) {
            $hasil[] = ['jenis' => 'Pengaduan', 'id' => $a['id'], 'judul' => $a['id'].' · '.$a['pelapor'], 'info' => $a['kategori'].' · '.$a['status']];
        }
        foreach (UlasanController::daftarUlasan() as $u) {
            $hasil[] = ['jenis' => 'Ulasan', 'id' => $u['id'], 'judul' => $u['id'].' · '.$u['pelanggan'], 'info' => 'Rating '.$u['rating'].' untuk '.$u['teknisi'].' · '.$u['status']];
        }
        foreach (PencairanController::daftarPengajuan() as $p) {
            $hasil[] = ['jenis' => 'Pencairan', 'id' => $p['id'], 'judul' => $p['id'].' · '.$p['pemohon'], 'info' => $p['jenis'].' · '.$p['status']];
        }

        return $hasil;
    }

    public function boot(): void
    {
        View::composer('layouts.admin', function ($view): void {
            $view->with('jumlahTeknisiMenunggu', count(PenggunaController::teknisiMenunggu()));
            $view->with('jumlahPengaduanBaru', PengaduanController::jumlahBaru());
            $view->with('jumlahPengajuanMenunggu', PencairanController::jumlahMenunggu());
            $view->with('indeksCari', self::indeksCari());
        });

        View::composer('admin.partials.detail-transaksi', function ($view): void {
            $bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

            $pesananList = Pesanan::query()
                ->with([
                    'pelanggan',
                    'teknisi.pengguna',
                    'lokasi',
                    'detail.layanan',
                    'fotoBukti',
                    'pembayaran',
                ])
                ->orderByDesc('dibuat_pada')
                ->limit(50)
                ->get();

            $daftar = $pesananList->map(function (Pesanan $p) use ($bulan): array {
                $waktu = $p->dibuat_pada;
                $tanggalTeks = $waktu
                    ? $waktu->day.' '.$bulan[$waktu->month - 1].' '.$waktu->year
                    : '-';
                $jamTeks = $waktu ? $waktu->format('H.i') : '-';

                $status = match ($p->status_pesanan) {
                    Pesanan::SELESAI => 'Selesai',
                    Pesanan::DIBATALKAN => 'Dibatalkan',
                    default => 'Berlangsung',
                };

                $detailLayanan = $p->detail->firstWhere('jenis_item', DetailPesanan::JENIS_LAYANAN);
                $layanan = $detailLayanan?->layanan?->nama_layanan
                    ?? $detailLayanan?->nama_item
                    ?? data_get($p->detail_layanan, 'jenis_pekerjaan')
                    ?? 'Layanan AC';

                $rincian = $p->detail->map(fn (DetailPesanan $d): array => [
                    'item' => $d->nama_item ?: ($d->layanan?->nama_layanan ?? 'Item'),
                    'biaya' => (float) $d->subtotal,
                ])->values()->all();

                $pembayaranTerakhir = $p->pembayaran->sortByDesc('id_pembayaran')->first();
                $metodeBayar = $pembayaranTerakhir->metode_pembayaran ?? $pembayaranTerakhir->metode ?? 'Transfer / Tunai';
                $statusBayarRaw = strtolower((string) ($pembayaranTerakhir->status_pembayaran ?? $pembayaranTerakhir->status ?? ''));

                $statusBayar = match (true) {
                    in_array($statusBayarRaw, ['lunas', 'paid', 'berhasil', 'sukses'], true) => 'Lunas',
                    in_array($statusBayarRaw, ['batal', 'dibatalkan', 'gagal', 'refund'], true) => 'Batal',
                    default => ($p->status_pesanan === Pesanan::SELESAI ? 'Lunas' : 'Menunggu'),
                };

                $buktiFoto = $p->fotoBukti ?? collect();
                $ambilBukti = function (array $kataKunci) use ($buktiFoto): string {
                    $cocok = $buktiFoto->first(function ($f) use ($kataKunci): bool {
                        $teks = strtolower((string) ($f->tahap ?? $f->jenis ?? $f->keterangan ?? ''));
                        foreach ($kataKunci as $k) {
                            if (str_contains($teks, $k)) {
                                return true;
                            }
                        }

                        return false;
                    });

                    return $cocok?->keterangan ?: ($cocok ? 'Foto terlampir' : 'Belum ada catatan');
                };

                $unitAc = trim(implode(' ', array_filter([
                    $p->jenis_ac ? 'AC '.$p->jenis_ac : null,
                    $p->merek ?: null,
                    $p->pk ? $p->pk.' PK' : null,
                ]))) ?: 'Unit AC';

                $alamat = $p->detail_lokasi
                    ?: ($p->lokasi->alamat_lengkap ?? $p->lokasi->alamat ?? '-');

                return [
                    'id' => $p->kode,
                    'status' => $status,
                    'layanan' => $layanan,
                    'tanggal' => $tanggalTeks,
                    'jam' => $jamTeks,
                    'pelanggan' => $p->pelanggan->nama ?? 'Pelanggan',
                    'telepon_pelanggan' => $p->pelanggan->no_telepon ?? '-',
                    'alamat' => $alamat,
                    'teknisi' => $p->teknisi->pengguna->nama ?? 'Belum ditugaskan',
                    'telepon_teknisi' => $p->teknisi->pengguna->no_telepon ?? '-',
                    'durasi' => ($p->diterima_pada && $p->selesai_pada)
                        ? $p->diterima_pada->diffInMinutes($p->selesai_pada).' menit'
                        : '-',
                    'unit_ac' => $unitAc,
                    'keluhan' => $p->catatan_pelanggan
                        ?: data_get($p->detail_layanan, 'keluhan')
                        ?: '-',
                    'bukti' => [
                        'sebelum' => $ambilBukti(['sebelum', 'awal', 'before']),
                        'proses' => $ambilBukti(['proses', 'kerja', 'process']),
                        'sesudah' => $ambilBukti(['sesudah', 'akhir', 'after']),
                        'catatan_teknisi' => $p->catatan_pengerjaan ?: '-',
                        'waktu_selesai' => $p->selesai_pada
                            ? $p->selesai_pada->day.' '.$bulan[$p->selesai_pada->month - 1].' '.$p->selesai_pada->year.', '.$p->selesai_pada->format('H.i')
                            : '-',
                    ],
                    'rincian' => $rincian,
                    'total_biaya' => (float) $p->total_biaya,
                    'metode_bayar' => $metodeBayar,
                    'status_bayar' => $statusBayar,
                ];
            })->values()->all();

            $view->with('daftarTransaksi', $daftar);
        });
    }
}
