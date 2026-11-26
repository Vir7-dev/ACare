<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tawaran pesanan ke teknisi (UC-20): pesanan ditawarkan ke satu teknisi
 * terdekat selama batas_tawaran; bila ditolak atau lewat, pindah ke teknisi
 * berikutnya. id_teknisi baru diisi setelah teknisi menerima.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->foreignId('id_teknisi_ditawari')->nullable()->after('id_teknisi')
                ->constrained('teknisi', 'id_pengguna')->nullOnDelete();
            // Mulai dicarikan teknisi (setelah pembayaran awal lunas), untuk
            // batas waktu pencarian.
            $table->dateTime('pencarian_dimulai_pada')->nullable()->after('batas_tawaran');
        });
    }

    public function down(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->dropConstrainedForeignId('id_teknisi_ditawari');
            $table->dropColumn('pencarian_dimulai_pada');
        });
    }
};
