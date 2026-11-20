<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Hasil persetujuan biaya perbaikan (UC-14).
 *
 * null      = teknisi tidak mengajukan biaya tambahan
 * menunggu  = rincian biaya sudah dikirim, menunggu pelanggan
 * disetujui = item biaya teknisi ikut ditagih saat pelunasan
 * ditolak   = item biaya teknisi tetap tersimpan sebagai riwayat, tetapi
 *             tidak ditagih; pesanan selesai dengan biaya awal saja
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->enum('status_biaya', ['menunggu', 'disetujui', 'ditolak'])
                ->nullable()->after('total_biaya');
            $table->dateTime('biaya_ditanggapi_pada')->nullable()->after('batas_persetujuan_biaya');
        });
    }

    public function down(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->dropColumn(['status_biaya', 'biaya_ditanggapi_pada']);
        });
    }
};
