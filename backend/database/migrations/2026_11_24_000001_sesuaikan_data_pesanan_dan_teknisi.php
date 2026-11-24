<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Menyesuaikan skema dengan data yang diisi aplikasi mobile.
 *
 * pesanan.detail_lokasi  : patokan untuk pesanan ini, misal "Kamar tidur
 *                          utama, lantai 2". Tidak disimpan di lokasi karena
 *                          alamat tersimpan dipakai berulang.
 * pesanan.detail_layanan : isian khusus layanan dalam JSON, contoh
 *                          {"keluhan": ["Tidak dingin"]}, {"jenis_freon": "R32"},
 *                          {"jenis_pekerjaan": "pindah"}. catatan_pelanggan
 *                          tetap untuk catatan bebas.
 * teknisi.kendaraan      : dipecah menjadi jenis_kendaraan dan plat_nomor
 *                          karena aplikasi menampilkannya terpisah.
 * teknisi.pengalaman     : dihapus, tidak dipakai di aplikasi. Bio teknisi
 *                          memakai kolom deskripsi.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pesanan', function (Blueprint $table) {
            $table->string('detail_lokasi', 150)->nullable()->after('id_lokasi');
            $table->json('detail_layanan')->nullable()->after('merek');
        });

        Schema::table('teknisi', function (Blueprint $table) {
            $table->string('jenis_kendaraan', 50)->nullable()->after('deskripsi');
            $table->string('plat_nomor', 15)->nullable()->after('jenis_kendaraan');
        });

        // Data lama berformat "Honda Beat • BP 4892 QL" atau "Honda Beat (BP 4892 QL)".
        foreach (DB::table('teknisi')->whereNotNull('kendaraan')->get(['id_pengguna', 'kendaraan']) as $t) {
            [$jenis, $plat] = self::pecahKendaraan($t->kendaraan);
            DB::table('teknisi')->where('id_pengguna', $t->id_pengguna)
                ->update(['jenis_kendaraan' => $jenis, 'plat_nomor' => $plat]);
        }

        Schema::table('teknisi', function (Blueprint $table) {
            $table->dropColumn(['kendaraan', 'pengalaman']);
        });
    }

    public function down(): void
    {
        Schema::table('teknisi', function (Blueprint $table) {
            $table->unsignedTinyInteger('pengalaman')->default(0)->after('id_pengguna');
            $table->string('kendaraan', 100)->nullable()->after('deskripsi');
        });

        foreach (DB::table('teknisi')->get(['id_pengguna', 'jenis_kendaraan', 'plat_nomor']) as $t) {
            $gabung = trim(implode(' • ', array_filter([$t->jenis_kendaraan, $t->plat_nomor])));
            DB::table('teknisi')->where('id_pengguna', $t->id_pengguna)
                ->update(['kendaraan' => $gabung === '' ? null : $gabung]);
        }

        Schema::table('teknisi', function (Blueprint $table) {
            $table->dropColumn(['jenis_kendaraan', 'plat_nomor']);
        });

        Schema::table('pesanan', function (Blueprint $table) {
            $table->dropColumn(['detail_lokasi', 'detail_layanan']);
        });
    }

    /** @return array{0: ?string, 1: ?string} [jenis kendaraan, plat nomor] */
    private static function pecahKendaraan(string $teks): array
    {
        if (preg_match('/^(.*?)\s*[•(]\s*([^)]+)\)?\s*$/u', $teks, $m)) {
            return [trim($m[1]) ?: null, trim($m[2]) ?: null];
        }

        return [trim($teks) ?: null, null];
    }
};
