<?php

use App\Http\Controllers\Api\AlamatController;
use App\Http\Controllers\Api\AutentikasiController;
use App\Http\Controllers\Api\LayananController;
use App\Http\Controllers\Api\PembayaranController;
use App\Http\Controllers\Api\PesananController;
use App\Http\Controllers\Api\ProfilController;
use App\Http\Controllers\Api\TeknisiController;
use App\Http\Controllers\Api\XenditWebhookController;
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

// Dipanggil server Xendit; diamankan dengan header x-callback-token.
Route::post('/xendit/webhook', XenditWebhookController::class)->name('api.xendit.webhook');

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
        Route::post('/pesanan/{id}/biaya', [PesananController::class, 'biaya'])->whereNumber('id')->name('api.pesanan.biaya');
        Route::post('/pesanan/{id}/pembayaran/{idPembayaran}/bayar', [PembayaranController::class, 'bayar'])
            ->whereNumber(['id', 'idPembayaran'])->middleware('throttle:20,1')->name('api.pesanan.bayar');
        Route::post('/pesanan/{id}/pembayaran/{idPembayaran}/simulasi-lunas', [PembayaranController::class, 'simulasi'])
            ->whereNumber(['id', 'idPembayaran'])->name('api.pesanan.simulasi-lunas');
    });

    // Foto bukti pengerjaan: pelanggan pemilik pesanan dan teknisinya.
    Route::get('/pesanan/{id}/foto/{idFoto}', [TeknisiController::class, 'foto'])
        ->whereNumber(['id', 'idFoto'])->name('api.pesanan.foto');

    Route::middleware('peran:teknisi')->prefix('teknisi')->group(function () {
        Route::put('/status', [TeknisiController::class, 'status'])->name('api.teknisi.status');
        Route::put('/lokasi', [TeknisiController::class, 'lokasi'])->name('api.teknisi.lokasi');
        Route::get('/tawaran', [TeknisiController::class, 'tawaran'])->name('api.teknisi.tawaran');
        Route::post('/tawaran/{id}/terima', [TeknisiController::class, 'terima'])->whereNumber('id')->name('api.teknisi.terima');
        Route::post('/tawaran/{id}/tolak', [TeknisiController::class, 'tolakTawaran'])->whereNumber('id')->name('api.teknisi.tolak');
        Route::get('/pekerjaan', [TeknisiController::class, 'pekerjaan'])->name('api.teknisi.pekerjaan');
        Route::post('/pekerjaan/{id}/tiba', [TeknisiController::class, 'tiba'])->whereNumber('id')->name('api.teknisi.tiba');
        Route::post('/pekerjaan/{id}/pengecekan', [TeknisiController::class, 'mulaiPengecekan'])->whereNumber('id')->name('api.teknisi.pengecekan');
        Route::post('/pekerjaan/{id}/foto-pemeriksaan', [TeknisiController::class, 'fotoPemeriksaan'])->whereNumber('id')->name('api.teknisi.foto-pemeriksaan');
        Route::post('/pekerjaan/{id}/biaya', [TeknisiController::class, 'ajukanBiaya'])->whereNumber('id')->name('api.teknisi.biaya');
        Route::post('/pekerjaan/{id}/tanpa-biaya', [TeknisiController::class, 'tanpaBiaya'])->whereNumber('id')->name('api.teknisi.tanpa-biaya');
        Route::post('/pekerjaan/{id}/selesai', [TeknisiController::class, 'selesai'])->whereNumber('id')->name('api.teknisi.selesai');
    });
});
