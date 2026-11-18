<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('foto_bukti_pengerjaan', function (Blueprint $table) {
            $table->id('id_foto');
            $table->foreignId('id_pesanan')->constrained('pesanan', 'id_pesanan')->cascadeOnDelete();
            $table->enum('tahap', ['pemeriksaan', 'sebelum', 'sesudah', 'tambahan']);
            $table->string('path_foto');
            $table->dateTime('dibuat_pada')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('foto_bukti_pengerjaan');
    }
};
