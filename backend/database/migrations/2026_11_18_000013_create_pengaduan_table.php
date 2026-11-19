<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // id_pesanan kosong = aduan jalur "Sistem & Aplikasi".
        // Pihak terlapor diturunkan dari pesanan dan peran pelapor.
        Schema::create('pengaduan', function (Blueprint $table) {
            $table->id('id_pengaduan');
            $table->foreignId('id_pelapor')->constrained('pengguna', 'id_pengguna');
            $table->foreignId('id_pesanan')->nullable()->constrained('pesanan', 'id_pesanan');
            $table->foreignId('id_admin')->nullable()->constrained('pengguna', 'id_pengguna')->nullOnDelete();
            $table->string('jenis_pengaduan', 50); // jenis masalah, misal "Teknisi Datang Terlambat"
            $table->text('deskripsi');
            $table->json('bukti')->nullable(); // daftar path foto, maksimal 3
            $table->enum('status_pengaduan', ['diajukan', 'diproses', 'selesai'])->default('diajukan');
            $table->text('tanggapan_admin')->nullable();
            $table->dateTime('dibuat_pada')->useCurrent();
            $table->dateTime('diubah_pada')->useCurrent()->useCurrentOnUpdate();
            $table->dateTime('selesai_pada')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengaduan');
    }
};
