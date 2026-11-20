<?php

namespace Database\Seeders;

use App\Models\Layanan;
use Illuminate\Database\Seeder;

/** Lima layanan resmi ACare, sama dengan katalog di aplikasi mobile. */
class LayananSeeder extends Seeder
{
    public function run(): void
    {
        $daftar = [
            ['Cuci AC', 'Membersihkan filter, evaporator, dan bagian dalam AC agar lebih dingin dan hemat listrik.', 75000, 45],
            ['Service AC', 'Perbaikan kerusakan AC seperti tidak dingin, bocor air, bunyi berisik, atau mati total.', 100000, 45],
            ['Isi Freon', 'Pengisian ulang freon berkualitas untuk menjaga performa pendinginan AC tetap optimal.', 150000, 45],
            ['Bongkar Pasang', 'Melayani pemasangan AC baru atau pemindahan dan bongkar pasang unit AC lama.', 100000, 45],
            // Layanan paling ringan untuk pelanggan yang belum tahu masalah AC-nya;
            // setelah pengecekan teknisi boleh mengajukan biaya perbaikan.
            ['Cek AC', 'Pemeriksaan kondisi AC oleh teknisi, cocok bila kamu belum tahu masalahnya atau sekadar ingin memastikan AC dalam kondisi baik.', 50000, 30],
        ];

        foreach ($daftar as [$nama, $deskripsi, $harga, $durasi]) {
            Layanan::updateOrCreate(
                ['nama_layanan' => $nama],
                [
                    'deskripsi_layanan' => $deskripsi,
                    'harga' => $harga,
                    'estimasi_durasi' => $durasi,
                    'persentase_platform' => 10,
                    'status_layanan' => 'aktif',
                ],
            );
        }
    }
}
