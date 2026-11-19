<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifikasi', function (Blueprint $table) {
            $table->id('id_notifikasi');
            $table->foreignId('id_penerima')->constrained('pengguna', 'id_pengguna')->cascadeOnDelete();
            $table->foreignId('id_pesanan')->nullable()->constrained('pesanan', 'id_pesanan')->nullOnDelete();
            $table->string('judul', 150);
            $table->string('tipe_notifikasi', 50);
            $table->text('isi_notifikasi');
            $table->boolean('status_dibaca')->default(false);
            $table->dateTime('dibuat_pada')->useCurrent();

            $table->index(['id_penerima', 'dibuat_pada']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifikasi');
    }
};
