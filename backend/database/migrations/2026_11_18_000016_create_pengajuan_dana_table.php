<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Satu tabel untuk dua jenis pengajuan yang sama-sama ditransfer
        // manual oleh Admin: pencairan pendapatan teknisi dan refund pelanggan.
        Schema::create('pengajuan_dana', function (Blueprint $table) {
            $table->id('id_pengajuan');
            $table->enum('jenis', ['pencairan', 'refund']);
            $table->foreignId('id_pemohon')->constrained('pengguna', 'id_pengguna');
            $table->foreignId('id_pesanan')->nullable()->constrained('pesanan', 'id_pesanan'); // wajib untuk refund
            $table->decimal('nominal', 12, 2);

            // Tujuan transfer (bank atau e-wallet), disalin saat pengajuan dibuat
            $table->string('nama_bank', 50);
            $table->string('no_rekening', 30);
            $table->string('atas_nama', 100);

            $table->text('alasan')->nullable(); // alasan refund dari pelanggan
            $table->enum('status', ['menunggu', 'disetujui', 'ditolak', 'selesai_ditransfer'])->default('menunggu');
            $table->text('alasan_penolakan')->nullable();
            $table->foreignId('id_admin')->nullable()->constrained('pengguna', 'id_pengguna')->nullOnDelete();
            $table->dateTime('diproses_pada')->nullable();
            $table->dateTime('dibuat_pada')->useCurrent();
            $table->dateTime('diubah_pada')->useCurrent()->useCurrentOnUpdate();

            $table->index(['jenis', 'status']);
            $table->index(['id_pemohon', 'jenis']);
        });

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE pengajuan_dana ADD CONSTRAINT chk_pengajuan_nominal CHECK (nominal > 0)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('pengajuan_dana');
    }
};
