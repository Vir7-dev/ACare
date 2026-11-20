<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

/**
 * Akun ACare disimpan di tabel pengguna; tabel users bawaan Laravel tidak
 * dipakai. Migrasi bawaan sudah tidak membuatnya lagi, migrasi ini
 * membersihkannya dari database yang terlanjur dimigrasi.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('users');
    }

    public function down(): void
    {
        // Sengaja kosong: tabel users memang tidak dipakai lagi.
    }
};
