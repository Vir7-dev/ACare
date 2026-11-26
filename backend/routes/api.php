<?php

use App\Http\Controllers\Api\AlamatController;
use App\Http\Controllers\Api\AutentikasiController;
use App\Http\Controllers\Api\LayananController;
use App\Http\Controllers\Api\PesananController;
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

    Route::get('/layanan', [LayananController::class, 'index'])->name('api.layanan');

    Route::middleware('peran:pelanggan')->group(function () {
        Route::get('/alamat', [AlamatController::class, 'index'])->name('api.alamat');
        Route::post('/alamat', [AlamatController::class, 'store'])->name('api.alamat.simpan');
        Route::put('/alamat/{id}', [AlamatController::class, 'update'])->whereNumber('id')->name('api.alamat.ubah');
        Route::delete('/alamat/{id}', [AlamatController::class, 'destroy'])->whereNumber('id')->name('api.alamat.hapus');

        Route::get('/pesanan', [PesananController::class, 'index'])->name('api.pesanan');
        Route::post('/pesanan', [PesananController::class, 'store'])->name('api.pesanan.buat');
        Route::get('/pesanan/{id}', [PesananController::class, 'show'])->whereNumber('id')->name('api.pesanan.detail');
        Route::post('/pesanan/{id}/batal', [PesananController::class, 'batal'])->whereNumber('id')->name('api.pesanan.batal');
    });
});
