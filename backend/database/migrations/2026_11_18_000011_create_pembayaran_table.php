<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Pembayaran pelanggan lewat Xendit. Pengembalian dana (refund) dicatat
        // di tabel pengajuan_dana, bukan di sini.
        Schema::create('pembayaran', function (Blueprint $table) {
            $table->id('id_pembayaran');
            $table->foreignId('id_pesanan')->constrained('pesanan', 'id_pesanan');
            $table->enum('jenis_pembayaran', ['awal', 'pelunasan']);
            $table->string('metode_pembayaran', 50)->nullable(); // diisi dari Xendit setelah dibayar
            $table->decimal('jumlah_bayar', 12, 2);
            // tertahan     = pesanan dibatalkan, dana menunggu refund
            // dikembalikan = refund sudah ditransfer Admin
            $table->enum('status_pembayaran', [
                'menunggu', 'berhasil', 'gagal', 'kedaluwarsa', 'tertahan', 'dikembalikan',
            ])->default('menunggu');
            $table->string('referensi_transaksi', 100)->nullable()->unique(); // ID invoice Xendit
            $table->string('url_pembayaran')->nullable(); // halaman checkout Xendit
            $table->dateTime('kedaluwarsa_pada')->nullable();
            $table->dateTime('waktu_pembayaran')->nullable();
            $table->dateTime('dibuat_pada')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pembayaran');
    }
};
