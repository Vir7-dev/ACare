<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Support\StatusAdmin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LayananController extends Controller
{
    /**
     * Katalog layanan: data contoh, atau versi terbaru dari session bila sudah diubah.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarLayanan(): array
    {
        $tersimpan = StatusAdmin::ambil('layanan');
        if (is_array($tersimpan) && $tersimpan !== []) {
            return array_values($tersimpan);
        }

        // 6 Layanan Utama ACare (Sesuai Katalog Resmi)
        return [
            [
                'id' => 1,
                'nama' => 'Cuci AC',
                'deskripsi' => 'Pembersihan menyeluruh unit AC split indoor & outdoor agar performa dingin optimal dan bebas bakteri.',
                'harga_min' => 80000,
                'harga_max' => 150000,
                'durasi' => '60–90 menit',
                'icon' => 'lucide:droplets',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => 'Aktif',
                'total_pesanan' => 231,
            ],
            [
                'id' => 2,
                'nama' => 'Service AC',
                'deskripsi' => 'Pemeriksaan & perbaikan komponen AC yang rusak, bocor air, berisik, atau mati total.',
                'harga_min' => 100000,
                'harga_max' => 350000,
                'durasi' => '90–180 menit',
                'icon' => 'lucide:wrench',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => 'Aktif',
                'total_pesanan' => 145,
            ],
            [
                'id' => 3,
                'nama' => 'Bongkar Pasang AC',
                'deskripsi' => 'Layanan pemindahan atau pembongkaran dan instalasi kembali unit AC ke lokasi / ruangan baru.',
                'harga_min' => 200000,
                'harga_max' => 450000,
                'durasi' => '120–180 menit',
                'icon' => 'lucide:hammer',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => 'Aktif',
                'total_pesanan' => 78,
            ],
            [
                'id' => 4,
                'nama' => 'Isi Freon AC',
                'deskripsi' => 'Pengisian ulang freon AC (R22, R32, R410A) sesuai kapasitas unit agar AC kembali dingin maksimal.',
                'harga_min' => 150000,
                'harga_max' => 300000,
                'durasi' => '30–60 menit',
                'icon' => 'lucide:snowflake',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => 'Aktif',
                'total_pesanan' => 124,
            ],
            [
                'id' => 5,
                'nama' => 'Pemasangan AC Baru',
                'deskripsi' => 'Instalasi unit AC baru lengkap meliputi bracket outdoor, vacum pipa tembaga, kabel, dan uji coba.',
                'harga_min' => 350000,
                'harga_max' => 600000,
                'durasi' => '180–240 menit',
                'icon' => 'lucide:circle-plus',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => 'Aktif',
                'total_pesanan' => 53,
            ],
            [
                'id' => 6,
                'nama' => 'Cek & Diagnosa AC',
                'deskripsi' => 'Pemeriksaan menyeluruh kondisi unit AC, kelistrikan, dan tekanan freon untuk menemukan sumber masalah.',
                'harga_min' => 75000,
                'harga_max' => 100000,
                'durasi' => '45–60 menit',
                'icon' => 'lucide:search',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => 'Aktif',
                'total_pesanan' => 62,
            ],
        ];
    }

    /**
     * Simpan seluruh katalog hasil perubahan (tambah, ubah, hapus, status).
     */
    public function sinkron(Request $request): JsonResponse
    {
        $data = $request->validate([
            'layanan' => ['present', 'array', 'max:100'],
            'layanan.*.id' => ['required'],
            'layanan.*.nama' => ['required', 'string', 'max:80'],
            'layanan.*.deskripsi' => ['nullable', 'string', 'max:500'],
            'layanan.*.harga_min' => ['required', 'integer', 'min:0'],
            'layanan.*.harga_max' => ['required', 'integer', 'min:0'],
            'layanan.*.durasi' => ['nullable', 'string', 'max:40'],
            'layanan.*.icon' => ['required', 'string', 'max:60'],
            'layanan.*.warna' => ['required', 'string', 'max:80'],
            'layanan.*.status' => ['required', 'in:Aktif,Tidak Aktif'],
            'layanan.*.total_pesanan' => ['required', 'integer', 'min:0'],
        ]);

        foreach ($data['layanan'] as $item) {
            if ($item['harga_max'] < $item['harga_min']) {
                return response()->json(['pesan' => 'Harga maksimum tidak boleh lebih kecil dari harga minimum.'], 422);
            }
        }

        StatusAdmin::simpanSemua('layanan', $data['layanan']);

        return response()->json(['ok' => true]);
    }

    public function index()
    {
        $layanan = self::daftarLayanan();

        return view('admin.kelola-layanan', compact('layanan'));
    }
}
