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
            ['Cuci AC', 'Membersihkan filter, evaporator, dan bagian dalam AC agar lebih dingin dan hemat listrik.', 75000],
            ['Service AC', 'Pengecekan dan perbaikan kerusakan ringan hingga berat pada sistem pendingin AC.', 100000],
            ['Isi Freon', 'Pengisian ulang freon berkualitas untuk menjaga performa pendinginan AC tetap optimal.', 150000],
            ['Bongkar Pasang', 'Melayani pemasangan AC baru atau pemindahan dan bongkar pasang unit AC lama.', 100000],
            ['Cek AC', 'Menangani berbagai kerusakan AC seperti tidak dingin, bocor, atau kendala kelistrikan.', 100000],
        ];

        foreach ($daftar as [$nama, $deskripsi, $harga]) {
            Layanan::updateOrCreate(
                ['nama_layanan' => $nama],
                [
                    'deskripsi_layanan' => $deskripsi,
                    'harga' => $harga,
                    'estimasi_durasi' => 45,
                    'persentase_platform' => 10,
                    'status_layanan' => 'aktif',
                ],
            );
        }
    }
}
