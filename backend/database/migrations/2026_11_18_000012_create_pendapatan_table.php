<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Dibuat sekali per pesanan setelah pembayaran terakhir lunas.
        // Saldo teknisi = total pendapatan_teknisi - total pengajuan pencairan
        // yang tidak ditolak (lihat tabel pengajuan_dana).
        Schema::create('pendapatan', function (Blueprint $table) {
            $table->id('id_pendapatan');
            $table->unsignedBigInteger('id_pesanan')->unique();
            $table->foreignId('id_teknisi')->constrained('teknisi', 'id_pengguna');
            $table->decimal('persentase_platform', 5, 2);
            $table->decimal('pendapatan_platform', 12, 2);
            $table->decimal('pendapatan_teknisi', 12, 2);
            $table->dateTime('dibuat_pada')->useCurrent();

            // Pendapatan hanya boleh dicatat untuk teknisi yang menangani pesanan itu.
            $table->foreign(['id_pesanan', 'id_teknisi'], 'fk_pendapatan_pesanan_teknisi')
                ->references(['id_pesanan', 'id_teknisi'])->on('pesanan');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pendapatan');
    }
};
