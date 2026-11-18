<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fcm_token', function (Blueprint $table) {
            $table->id('id_fcm');
            $table->foreignId('id_pengguna')->constrained('pengguna', 'id_pengguna')->cascadeOnDelete();
            $table->string('token', 512)->unique();
            $table->dateTime('dibuat_pada')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fcm_token');
    }
};
