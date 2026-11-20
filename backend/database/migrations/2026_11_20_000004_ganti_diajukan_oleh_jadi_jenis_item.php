<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Jenis baris biaya pesanan:
 *   layanan     = layanan yang dipesan pelanggan (biaya awal)
 *   jasa        = jasa perbaikan yang diajukan teknisi
 *   suku_cadang = suku cadang / material yang diajukan teknisi
 *
 * Kolom lama diajukan_oleh (pelanggan/teknisi) dihapus karena sudah
 * tersirat dari jenis_item: layanan dari pelanggan, sisanya dari teknisi.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('detail_pesanan', function (Blueprint $table) {
            $table->enum('jenis_item', ['layanan', 'jasa', 'suku_cadang'])
                ->default('layanan')->after('id_layanan');
        });

        DB::table('detail_pesanan')->where('diajukan_oleh', 'teknisi')->update(['jenis_item' => 'jasa']);

        Schema::table('detail_pesanan', function (Blueprint $table) {
            $table->dropColumn('diajukan_oleh');
        });
    }

    public function down(): void
    {
        Schema::table('detail_pesanan', function (Blueprint $table) {
            $table->enum('diajukan_oleh', ['pelanggan', 'teknisi'])->default('pelanggan');
        });

        DB::table('detail_pesanan')->where('jenis_item', '!=', 'layanan')->update(['diajukan_oleh' => 'teknisi']);

        Schema::table('detail_pesanan', function (Blueprint $table) {
            $table->dropColumn('jenis_item');
        });
    }
};
