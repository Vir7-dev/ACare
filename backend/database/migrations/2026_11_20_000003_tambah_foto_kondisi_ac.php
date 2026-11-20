<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tahap "kondisi" = foto kondisi AC yang diunggah pelanggan saat memesan
 * (opsional), supaya teknisi bisa melihat gambaran masalah sebelum datang.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('foto_bukti_pengerjaan', function (Blueprint $table) {
            $table->enum('tahap', ['kondisi', 'pemeriksaan', 'sebelum', 'sesudah', 'tambahan'])->change();
        });
    }

    public function down(): void
    {
        Schema::table('foto_bukti_pengerjaan', function (Blueprint $table) {
            $table->enum('tahap', ['pemeriksaan', 'sebelum', 'sesudah', 'tambahan'])->change();
        });
    }
};
