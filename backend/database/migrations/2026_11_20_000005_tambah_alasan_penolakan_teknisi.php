<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Hasil verifikasi pendaftaran teknisi oleh Admin. Bila ditolak, alasannya
 * ditampilkan ke calon teknisi agar ia tahu dokumen apa yang perlu diperbaiki.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teknisi', function (Blueprint $table) {
            $table->text('alasan_penolakan')->nullable()->after('status_verifikasi');
            $table->foreignId('diverifikasi_oleh')->nullable()->after('alasan_penolakan')
                ->constrained('pengguna', 'id_pengguna')->nullOnDelete();
            $table->dateTime('diverifikasi_pada')->nullable()->after('diverifikasi_oleh');
        });
    }

    public function down(): void
    {
        Schema::table('teknisi', function (Blueprint $table) {
            $table->dropConstrainedForeignId('diverifikasi_oleh');
            $table->dropColumn(['alasan_penolakan', 'diverifikasi_pada']);
        });
    }
};
