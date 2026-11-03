<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;

class StatistikController extends Controller
{
    public function index()
    {
        // Statistik ringkas
        $stats = [
            ['label' => 'Total Transaksi', 'value' => '631', 'sub' => '+24 bulan ini', 'icon' => 'receipt', 'warna' => 'bg-sky-500', 'bg' => 'bg-sky-50', 'text' => 'text-sky-600'],
            ['label' => 'Pendapatan Bulan Ini', 'value' => 'Rp 18,4 Jt', 'sub' => '+12% dari bulan lalu', 'icon' => 'money', 'warna' => 'bg-emerald-500', 'bg' => 'bg-emerald-50', 'text' => 'text-emerald-600'],
            ['label' => 'Teknisi Aktif', 'value' => '28', 'sub' => '3 menunggu verifikasi', 'icon' => 'technician', 'warna' => 'bg-violet-500', 'bg' => 'bg-violet-50', 'text' => 'text-violet-600'],
            ['label' => 'Pengguna Terdaftar', 'value' => '1.240', 'sub' => '+87 pengguna baru', 'icon' => 'users', 'warna' => 'bg-amber-500', 'bg' => 'bg-amber-50', 'text' => 'text-amber-600'],
        ];

        // Data chart bulanan (Pendapatan dalam jutaan)
        $chartLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        $chartPendapatan = [8.2, 9.5, 10.1, 11.4, 12.0, 13.7, 14.2, 15.8, 16.3, 18.4, null, null];
        $chartTransaksi = [42, 55, 60, 71, 80, 93, 98, 110, 115, 128, null, null];

        // Distribusi layanan
        $distribusiLayanan = [
            ['nama' => 'Cuci AC', 'jumlah' => 142, 'persen' => 22.5, 'warna' => '#0ea5e9'],
            ['nama' => 'Isi Freon AC', 'jumlah' => 115, 'persen' => 18.2, 'warna' => '#8b5cf6'],
            ['nama' => 'Service AC', 'jumlah' => 98, 'persen' => 15.5, 'warna' => '#f59e0b'],
            ['nama' => 'Pembersihan Filter', 'jumlah' => 89, 'persen' => 14.1, 'warna' => '#10b981'],
            ['nama' => 'Cek & Diagnosa', 'jumlah' => 56, 'persen' => 8.9, 'warna' => '#ef4444'],
            ['nama' => 'Lainnya', 'jumlah' => 131, 'persen' => 20.8, 'warna' => '#94a3b8'],
        ];

        // Transaksi terbaru
        $transaksi = [
            ['id' => 'TRX-2410001', 'tanggal' => '20 Okt 2026', 'pelanggan' => 'Budi Santoso', 'layanan' => 'Cuci AC', 'teknisi' => 'Ahmad Fauzi', 'harga' => 120000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410002', 'tanggal' => '20 Okt 2026', 'pelanggan' => 'Siti Rahayu', 'layanan' => 'Isi Freon AC', 'teknisi' => 'Rendi Kurniawan', 'harga' => 200000, 'status' => 'Berlangsung'],
            ['id' => 'TRX-2410003', 'tanggal' => '19 Okt 2026', 'pelanggan' => 'Hendra Wijaya', 'layanan' => 'Bongkar Pasang AC', 'teknisi' => 'Dian Pratama', 'harga' => 350000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410004', 'tanggal' => '19 Okt 2026', 'pelanggan' => 'Rina Melati', 'layanan' => 'Service AC', 'teknisi' => 'Ahmad Fauzi', 'harga' => 250000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410005', 'tanggal' => '18 Okt 2026', 'pelanggan' => 'Agus Prasetyo', 'layanan' => 'Cek & Diagnosa AC', 'teknisi' => 'Fajar Nugroho', 'harga' => 100000, 'status' => 'Dibatalkan'],
            ['id' => 'TRX-2410006', 'tanggal' => '18 Okt 2026', 'pelanggan' => 'Dewi Kusuma', 'layanan' => 'Cuci AC', 'teknisi' => 'Rendi Kurniawan', 'harga' => 80000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410007', 'tanggal' => '17 Okt 2026', 'pelanggan' => 'Wahyu Nugroho', 'layanan' => 'Pemasangan AC Baru', 'teknisi' => 'Dian Pratama', 'harga' => 500000, 'status' => 'Selesai'],
            ['id' => 'TRX-2410008', 'tanggal' => '17 Okt 2026', 'pelanggan' => 'Indah Permata', 'layanan' => 'Pembersihan Filter', 'teknisi' => 'Fajar Nugroho', 'harga' => 65000, 'status' => 'Berlangsung'],
        ];

        return view('admin.statistik', compact('stats', 'chartLabels', 'chartPendapatan', 'chartTransaksi', 'distribusiLayanan', 'transaksi'));
    }
}
