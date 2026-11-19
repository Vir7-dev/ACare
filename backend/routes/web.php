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

// 1. Autentikasi Admin Portal ACare
Route::get('/admin/login', [AuthController::class, 'showLogin'])->name('admin.login');
Route::post('/admin/login', [AuthController::class, 'login'])->name('admin.login.submit');
Route::post('/admin/logout', [AuthController::class, 'logout'])->name('admin.logout');

// 2. Beranda / Dashboard (Tugas Thoriq: Ringkasan Statistik, Omzet & Performa Platform)
Route::get('/', [DashboardController::class, 'index'])->name('admin.dashboard');

// Alamat lama menuju Beranda (hanya redirect, bukan halaman terpisah)
Route::redirect('/admin', '/');
Route::redirect('/admin/dashboard', '/');
Route::redirect('/admin/beranda', '/');

// 3. Kelola Transaksi & Monitoring Bukti Pengerjaan Servis AC
Route::get('/admin/transaksi', [TransaksiController::class, 'index'])->name('admin.transaksi');

// 4. Kelola Pengguna & Verifikasi Teknisi (Tugas Dina: Pengguna & Verifikasi Berkas Teknisi)
Route::get('/admin/pengguna', [PenggunaController::class, 'index'])->name('admin.pengguna');

// 5. Kelola Layanan (Tugas Achmal: 6 Katalog Layanan Resmi ACare)
Route::get('/admin/layanan', [LayananController::class, 'index'])->name('admin.layanan');

// 6. Pengaduan dari pelanggan/teknisi
Route::get('/admin/pengaduan', [PengaduanController::class, 'index'])->name('admin.pengaduan');

// 7. Moderasi rating & ulasan pelanggan
Route::get('/admin/ulasan', [UlasanController::class, 'index'])->name('admin.ulasan');

// 8. Pencairan pendapatan teknisi & refund pelanggan
Route::get('/admin/pencairan', [PencairanController::class, 'index'])->name('admin.pencairan');

// 9. Aksi perubahan status (disimpan di session sementara)
Route::post('/admin/pengguna/status', [PenggunaController::class, 'ubahStatus'])->name('admin.pengguna.status');
Route::post('/admin/pengguna/dokumen', [PenggunaController::class, 'ubahDokumen'])->name('admin.pengguna.dokumen');
Route::post('/admin/pengaduan/status', [PengaduanController::class, 'ubahStatus'])->name('admin.pengaduan.status');
Route::post('/admin/ulasan/status', [UlasanController::class, 'ubahStatus'])->name('admin.ulasan.status');
Route::post('/admin/pencairan/status', [PencairanController::class, 'ubahStatus'])->name('admin.pencairan.status');
Route::post('/admin/layanan/sinkron', [LayananController::class, 'sinkron'])->name('admin.layanan.sinkron');

// Redirect rute statistik lama ke Beranda Dashboard agar selalu sinkron
Route::redirect('/admin/statistik', '/');
