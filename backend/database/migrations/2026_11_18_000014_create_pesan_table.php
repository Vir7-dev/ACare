<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pesan', function (Blueprint $table) {
            $table->id('id_pesan');
            $table->foreignId('id_pesanan')->constrained('pesanan', 'id_pesanan')->cascadeOnDelete();
            $table->foreignId('id_pengirim')->constrained('pengguna', 'id_pengguna');
            $table->enum('tipe_pesan', ['teks', 'gambar'])->default('teks');
            $table->text('isi')->nullable();
            $table->string('path_gambar')->nullable();
            $table->boolean('status_dibaca')->default(false);
            $table->dateTime('dibuat_pada')->useCurrent();

            $table->index(['id_pesanan', 'dibuat_pada']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pesan');
    }
};
