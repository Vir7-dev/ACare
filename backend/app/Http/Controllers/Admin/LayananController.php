<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;

class LayananController extends Controller
{
    public function index()
    {
        // 6 Layanan Utama ACare (Sesuai Katalog Resmi)
        $layanan = [
            [
                'id' => 1,
                'nama' => 'Cuci AC',
                'kategori' => 'Perawatan',
                'deskripsi' => 'Pembersihan menyeluruh unit AC split indoor & outdoor agar performa dingin optimal dan bebas bakteri.',
                'harga_min' => 80000,
                'harga_max' => 150000,
                'durasi' => '60–90 menit',
                'icon' => '🌊',
                'warna' => 'bg-cyan-100 text-cyan-600',
                'status' => 'Aktif',
                'total_pesanan' => 231,
            ],
            [
                'id' => 2,
                'nama' => 'Service AC',
                'kategori' => 'Perbaikan',
                'deskripsi' => 'Pemeriksaan & perbaikan komponen AC yang rusak, bocor air, berisik, atau mati total.',
                'harga_min' => 100000,
                'harga_max' => 350000,
                'durasi' => '90–180 menit',
                'icon' => '🔧',
                'warna' => 'bg-orange-100 text-orange-600',
                'status' => 'Aktif',
                'total_pesanan' => 145,
            ],
            [
                'id' => 3,
                'nama' => 'Bongkar Pasang AC',
                'kategori' => 'Instalasi',
                'deskripsi' => 'Layanan pemindahan atau pembongkaran dan instalasi kembali unit AC ke lokasi / ruangan baru.',
                'harga_min' => 200000,
                'harga_max' => 450000,
                'durasi' => '120–180 menit',
                'icon' => '🏗️',
                'warna' => 'bg-violet-100 text-violet-600',
                'status' => 'Aktif',
                'total_pesanan' => 78,
            ],
            [
                'id' => 4,
                'nama' => 'Isi Freon AC',
                'kategori' => 'Perawatan',
                'deskripsi' => 'Pengisian ulang freon AC (R22, R32, R410A) sesuai kapasitas unit agar AC kembali dingin maksimal.',
                'harga_min' => 150000,
                'harga_max' => 300000,
                'durasi' => '30–60 menit',
                'icon' => '❄️',
                'warna' => 'bg-sky-100 text-sky-600',
                'status' => 'Aktif',
                'total_pesanan' => 124,
            ],
            [
                'id' => 5,
                'nama' => 'Pemasangan AC Baru',
                'kategori' => 'Instalasi',
                'deskripsi' => 'Instalasi unit AC baru lengkap meliputi bracket outdoor, vacum pipa tembaga, kabel, dan uji coba.',
                'harga_min' => 350000,
                'harga_max' => 600000,
                'durasi' => '180–240 menit',
                'icon' => '🆕',
                'warna' => 'bg-green-100 text-green-600',
                'status' => 'Aktif',
                'total_pesanan' => 53,
            ],
            [
                'id' => 6,
                'nama' => 'Cek & Diagnosa AC',
                'kategori' => 'Perbaikan',
                'deskripsi' => 'Pemeriksaan menyeluruh kondisi unit AC, kelistrikan, dan tekanan freon untuk menemukan sumber masalah.',
                'harga_min' => 75000,
                'harga_max' => 100000,
                'durasi' => '45–60 menit',
                'icon' => '🔍',
                'warna' => 'bg-amber-100 text-amber-600',
                'status' => 'Aktif',
                'total_pesanan' => 62,
            ],
        ];

        $kategori = ['Semua', 'Perawatan', 'Perbaikan', 'Instalasi'];

        $stats = [
            'total_layanan' => count($layanan),
            'layanan_aktif' => count(array_filter($layanan, fn($l) => $l['status'] === 'Aktif')),
            'layanan_nonaktif' => count(array_filter($layanan, fn($l) => $l['status'] === 'Tidak Aktif')),
            'total_pesanan' => array_sum(array_column($layanan, 'total_pesanan')),
        ];

        return view('admin.kelola-layanan', compact('layanan', 'kategori', 'stats'));
    }
}
