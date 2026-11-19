<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dokumen_verifikasi', function (Blueprint $table) {
            $table->id('id_dokumen');
            $table->foreignId('id_teknisi')->constrained('teknisi', 'id_pengguna')->cascadeOnDelete();
            $table->string('jenis_dokumen', 50); // cv, lamaran_kerja, ktp, ijazah, pas_foto
            $table->string('path_file');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dokumen_verifikasi');
    }
};
