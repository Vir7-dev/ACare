<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('layanan', function (Blueprint $table) {
            $table->id('id_layanan');
            $table->string('nama_layanan', 100)->unique();
            $table->text('deskripsi_layanan')->nullable();
            $table->decimal('harga', 12, 2); // harga awal yang dibayar di muka
            $table->unsignedInteger('estimasi_durasi')->nullable(); // dalam menit
            // Potongan platform (%) yang diatur Admin; nilainya disalin ke
            // tabel pendapatan saat pesanan selesai supaya tidak berubah surut.
            $table->decimal('persentase_platform', 5, 2)->default(10);
            $table->enum('status_layanan', ['aktif', 'nonaktif'])->default('aktif');
        });

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE layanan
                ADD CONSTRAINT chk_layanan_harga CHECK (harga >= 0),
                ADD CONSTRAINT chk_layanan_persentase CHECK (persentase_platform BETWEEN 0 AND 100)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('layanan');
    }
};
