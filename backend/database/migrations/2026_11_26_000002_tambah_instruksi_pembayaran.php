<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pembayaran', function (Blueprint $table) {
            // Yang ditampilkan ke pelanggan: isi kode QRIS atau nomor Virtual Account.
            $table->text('kode_bayar')->nullable()->after('referensi_transaksi');
            // Tautan e-wallet dari Xendit bisa lebih dari 255 karakter.
            $table->text('url_pembayaran')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('pembayaran', function (Blueprint $table) {
            $table->dropColumn('kode_bayar');
            $table->string('url_pembayaran')->nullable()->change();
        });
    }
};
