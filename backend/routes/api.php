<?php

use App\Http\Controllers\Api\AutentikasiController;
use App\Http\Controllers\Api\ProfilController;
use Illuminate\Support\Facades\Route;

/*
| API aplikasi mobile ACare (prefix /api). Semua respons berupa JSON;
| galat punya "message" (siap ditampilkan) dan, bila perlu, "kode".
*/

Route::middleware('throttle:10,1')->group(function () {
    Route::post('/daftar', [AutentikasiController::class, 'daftar'])->name('api.daftar');
    Route::post('/daftar/teknisi', [AutentikasiController::class, 'daftarTeknisi'])->name('api.daftar.teknisi');
});
Route::post('/masuk', [AutentikasiController::class, 'masuk'])->name('api.masuk');

Route::middleware(['auth:sanctum', 'akun.aktif'])->group(function () {
    Route::post('/keluar', [AutentikasiController::class, 'keluar'])->name('api.keluar');

    Route::get('/saya', [ProfilController::class, 'tampil'])->name('api.saya');
    Route::put('/saya', [ProfilController::class, 'ubah'])->name('api.saya.ubah');
    Route::post('/saya/foto', [ProfilController::class, 'ubahFoto'])->name('api.saya.foto');
    Route::put('/saya/kata-sandi', [ProfilController::class, 'ubahKataSandi'])->name('api.saya.kata-sandi');
});
