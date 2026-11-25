<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Pesanan;
use Carbon\Carbon;
use Illuminate\Http\Request;

class TransaksiController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    private static function formatStatus(string $statusPesanan): string
    {
        return match (strtolower($statusPesanan)) {
            Pesanan::SELESAI => 'Selesai',
            Pesanan::DIBATALKAN => 'Dibatalkan',
            default => 'Berlangsung',
        };
    }

    /**
     * Daftar transaksi dari database (sumber tunggal untuk Kelola Transaksi & pencarian global).
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarTransaksi(): array
    {
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
            ->get();

        return $pesananList->map(function (Pesanan $p): array {
            $waktu = $p->dibuat_pada ? Carbon::parse($p->dibuat_pada) : null;
            $tanggal = $waktu
                ? $waktu->day.' '.self::BULAN[$waktu->month - 1].' '.$waktu->year
                : '-';
            $jam = $waktu ? $waktu->format('H:i').' WIB' : '-';

            $status = self::formatStatus((string) $p->status_pesanan);

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
            $metodeBayar = $pembayaranTerakhir->metode_pembayaran
                ?? $pembayaranTerakhir->metode
                ?? 'Transfer / Tunai';

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

            $selesaiWaktu = $p->selesai_pada ? Carbon::parse($p->selesai_pada) : null;
            $diterimaWaktu = $p->diterima_pada ? Carbon::parse($p->diterima_pada) : null;

            return [
                'id' => (string) $p->id_pesanan,
                'kode' => $p->kode ?: (string) $p->id_pesanan,
                'tanggal' => $tanggal,
                'jam' => $jam,
                'pelanggan' => $p->pelanggan?->nama ?? 'Pelanggan',
                'telepon_pelanggan' => $p->pelanggan?->no_telepon ?? '-',
                'alamat' => $alamat,
                'layanan' => $layanan,
                'unit_ac' => $unitAc,
                'keluhan' => $p->catatan_pelanggan
                    ?: data_get($p->detail_layanan, 'keluhan')
                    ?: '-',
                'teknisi' => $p->teknisi?->pengguna?->nama ?? 'Belum ditugaskan',
                'telepon_teknisi' => $p->teknisi?->pengguna?->no_telepon ?? '-',
                'status' => $status,
                'metode_bayar' => $metodeBayar,
                'status_bayar' => $statusBayar,
                'durasi' => ($diterimaWaktu && $selesaiWaktu)
                    ? $diterimaWaktu->diffInMinutes($selesaiWaktu).' menit'
                    : '-',
                'rincian' => $rincian,
                'total_biaya' => (float) $p->total_biaya,
                'bukti' => [
                    'sebelum' => $ambilBukti(['sebelum', 'awal', 'before']),
                    'proses' => $ambilBukti(['proses', 'kerja', 'process']),
                    'sesudah' => $ambilBukti(['sesudah', 'akhir', 'after']),
                    'catatan_teknisi' => $p->catatan_pengerjaan ?: '-',
                    'waktu_selesai' => $selesaiWaktu
                        ? $selesaiWaktu->day.' '.self::BULAN[$selesaiWaktu->month - 1].' '.$selesaiWaktu->year.', '.$selesaiWaktu->format('H.i')
                        : '-',
                ],
            ];
        })->values()->all();
    }

    public function index(Request $request)
    {
        return view('admin.kelola-transaksi', [
            'transaksiList' => self::daftarTransaksi(),
        ]);
    }
}
