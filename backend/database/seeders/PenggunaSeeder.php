<?php

namespace Database\Seeders;

use App\Models\Lokasi;
use App\Models\Pengguna;
use App\Models\Teknisi;
use Illuminate\Database\Seeder;

/**
 * Akun contoh untuk pengembangan lokal (satu per peran).
 * Kata sandi semua akun: "password". Jangan dipakai di server produksi.
 */
class PenggunaSeeder extends Seeder
{
    public function run(): void
    {
        Pengguna::updateOrCreate(['email' => 'admin@acare.id'], [
            'nama' => 'Admin Operasional',
            'no_telepon' => '081200000001',
            'kata_sandi' => 'password',
            'role' => Pengguna::ROLE_ADMIN,
        ]);

        $pelanggan = Pengguna::updateOrCreate(['email' => 'pelanggan@acare.id'], [
            'nama' => 'Pelanggan Contoh',
            'no_telepon' => '081200000002',
            'kata_sandi' => 'password',
            'role' => Pengguna::ROLE_PELANGGAN,
        ]);

        Lokasi::firstOrCreate(
            ['id_pengguna' => $pelanggan->id_pengguna, 'label_alamat' => 'Rumah'],
            [
                'alamat_lengkap' => 'Batam Centre, Kota Batam, Kepulauan Riau',
                'latitude' => 1.1283000,
                'longitude' => 104.0530000,
            ],
        );

        $teknisi = Pengguna::updateOrCreate(['email' => 'teknisi@acare.id'], [
            'nama' => 'Rizky Pratama',
            'no_telepon' => '081200000003',
            'kata_sandi' => 'password',
            'role' => Pengguna::ROLE_TEKNISI,
        ]);

        Teknisi::updateOrCreate(['id_pengguna' => $teknisi->id_pengguna], [
            'deskripsi' => 'Berpengalaman 5 tahun menangani AC rumah dan kantor.',
            'jenis_kendaraan' => 'Honda Beat',
            'plat_nomor' => 'BP 1234 AC',
            'nama_bank' => 'BNI',
            'no_rekening' => '1234567890',
            'atas_nama' => 'Rizky Pratama',
            'status_verifikasi' => 'terverifikasi',
            'status_ketersediaan' => 'tidak_tersedia',
        ]);
    }
}
