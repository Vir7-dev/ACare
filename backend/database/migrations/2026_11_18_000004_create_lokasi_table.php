<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lokasi', function (Blueprint $table) {
            $table->id('id_lokasi');
            $table->foreignId('id_pengguna')->constrained('pengguna', 'id_pengguna')->cascadeOnDelete();
            $table->string('label_alamat', 50);
            $table->text('alamat_lengkap'); // termasuk detail/patokan
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);

            // Dipakai foreign key gabungan dari pesanan: alamat harus milik pelanggan itu.
            $table->unique(['id_lokasi', 'id_pengguna'], 'uq_lokasi_pemilik');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lokasi');
    }
};
