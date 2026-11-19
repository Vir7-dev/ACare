<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Support\StatusAdmin;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PencairanController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    /**
     * Status pengajuan. Alurnya Menunggu, Disetujui, lalu Selesai Ditransfer;
     * pengajuan yang belum selesai bisa Ditolak dengan alasan.
     *
     * @var array<int, string>
     */
    public const STATUS = ['Menunggu', 'Disetujui', 'Selesai Ditransfer', 'Ditolak'];

    /**
     * Perpindahan status yang sah (di luar pembatalan perubahan).
     *
     * @var array<string, array<int, string>>
     */
    private const ALUR = [
        'Menunggu' => ['Disetujui', 'Ditolak'],
        'Disetujui' => ['Selesai Ditransfer', 'Ditolak'],
        'Selesai Ditransfer' => [],
        'Ditolak' => [],
    ];

    /**
     * Data pengajuan sementara (belum memakai database). Nominal pencairan
     * adalah jumlah pendapatan Teknisi per pesanan (tagihan dikurangi
     * potongan platform 15%); refund memakai nominal yang dibayar Pelanggan.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function dataDasar(): array
    {
        $pengajuan = [
            [
                'id' => 'PCR-2611001',
                'jenis' => 'Pencairan',
                'tanggal' => '9 Nov 2026',
                'jam' => '08:30 WIB',
                'pemohon' => 'Virgiawan Aziz L',
                'peran' => 'Teknisi',
                'tujuan' => ['jenis' => 'Bank', 'nama' => 'BCA', 'nomor' => '8821034567', 'atas_nama' => 'Virgiawan Aziz Listianto'],
                'pesanan' => [
                    ['id' => 'TRX-2410001', 'keterangan' => 'Cuci AC', 'nominal' => 102000],
                    ['id' => 'TRX-2410004', 'keterangan' => 'Service AC', 'nominal' => 212500],
                    ['id' => 'TRX-2410007', 'keterangan' => 'Pemasangan AC Baru', 'nominal' => 425000],
                ],
                'status' => 'Menunggu',
            ],
            [
                'id' => 'PCR-2611002',
                'jenis' => 'Pencairan',
                'tanggal' => '8 Nov 2026',
                'jam' => '20:10 WIB',
                'pemohon' => 'Ahmad Fauzi',
                'peran' => 'Teknisi',
                'tujuan' => ['jenis' => 'Bank', 'nama' => 'BNI', 'nomor' => '0456712390', 'atas_nama' => 'Ahmad Fauzi'],
                'pesanan' => [
                    ['id' => 'TRX-2410003', 'keterangan' => 'Bongkar Pasang AC', 'nominal' => 297500],
                    ['id' => 'TRX-2410006', 'keterangan' => 'Cuci AC', 'nominal' => 68000],
                ],
                'status' => 'Menunggu',
            ],
            [
                'id' => 'PCR-2611003',
                'jenis' => 'Pencairan',
                'tanggal' => '8 Nov 2026',
                'jam' => '14:05 WIB',
                'pemohon' => 'Achmal Feb',
                'peran' => 'Teknisi',
                'tujuan' => ['jenis' => 'E-Wallet', 'nama' => 'DANA', 'nomor' => '081267676767', 'atas_nama' => 'Achmal Febriansyah'],
                'pesanan' => [
                    ['id' => 'TRX-2410008', 'keterangan' => 'Service AC', 'nominal' => 148750],
                ],
                'status' => 'Menunggu',
            ],
            [
                'id' => 'RFD-2611001',
                'jenis' => 'Refund',
                'tanggal' => '8 Nov 2026',
                'jam' => '11:30 WIB',
                'pemohon' => 'Agus Prasetyo',
                'peran' => 'Pelanggan',
                'tujuan' => ['jenis' => 'Bank', 'nama' => 'BRI', 'nomor' => '012301004455', 'atas_nama' => 'Agus Prasetyo'],
                'pesanan' => [
                    ['id' => 'TRX-2410005', 'keterangan' => 'Cek & Diagnosa AC', 'nominal' => 100000],
                ],
                'alasan_pengajuan' => 'Pesanan dibatalkan Pelanggan saat sistem masih mencari Teknisi.',
                'nominal' => 100000,
                'status' => 'Menunggu',
            ],
            [
                'id' => 'RFD-2611002',
                'jenis' => 'Refund',
                'tanggal' => '7 Nov 2026',
                'jam' => '16:45 WIB',
                'pemohon' => 'Maya Lestari',
                'peran' => 'Pelanggan',
                'tujuan' => ['jenis' => 'E-Wallet', 'nama' => 'GoPay', 'nomor' => '085212349876', 'atas_nama' => 'Maya Lestari'],
                'pesanan' => [
                    ['id' => 'TRX-2411003', 'keterangan' => 'Isi Freon AC', 'nominal' => 80000],
                ],
                'alasan_pengajuan' => 'Tidak ada Teknisi yang menerima sampai batas waktu penawaran.',
                'nominal' => 80000,
                'status' => 'Menunggu',
            ],
            [
                'id' => 'PCR-2610014',
                'jenis' => 'Pencairan',
                'tanggal' => '5 Nov 2026',
                'jam' => '10:20 WIB',
                'pemohon' => 'Achmal Feb',
                'peran' => 'Teknisi',
                'tujuan' => ['jenis' => 'E-Wallet', 'nama' => 'DANA', 'nomor' => '081267676767', 'atas_nama' => 'Achmal Febriansyah'],
                'pesanan' => [
                    ['id' => 'TRX-2409031', 'keterangan' => 'Isi Freon AC', 'nominal' => 85000],
                    ['id' => 'TRX-2409036', 'keterangan' => 'Cuci AC', 'nominal' => 68000],
                ],
                'status' => 'Disetujui',
            ],
            [
                'id' => 'PCR-2610008',
                'jenis' => 'Pencairan',
                'tanggal' => '30 Okt 2026',
                'jam' => '09:15 WIB',
                'pemohon' => 'Ahmad Fauzi',
                'peran' => 'Teknisi',
                'tujuan' => ['jenis' => 'Bank', 'nama' => 'BNI', 'nomor' => '0456712390', 'atas_nama' => 'Ahmad Fauzi'],
                'pesanan' => [
                    ['id' => 'TRX-2409018', 'keterangan' => 'Cuci AC', 'nominal' => 127500],
                ],
                'status' => 'Selesai Ditransfer',
                'referensi' => 'TF-BNI-261031-0118',
                'waktu_transfer' => '31 Okt 2026, 10:20 WIB',
            ],
            [
                'id' => 'RFD-2610006',
                'jenis' => 'Refund',
                'tanggal' => '28 Okt 2026',
                'jam' => '13:00 WIB',
                'pemohon' => 'Dian Anggraini',
                'peran' => 'Pelanggan',
                'tujuan' => ['jenis' => 'E-Wallet', 'nama' => 'DANA', 'nomor' => '081377001122', 'atas_nama' => 'Dian Anggraini'],
                'pesanan' => [
                    ['id' => 'TRX-2410210', 'keterangan' => 'Service AC', 'nominal' => 175000],
                ],
                'alasan_pengajuan' => 'Teknisi menolak pesanan dan tidak ada pengganti.',
                'nominal' => 175000,
                'status' => 'Selesai Ditransfer',
                'referensi' => 'TF-DANA-261029-0042',
                'waktu_transfer' => '29 Okt 2026, 09:05 WIB',
            ],
            [
                'id' => 'PCR-2610003',
                'jenis' => 'Pencairan',
                'tanggal' => '25 Okt 2026',
                'jam' => '17:40 WIB',
                'pemohon' => 'Virgiawan Aziz L',
                'peran' => 'Teknisi',
                'tujuan' => ['jenis' => 'Bank', 'nama' => 'BCA', 'nomor' => '8821034500', 'atas_nama' => 'Virgi Aziz'],
                'pesanan' => [
                    ['id' => 'TRX-2409007', 'keterangan' => 'Service AC', 'nominal' => 85000],
                ],
                'status' => 'Ditolak',
                'alasan' => 'Nama pemilik rekening tidak sesuai dengan nama Teknisi.',
            ],
        ];

        return array_map(function (array $p): array {
            if ($p['jenis'] === 'Pencairan') {
                $p['nominal'] = array_sum(array_column($p['pesanan'], 'nominal'));
            }

            return $p + ['alasan' => null, 'referensi' => null, 'waktu_transfer' => null, 'alasan_pengajuan' => null];
        }, $pengajuan);
    }

    /**
     * Daftar pengajuan dengan perubahan status dari session sudah diterapkan.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarPengajuan(): array
    {
        $tersimpan = StatusAdmin::ambil('pencairan') ?? [];

        return array_map(function (array $pengajuan) use ($tersimpan): array {
            $ubah = $tersimpan[$pengajuan['id']] ?? null;
            if (is_array($ubah)) {
                $pengajuan['status'] = $ubah['status'];
                $pengajuan['alasan'] = $ubah['alasan'];
                $pengajuan['referensi'] = $ubah['referensi'];
                $pengajuan['waktu_transfer'] = $ubah['waktu_transfer'];
            }

            return $pengajuan;
        }, self::dataDasar());
    }

    /**
     * Jumlah pengajuan yang masih menunggu keputusan Admin.
     */
    public static function jumlahMenunggu(): int
    {
        return count(array_filter(
            self::daftarPengajuan(),
            fn (array $pengajuan): bool => $pengajuan['status'] === 'Menunggu'
        ));
    }

    private static function waktuSekarang(): string
    {
        $sekarang = now();

        return $sekarang->day.' '.self::BULAN[$sekarang->month - 1].' '.$sekarang->year.', '.$sekarang->format('H:i').' WIB';
    }

    /**
     * Ubah status satu atau beberapa pengajuan. Dengan `pulihkan`, perubahan
     * dikembalikan ke keadaan sebelumnya (dipakai tombol Batalkan).
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'pulihkan' => ['sometimes', 'boolean'],
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required', 'string'],
            'perubahan.*.status' => ['required', 'in:'.implode(',', self::STATUS)],
            'perubahan.*.alasan' => ['nullable', 'string', 'max:200'],
            'perubahan.*.referensi' => ['nullable', 'string', 'max:60'],
            'perubahan.*.waktu_transfer' => ['nullable', 'string', 'max:40'],
        ]);

        $pulihkan = (bool) ($data['pulihkan'] ?? false);
        $saatIni = array_column(self::daftarPengajuan(), null, 'id');

        foreach ($data['perubahan'] as $ubah) {
            if (! isset($saatIni[$ubah['id']])) {
                return response()->json(['pesan' => 'Pengajuan tidak ditemukan.'], 404);
            }
            if ($pulihkan) {
                continue;
            }
            $dari = $saatIni[$ubah['id']]['status'];
            if (! in_array($ubah['status'], self::ALUR[$dari], true)) {
                return response()->json(['pesan' => 'Pengajuan '.$ubah['id'].' tidak bisa diubah dari '.$dari.' ke '.$ubah['status'].'.'], 422);
            }
            if ($ubah['status'] === 'Ditolak' && trim((string) ($ubah['alasan'] ?? '')) === '') {
                return response()->json(['pesan' => 'Alasan penolakan wajib diisi.'], 422);
            }
            if ($ubah['status'] === 'Selesai Ditransfer' && trim((string) ($ubah['referensi'] ?? '')) === '') {
                return response()->json(['pesan' => 'Referensi transfer wajib diisi.'], 422);
            }
        }

        $hasil = [];
        foreach ($data['perubahan'] as $ubah) {
            $catatan = [
                'status' => $ubah['status'],
                'alasan' => $ubah['status'] === 'Ditolak' ? trim((string) $ubah['alasan']) : null,
                'referensi' => $ubah['status'] === 'Selesai Ditransfer' ? trim((string) $ubah['referensi']) : null,
                'waktu_transfer' => $ubah['status'] === 'Selesai Ditransfer'
                    ? ($pulihkan && ! empty($ubah['waktu_transfer']) ? $ubah['waktu_transfer'] : self::waktuSekarang())
                    : null,
            ];
            StatusAdmin::simpan('pencairan', $ubah['id'], $catatan);
            $hasil[$ubah['id']] = $catatan;
        }

        return response()->json(['ok' => true, 'menunggu' => self::jumlahMenunggu(), 'catatan' => $hasil]);
    }

    public function index(Request $request): View
    {
        $statusAwal = in_array($request->query('status'), self::STATUS, true)
            ? $request->query('status')
            : 'Semua';

        return view('admin.pencairan-refund', [
            'pengajuanList' => self::daftarPengajuan(),
            'statusAwal' => $statusAwal,
            'idTransaksi' => array_column(TransaksiController::daftarTransaksi(), 'id'),
        ]);
    }
}
