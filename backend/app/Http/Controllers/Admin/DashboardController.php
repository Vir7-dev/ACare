<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        // 4 Kartu Statistik Utama
        $stats = [
            [
                'label' => 'Total Transaksi',
                'value' => '631',
                'sub' => '+24 bulan ini',
                'icon' => 'receipt',
                'warna' => 'from-sky-500 to-sky-600',
                'bg' => 'bg-sky-50',
                'text' => 'text-sky-600',
            ],
            [
                'label' => 'Pendapatan Bulan Ini',
                'value' => 'Rp 18,4 Jt',
                'sub' => '+12% dari bulan lalu',
                'icon' => 'money',
                'warna' => 'from-emerald-500 to-emerald-600',
                'bg' => 'bg-emerald-50',
                'text' => 'text-emerald-600',
            ],
            [
                'label' => 'Teknisi Aktif',
                'value' => '28',
                'sub' => '3 menunggu verifikasi',
                'icon' => 'technician',
                'warna' => 'from-violet-500 to-violet-600',
                'bg' => 'bg-violet-50',
                'text' => 'text-violet-600',
            ],
            [
                'label' => 'Pengguna Terdaftar',
                'value' => '1.240',
                'sub' => '+87 pengguna baru',
                'icon' => 'users',
                'warna' => 'from-amber-500 to-amber-600',
                'bg' => 'bg-amber-50',
                'text' => 'text-amber-600',
            ],
        ];

        // Data Grafik Tren Bulanan 2026
        $chartLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        $chartPendapatan = [8.2, 9.5, 10.1, 11.4, 12.0, 13.7, 14.2, 15.8, 16.3, 18.4, null, null];
        $chartTransaksi = [42, 55, 60, 71, 80, 93, 98, 110, 115, 128, null, null];

        // Distribusi 6 Kategori Layanan AC Resmi
        $distribusiLayanan = [
            ['nama' => 'Cuci AC', 'jumlah' => 231, 'persen' => 33.3, 'warna' => '#0284C7'],
            ['nama' => 'Service AC', 'jumlah' => 145, 'persen' => 20.9, 'warna' => '#F97316'],
            ['nama' => 'Isi Freon AC', 'jumlah' => 124, 'persen' => 17.9, 'warna' => '#0EA5E9'],
            ['nama' => 'Bongkar Pasang AC', 'jumlah' => 78, 'persen' => 11.3, 'warna' => '#8B5CF6'],
            ['nama' => 'Cek & Diagnosa AC', 'jumlah' => 62, 'persen' => 8.9, 'warna' => '#EAB308'],
            ['nama' => 'Pemasangan AC Baru', 'jumlah' => 53, 'persen' => 7.7, 'warna' => '#10B981'],
        ];

        // Transaksi Terbaru di Platform ACare
        $transaksi = [
            ['id' => 'TRX-2410001', 'tanggal' => '20 Okt 2026', 'pelanggan' => 'Budi Santoso', 'layanan' => 'Cuci AC (1/2 - 1 PK)', 'teknisi' => 'Virgiawan Aziz L', 'harga' => 120000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410002', 'tanggal' => '20 Okt 2026', 'pelanggan' => 'Siti Rahayu', 'layanan' => 'Isi Freon AC (R32)', 'teknisi' => 'Achmal Feb', 'harga' => 200000, 'status' => 'Berlangsung'],
            ['id' => 'TRX-2410003', 'tanggal' => '19 Okt 2026', 'pelanggan' => 'Hendra Wijaya', 'layanan' => 'Bongkar Pasang AC', 'teknisi' => 'Ahmad Fauzi', 'harga' => 350000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410004', 'tanggal' => '19 Okt 2026', 'pelanggan' => 'Rina Melati', 'layanan' => 'Service AC (Bocor Air)', 'teknisi' => 'Virgiawan Aziz L', 'harga' => 250000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410005', 'tanggal' => '18 Okt 2026', 'pelanggan' => 'Agus Prasetyo', 'layanan' => 'Cek & Diagnosa AC', 'teknisi' => 'Achmal Feb', 'harga' => 100000, 'status' => 'Dibatalkan'],
            ['id' => 'TRX-2410006', 'tanggal' => '18 Okt 2026', 'pelanggan' => 'Dewi Kusuma', 'layanan' => 'Cuci AC Split', 'teknisi' => 'Ahmad Fauzi', 'harga' => 80000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410007', 'tanggal' => '17 Okt 2026', 'pelanggan' => 'Wahyu Nugroho', 'layanan' => 'Pemasangan AC Baru', 'teknisi' => 'Virgiawan Aziz L', 'harga' => 500000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410008', 'tanggal' => '17 Okt 2026', 'pelanggan' => 'Indah Permata', 'layanan' => 'Service AC (Ganti Kapasitor)', 'teknisi' => 'Achmal Feb', 'harga' => 175000, 'status' => 'Berlangsung'],
        ];

        // Teknisi yang Butuh Verifikasi Segera (Quick Action Widget di Dashboard)
        $teknisiMenungguVerifikasi = [
            ['id' => 'PAW3311', 'nama' => 'GanAnWo', 'kota' => 'Mataram Barat, Mataram', 'sejak' => '12 Sept 2026 12:25', 'dokumen_count' => 4],
            ['id' => 'TEK2021', 'nama' => 'Rendi Kurniawan', 'kota' => 'Batu Aji, Batam', 'sejak' => '15 Sept 2026 09:10', 'dokumen_count' => 4],
            ['id' => 'TEK2022', 'nama' => 'Dian Pratama', 'kota' => 'Bengkong, Batam', 'sejak' => '18 Sept 2026 14:30', 'dokumen_count' => 4],
        ];

        return view('admin.dashboard', compact(
            'stats',
            'chartLabels',
            'chartPendapatan',
            'chartTransaksi',
            'distribusiLayanan',
            'transaksi',
            'teknisiMenungguVerifikasi'
        ));
    }
}
