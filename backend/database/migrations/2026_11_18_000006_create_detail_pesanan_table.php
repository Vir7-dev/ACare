<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Baris biaya sebuah pesanan: layanan yang dipesan pelanggan, dan item
        // biaya perbaikan (jasa/suku cadang) yang diajukan teknisi.
        Schema::create('detail_pesanan', function (Blueprint $table) {
            $table->id('id_detail');
            $table->foreignId('id_pesanan')->constrained('pesanan', 'id_pesanan')->cascadeOnDelete();
            $table->foreignId('id_layanan')->nullable()->constrained('layanan', 'id_layanan'); // kosong untuk item teknisi
            $table->string('nama_item', 150);
            $table->unsignedInteger('jumlah')->default(1);
            $table->decimal('harga', 12, 2); // harga satuan saat diajukan
            $table->enum('diajukan_oleh', ['pelanggan', 'teknisi']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('detail_pesanan');
    }
};
