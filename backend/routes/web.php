<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\LayananController;
use App\Http\Controllers\Admin\PencairanController;
use App\Http\Controllers\Admin\PengaduanController;
use App\Http\Controllers\Admin\PenggunaController;
use App\Http\Controllers\Admin\TransaksiController;
use App\Http\Controllers\Admin\UlasanController;
use Illuminate\Support\Facades\Route;

// Rute bebas akses (belum login)
Route::get('/admin/login', [AuthController::class, 'showLogin'])->name('admin.login');
Route::post('/admin/login', [AuthController::class, 'login'])->name('admin.login.submit');

// Semua rute admin yang wajib login
Route::middleware('admin.auth')->group(function (): void {
    Route::post('/admin/logout', [AuthController::class, 'logout'])->name('admin.logout');

    // Beranda
    Route::get('/', [DashboardController::class, 'index'])->name('admin.dashboard');

    // Redirect rute lama
    Route::redirect('/admin', '/');
    Route::redirect('/admin/dashboard', '/');
    Route::redirect('/admin/beranda', '/');
    Route::redirect('/admin/statistik', '/');

    // Halaman utama portal admin
    Route::get('/admin/transaksi', [TransaksiController::class, 'index'])->name('admin.transaksi');
    Route::get('/admin/pengguna', [PenggunaController::class, 'index'])->name('admin.pengguna');
    Route::get('/admin/layanan', [LayananController::class, 'index'])->name('admin.layanan');
    Route::get('/admin/pengaduan', [PengaduanController::class, 'index'])->name('admin.pengaduan');
    Route::get('/admin/ulasan', [UlasanController::class, 'index'])->name('admin.ulasan');
    Route::get('/admin/pencairan', [PencairanController::class, 'index'])->name('admin.pencairan');

    // Endpoint aksi POST
    Route::post('/admin/pengguna/status', [PenggunaController::class, 'ubahStatus'])->name('admin.pengguna.status');
    Route::post('/admin/pengguna/dokumen', [PenggunaController::class, 'ubahDokumen'])->name('admin.pengguna.dokumen');
    Route::post('/admin/pengaduan/status', [PengaduanController::class, 'ubahStatus'])->name('admin.pengaduan.status');
    Route::post('/admin/ulasan/status', [UlasanController::class, 'ubahStatus'])->name('admin.ulasan.status');
    Route::post('/admin/pencairan/status', [PencairanController::class, 'ubahStatus'])->name('admin.pencairan.status');
    Route::post('/admin/layanan/sinkron', [LayananController::class, 'sinkron'])->name('admin.layanan.sinkron');
});
