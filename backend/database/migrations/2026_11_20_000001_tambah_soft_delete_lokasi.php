<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Alamat tersimpan boleh dihapus pelanggan, tetapi alamat yang pernah
 * dipakai pesanan tetap dibutuhkan riwayat. Karena itu penghapusan dibuat
 * "lunak": baris ditandai dihapus_pada dan disembunyikan dari daftar alamat.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('lokasi', function (Blueprint $table) {
            $table->dateTime('dihapus_pada')->nullable();
        });

        // Trigger lama menolak SEMUA perubahan pada lokasi yang sudah dipakai
        // pesanan, termasuk penandaan hapus. Sekarang hanya isi alamat yang
        // dikunci; dihapus_pada tetap boleh diisi.
        if (DB::getDriverName() === 'mysql') {
            DB::unprepared('DROP TRIGGER IF EXISTS trg_lokasi_immutable');
            DB::unprepared("
                CREATE TRIGGER trg_lokasi_immutable BEFORE UPDATE ON lokasi FOR EACH ROW
                BEGIN
                    IF (NOT (OLD.label_alamat <=> NEW.label_alamat)
                        OR NOT (OLD.alamat_lengkap <=> NEW.alamat_lengkap)
                        OR NOT (OLD.latitude <=> NEW.latitude)
                        OR NOT (OLD.longitude <=> NEW.longitude)
                        OR NOT (OLD.id_pengguna <=> NEW.id_pengguna))
                       AND EXISTS (SELECT 1 FROM pesanan WHERE id_lokasi = OLD.id_lokasi) THEN
                        SIGNAL SQLSTATE '45000'
                            SET MESSAGE_TEXT = 'Lokasi sudah dipakai pesanan, buat lokasi baru';
                    END IF;
                END
            ");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::unprepared('DROP TRIGGER IF EXISTS trg_lokasi_immutable');
            DB::unprepared("
                CREATE TRIGGER trg_lokasi_immutable BEFORE UPDATE ON lokasi FOR EACH ROW
                BEGIN
                    IF EXISTS (SELECT 1 FROM pesanan WHERE id_lokasi = OLD.id_lokasi) THEN
                        SIGNAL SQLSTATE '45000'
                            SET MESSAGE_TEXT = 'Lokasi sudah dipakai pesanan, buat lokasi baru';
                    END IF;
                END
            ");
        }

        Schema::table('lokasi', function (Blueprint $table) {
            $table->dropColumn('dihapus_pada');
        });
    }
};
