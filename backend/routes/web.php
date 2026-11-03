<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\PenggunaController;
use App\Http\Controllers\Admin\LayananController;
use App\Http\Controllers\Admin\TransaksiController;

// 1. Autentikasi Admin Portal ACare
Route::get('/admin/login', [AuthController::class, 'showLogin'])->name('admin.login');
Route::post('/admin/login', [AuthController::class, 'login'])->name('admin.login.submit');
Route::match(['get', 'post'], '/admin/logout', [AuthController::class, 'logout'])->name('admin.logout');

// 2. Beranda / Dashboard (Tugas Thoriq: Ringkasan Statistik, Omzet & Performa Platform)
Route::get('/', [DashboardController::class, 'index'])->name('admin.dashboard');
Route::get('/admin', [DashboardController::class, 'index'])->name('admin.dashboard.alias');
Route::get('/admin/dashboard', [DashboardController::class, 'index'])->name('admin.dashboard.main');
Route::get('/admin/beranda', [DashboardController::class, 'index'])->name('admin.beranda');

// 3. Kelola Transaksi & Monitoring Bukti Pengerjaan Servis AC
Route::get('/admin/transaksi', [TransaksiController::class, 'index'])->name('admin.transaksi');

// 4. Kelola Pengguna & Verifikasi Teknisi (Tugas Dina: Pengguna & Verifikasi Berkas Teknisi)
Route::get('/admin/pengguna', [PenggunaController::class, 'index'])->name('admin.pengguna');

// 5. Kelola Layanan (Tugas Achmal: 6 Katalog Layanan Resmi ACare)
Route::get('/admin/layanan', [LayananController::class, 'index'])->name('admin.layanan');

// Redirect rute statistik lama ke Beranda Dashboard agar selalu sinkron
Route::get('/admin/statistik', function () {
    return redirect()->route('admin.dashboard');
});
