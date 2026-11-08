<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Contracts\View\View;
use App\Support\StatusAdmin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PengaduanController extends Controller
{
    /**
     * Data pengaduan sementara (belum memakai database).
     *
     * @return array<int, array<string, mixed>>
     */
    public static function dataDasar(): array
    {
        return [
            [
                'id' => 'ADU-2611001',
                'tanggal' => '8 Nov 2026',
                'jam' => '09:12 WIB',
                'pelapor' => 'Budi Santoso',
                'peran' => 'Pelanggan',
                'terlapor' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2410001',
                'kategori' => 'Kualitas Pengerjaan',
                'ringkasan' => 'AC masih berbau apek setelah dicuci.',
                'deskripsi' => 'Setelah pencucian selesai, hembusan AC masih berbau apek dan bagian outdoor tidak dibersihkan. Mohon ditindaklanjuti.',
                'status' => 'Baru',
            ],
            [
                'id' => 'ADU-2611002',
                'tanggal' => '8 Nov 2026',
                'jam' => '08:40 WIB',
                'pelapor' => 'Siti Rahayu',
                'peran' => 'Pelanggan',
                'terlapor' => 'Achmal Feb',
                'order_id' => 'TRX-2410002',
                'kategori' => 'Keterlambatan',
                'ringkasan' => 'Teknisi datang 2 jam lebih lambat dari jadwal.',
                'deskripsi' => 'Teknisi tiba pukul 13:15 padahal jadwal pukul 11:15 dan tidak memberi kabar sebelumnya.',
                'status' => 'Baru',
            ],
            [
                'id' => 'ADU-2611003',
                'tanggal' => '7 Nov 2026',
                'jam' => '19:05 WIB',
                'pelapor' => 'Ahmad Fauzi',
                'peran' => 'Teknisi',
                'terlapor' => 'Hendra Wijaya',
                'order_id' => 'TRX-2410003',
                'kategori' => 'Perilaku Pelanggan',
                'ringkasan' => 'Pelanggan menolak membayar biaya tambahan yang disepakati.',
                'deskripsi' => 'Biaya pemasangan bracket baru sudah disetujui lewat aplikasi, tetapi pelanggan menolak membayar saat pekerjaan selesai.',
                'status' => 'Baru',
            ],
            [
                'id' => 'ADU-2611004',
                'tanggal' => '7 Nov 2026',
                'jam' => '15:30 WIB',
                'pelapor' => 'Rina Melati',
                'peran' => 'Pelanggan',
                'terlapor' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2410004',
                'kategori' => 'Biaya',
                'ringkasan' => 'Nominal tagihan berbeda dari estimasi awal.',
                'deskripsi' => 'Estimasi awal Rp 200.000 tetapi tagihan akhir Rp 250.000 tanpa penjelasan rincian tambahan.',
                'status' => 'Baru',
            ],
            [
                'id' => 'ADU-2611005',
                'tanggal' => '6 Nov 2026',
                'jam' => '10:20 WIB',
                'pelapor' => 'Dewi Kusuma',
                'peran' => 'Pelanggan',
                'terlapor' => 'Ahmad Fauzi',
                'order_id' => 'TRX-2410006',
                'kategori' => 'Kualitas Pengerjaan',
                'ringkasan' => 'Air masih menetes dari unit indoor.',
                'deskripsi' => 'Dua hari setelah dicuci, unit indoor kembali meneteskan air ke lantai.',
                'status' => 'Baru',
            ],
            [
                'id' => 'ADU-2610012',
                'tanggal' => '3 Nov 2026',
                'jam' => '13:45 WIB',
                'pelapor' => 'Wahyu Nugroho',
                'peran' => 'Pelanggan',
                'terlapor' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2410007',
                'kategori' => 'Kualitas Pengerjaan',
                'ringkasan' => 'Kabel pemasangan tidak dirapikan.',
                'deskripsi' => 'Kabel dan pipa hasil pemasangan terlihat berantakan dan tidak dibungkus.',
                'status' => 'Diproses',
            ],
            [
                'id' => 'ADU-2610009',
                'tanggal' => '30 Okt 2026',
                'jam' => '17:10 WIB',
                'pelapor' => 'Indah Permata',
                'peran' => 'Pelanggan',
                'terlapor' => 'Achmal Feb',
                'order_id' => 'TRX-2410008',
                'kategori' => 'Keterlambatan',
                'ringkasan' => 'Pesanan batal sepihak oleh teknisi.',
                'deskripsi' => 'Teknisi membatalkan pesanan 30 menit sebelum jadwal tanpa alasan yang jelas.',
                'status' => 'Selesai',
            ],
        ];
    }

    /**
     * Daftar pengaduan dengan perubahan status dari session sudah diterapkan.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarPengaduan(): array
    {
        $tersimpan = StatusAdmin::ambil('pengaduan') ?? [];

        return array_map(function (array $pengaduan) use ($tersimpan): array {
            $pengaduan['status'] = $tersimpan[$pengaduan['id']] ?? $pengaduan['status'];

            return $pengaduan;
        }, self::dataDasar());
    }

    /**
     * Ubah status satu atau beberapa pengaduan (juga dipakai untuk membatalkan).
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required', 'string'],
            'perubahan.*.status' => ['required', 'in:Baru,Diproses,Selesai'],
        ]);

        $id = array_column(self::dataDasar(), 'id');
        foreach ($data['perubahan'] as $ubah) {
            if (! in_array($ubah['id'], $id, true)) {
                return response()->json(['pesan' => 'Pengaduan tidak ditemukan.'], 404);
            }
        }

        foreach ($data['perubahan'] as $ubah) {
            StatusAdmin::simpan('pengaduan', $ubah['id'], $ubah['status']);
        }

        return response()->json(['ok' => true, 'baru' => self::jumlahBaru()]);
    }

    /**
     * Jumlah pengaduan yang belum ditangani.
     */
    public static function jumlahBaru(): int
    {
        return count(array_filter(
            self::daftarPengaduan(),
            fn (array $pengaduan): bool => $pengaduan['status'] === 'Baru'
        ));
    }

    public function index(Request $request): View
    {
        $statusAwal = in_array($request->query('status'), ['Baru', 'Diproses', 'Selesai'], true)
            ? $request->query('status')
            : 'Semua';

        return view('admin.pengaduan', [
            'pengaduanList' => self::daftarPengaduan(),
            'jumlahBaru' => self::jumlahBaru(),
            'statusAwal' => $statusAwal,
        ]);
    }
}
