<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rating_ulasan', function (Blueprint $table) {
            $table->id('id_rating');
            $table->foreignId('id_pesanan')->unique()->constrained('pesanan', 'id_pesanan')->cascadeOnDelete();
            $table->unsignedTinyInteger('rating'); // 1-5
            $table->text('ulasan')->nullable();
            $table->json('tag')->nullable(); // pilihan "yang paling kamu sukai"
            $table->boolean('ditampilkan')->default(true); // false = disembunyikan Admin
            $table->dateTime('dibuat_pada')->useCurrent();
        });

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE rating_ulasan ADD CONSTRAINT chk_rating_nilai CHECK (rating BETWEEN 1 AND 5)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('rating_ulasan');
    }
};
