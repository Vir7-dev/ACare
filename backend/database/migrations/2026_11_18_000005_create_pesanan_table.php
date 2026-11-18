<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pesanan', function (Blueprint $table) {
            $table->id('id_pesanan');
            $table->foreignId('id_pelanggan')->constrained('pengguna', 'id_pengguna');
            // Selama status "mencari_teknisi", kolom ini berisi teknisi yang sedang
            // ditawari. Setelah tawaran diterima, ia menjadi teknisi pesanan ini.
            $table->foreignId('id_teknisi')->nullable()->constrained('teknisi', 'id_pengguna');
            $table->unsignedBigInteger('id_lokasi');

            $table->dateTime('jadwal_service');
            $table->enum('jenis_ac', ['split', 'cassette', 'standing', 'window'])->nullable();
            $table->decimal('pk', 3, 1)->nullable();
            $table->string('merek', 50)->nullable();
            $table->text('catatan_pelanggan')->nullable();
            $table->text('catatan_biaya')->nullable(); // catatan teknisi pada rincian biaya perbaikan
            $table->text('catatan_pengerjaan')->nullable(); // catatan teknisi saat upload bukti kerja

            $table->enum('status_pesanan', [
                'mencari_teknisi',
                'menuju_lokasi',
                'tiba',
                'pengecekan_awal',
                'menunggu_persetujuan_biaya',
                'dikerjakan',
                'menunggu_pembayaran',
                'selesai',
                'dibatalkan',
            ])->default('mencari_teknisi');
            $table->decimal('total_biaya', 12, 2)->default(0);

            // Tawaran ke teknisi (UC-20)
            $table->dateTime('batas_tawaran')->nullable();
            $table->json('teknisi_menolak')->nullable(); // daftar id teknisi yang menolak/timeout

            // Persetujuan biaya perbaikan (UC-14)
            $table->dateTime('batas_persetujuan_biaya')->nullable();

            $table->string('alasan_pembatalan')->nullable();

            // Waktu tiap tahap, untuk garis waktu di aplikasi
            $table->dateTime('diterima_pada')->nullable();
            $table->dateTime('tiba_pada')->nullable();
            $table->dateTime('pengecekan_pada')->nullable();
            $table->dateTime('dikerjakan_pada')->nullable();
            $table->dateTime('menunggu_pembayaran_pada')->nullable();
            $table->dateTime('selesai_pada')->nullable();
            $table->dateTime('dibatalkan_pada')->nullable();

            $table->dateTime('dibuat_pada')->useCurrent();
            $table->dateTime('diubah_pada')->useCurrent()->useCurrentOnUpdate();

            $table->foreign(['id_lokasi', 'id_pelanggan'], 'fk_pesanan_lokasi')
                ->references(['id_lokasi', 'id_pengguna'])->on('lokasi');
            // Dipakai foreign key gabungan dari pendapatan.
            $table->unique(['id_pesanan', 'id_teknisi'], 'uq_pesanan_teknisi');
            $table->index(['status_pesanan', 'jadwal_service']);
        });

        // Alamat yang sudah dipakai pesanan tidak boleh diubah, supaya riwayat
        // pesanan tidak ikut berubah. Aplikasi juga memeriksa aturan ini;
        // trigger hanya pengaman tambahan di MySQL.
        if (DB::getDriverName() === 'mysql') {
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
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::unprepared('DROP TRIGGER IF EXISTS trg_lokasi_immutable');
        }

        Schema::dropIfExists('pesanan');
    }
};
