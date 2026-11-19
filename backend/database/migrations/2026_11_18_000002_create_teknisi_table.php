<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teknisi', function (Blueprint $table) {
            $table->foreignId('id_pengguna')->primary()
                ->constrained('pengguna', 'id_pengguna')->cascadeOnDelete();
            $table->unsignedTinyInteger('pengalaman')->default(0); // dalam tahun
            $table->text('deskripsi')->nullable();
            $table->string('kendaraan', 100)->nullable(); // contoh: "Honda Beat • BP 4892 QL"
            $table->string('nama_bank', 50);
            $table->string('no_rekening', 30);
            $table->string('atas_nama', 100);
            $table->enum('status_verifikasi', ['menunggu', 'terverifikasi', 'ditolak'])->default('menunggu');
            $table->enum('status_ketersediaan', ['tersedia', 'tidak_tersedia'])->default('tidak_tersedia');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->dateTime('lokasi_diperbarui_pada')->nullable();

            $table->index(['status_verifikasi', 'status_ketersediaan']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teknisi');
    }
};
