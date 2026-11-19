<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Support\StatusAdmin;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UlasanController extends Controller
{
    /**
     * Alasan yang bisa dipilih Admin saat menyembunyikan ulasan.
     *
     * @var array<int, string>
     */
    public const ALASAN = [
        'Kata kasar atau menghina',
        'Memuat data pribadi',
        'Spam atau promosi',
        'Tidak relevan dengan layanan',
        'Lainnya',
    ];

    /**
     * Data rating dan ulasan sementara (belum memakai database).
     *
     * @return array<int, array<string, mixed>>
     */
    public static function dataDasar(): array
    {
        return [
            [
                'id' => 'ULS-2611001',
                'tanggal' => '20 Okt 2026',
                'jam' => '16:10 WIB',
                'pelanggan' => 'Budi Santoso',
                'teknisi' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2410001',
                'layanan' => 'Cuci AC',
                'rating' => 5,
                'ulasan' => 'Pengerjaan rapi dan teknisinya ramah. Hembusan AC sekarang dingin dan tidak bau lagi.',
                'pilihan' => ['Pengerjaan Bersih & Rapi', 'Sopan & Ramah'],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2611002',
                'tanggal' => '19 Okt 2026',
                'jam' => '12:20 WIB',
                'pelanggan' => 'Hendra Wijaya',
                'teknisi' => 'Ahmad Fauzi',
                'order_id' => 'TRX-2410003',
                'layanan' => 'Bongkar Pasang AC',
                'rating' => 4,
                'ulasan' => 'Pemindahan selesai tepat waktu dan AC dingin normal. Kabel di luar kurang rapi, sisanya bagus.',
                'pilihan' => ['Tepat Waktu'],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2611003',
                'tanggal' => '19 Okt 2026',
                'jam' => '17:45 WIB',
                'pelanggan' => 'Rina Melati',
                'teknisi' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2410004',
                'layanan' => 'Service AC',
                'rating' => 5,
                'ulasan' => 'Air tidak menetes lagi. Penjelasan teknisinya jelas dan harganya sesuai estimasi.',
                'pilihan' => ['Penjelasan Sangat Jelas', 'AC Kembali Dingin Maksimal'],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2611004',
                'tanggal' => '17 Okt 2026',
                'jam' => '15:05 WIB',
                'pelanggan' => 'Dewi Kusuma',
                'teknisi' => 'Ahmad Fauzi',
                'order_id' => 'TRX-2410006',
                'layanan' => 'Cuci AC',
                'rating' => 2,
                'ulasan' => 'Teknisi datang terlambat dan pekerjaannya terburu-buru. Bagian outdoor tidak dicuci.',
                'pilihan' => [],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2611005',
                'tanggal' => '16 Okt 2026',
                'jam' => '19:30 WIB',
                'pelanggan' => 'Wahyu Nugroho',
                'teknisi' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2410007',
                'layanan' => 'Pemasangan AC Baru',
                'rating' => 1,
                'ulasan' => 'Teknisi bodoh dan tidak profesional! Jangan pakai jasa ini, dasar penipu!!!',
                'pilihan' => [],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2611006',
                'tanggal' => '15 Okt 2026',
                'jam' => '11:50 WIB',
                'pelanggan' => 'Indah Permata',
                'teknisi' => 'Achmal Feb',
                'order_id' => 'TRX-2410008',
                'layanan' => 'Service AC',
                'rating' => 3,
                'ulasan' => 'Hasil servis lumayan, tetapi harga terasa agak mahal untuk perbaikan yang sebentar.',
                'pilihan' => ['Alat Kerja Lengkap'],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2610018',
                'tanggal' => '30 Sep 2026',
                'jam' => '14:15 WIB',
                'pelanggan' => 'Maya Lestari',
                'teknisi' => 'Achmal Feb',
                'order_id' => 'TRX-2409031',
                'layanan' => 'Isi Freon AC',
                'rating' => 5,
                'ulasan' => 'Cepat dan sopan. Freon diisi sampai tekanan standar dan ditunjukkan hasil ukurnya.',
                'pilihan' => ['Sopan & Ramah', 'Alat Kerja Lengkap'],
                'status' => 'Tayang',
                'alasan' => null,
            ],
            [
                'id' => 'ULS-2610011',
                'tanggal' => '24 Sep 2026',
                'jam' => '09:40 WIB',
                'pelanggan' => 'Rizal Hakim',
                'teknisi' => 'Ahmad Fauzi',
                'order_id' => 'TRX-2409018',
                'layanan' => 'Cuci AC',
                'rating' => 4,
                'ulasan' => 'Servis bagus. Kalau mau diskon cuci AC, hubungi saya di 0812-3456-7890 atau kunjungi tokoku.',
                'pilihan' => [],
                'status' => 'Disembunyikan',
                'alasan' => 'Spam atau promosi',
            ],
            [
                'id' => 'ULS-2610004',
                'tanggal' => '18 Sep 2026',
                'jam' => '18:25 WIB',
                'pelanggan' => 'Sari Wulandari',
                'teknisi' => 'Virgiawan Aziz L',
                'order_id' => 'TRX-2409007',
                'layanan' => 'Service AC',
                'rating' => 2,
                'ulasan' => 'Perbaikan belum tuntas, AC masih berisik setelah dua hari. Mohon ditindaklanjuti.',
                'pilihan' => [],
                'status' => 'Tayang',
                'alasan' => null,
            ],
        ];
    }

    /**
     * Daftar ulasan dengan perubahan status dari session sudah diterapkan.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarUlasan(): array
    {
        $tersimpan = StatusAdmin::ambil('ulasan') ?? [];

        return array_map(function (array $ulasan) use ($tersimpan): array {
            $ubah = $tersimpan[$ulasan['id']] ?? null;
            if (is_array($ubah)) {
                $ulasan['status'] = $ubah['status'];
                $ulasan['alasan'] = $ubah['alasan'];
            }

            return $ulasan;
        }, self::dataDasar());
    }

    /**
     * Jumlah ulasan yang disembunyikan.
     */
    public static function jumlahDisembunyikan(): int
    {
        return count(array_filter(
            self::daftarUlasan(),
            fn (array $ulasan): bool => $ulasan['status'] === 'Disembunyikan'
        ));
    }

    /**
     * Sembunyikan atau tayangkan kembali satu atau beberapa ulasan
     * (juga dipakai untuk membatalkan perubahan).
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required', 'string'],
            'perubahan.*.status' => ['required', 'in:Tayang,Disembunyikan'],
            'perubahan.*.alasan' => ['nullable', 'string', 'max:120'],
        ]);

        $id = array_column(self::dataDasar(), 'id');
        foreach ($data['perubahan'] as $ubah) {
            if (! in_array($ubah['id'], $id, true)) {
                return response()->json(['pesan' => 'Ulasan tidak ditemukan.'], 404);
            }
            if ($ubah['status'] === 'Disembunyikan' && trim((string) ($ubah['alasan'] ?? '')) === '') {
                return response()->json(['pesan' => 'Alasan menyembunyikan ulasan wajib diisi.'], 422);
            }
        }

        foreach ($data['perubahan'] as $ubah) {
            StatusAdmin::simpan('ulasan', $ubah['id'], [
                'status' => $ubah['status'],
                'alasan' => $ubah['status'] === 'Disembunyikan' ? trim((string) $ubah['alasan']) : null,
            ]);
        }

        return response()->json(['ok' => true, 'disembunyikan' => self::jumlahDisembunyikan()]);
    }

    public function index(Request $request): View
    {
        $statusAwal = in_array($request->query('status'), ['Tayang', 'Disembunyikan'], true)
            ? $request->query('status')
            : 'Semua';

        return view('admin.moderasi-ulasan', [
            'ulasanList' => self::daftarUlasan(),
            'statusAwal' => $statusAwal,
            'alasanList' => self::ALASAN,
            'idTransaksi' => array_column(TransaksiController::daftarTransaksi(), 'id'),
        ]);
    }
}
