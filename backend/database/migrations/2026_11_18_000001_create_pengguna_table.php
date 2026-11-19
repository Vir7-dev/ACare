<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pengguna', function (Blueprint $table) {
            $table->id('id_pengguna');
            $table->string('nama', 100);
            $table->string('email', 150)->unique();
            $table->string('no_telepon', 20)->unique();
            $table->string('kata_sandi');
            $table->enum('role', ['pelanggan', 'teknisi', 'admin']);
            $table->string('foto_profil')->nullable();
            $table->enum('status_akun', ['aktif', 'diblokir'])->default('aktif');
            $table->dateTime('dibuat_pada')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengguna');
    }
};
