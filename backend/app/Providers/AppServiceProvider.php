<?php

namespace App\Providers;

use App\Http\Controllers\Admin\PencairanController;
use App\Http\Controllers\Admin\PengaduanController;
use App\Http\Controllers\Admin\PenggunaController;
use App\Http\Controllers\Admin\TransaksiController;
use App\Http\Controllers\Admin\UlasanController;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Indeks ringkas untuk pencarian global (transaksi, pengguna, pengaduan,
     * ulasan, pencairan dan refund).
     * Hanya berisi teks pendek; tidak ada data sensitif seperti telepon atau alamat.
     *
     * @return array<int, array{jenis: string, id: string, judul: string, info: string}>
     */
    private static function indeksCari(): array
    {
        $hasil = [];

        foreach (TransaksiController::daftarTransaksi() as $t) {
            $hasil[] = ['jenis' => 'Transaksi', 'id' => $t['id'], 'judul' => $t['id'].' · '.$t['pelanggan'], 'info' => $t['layanan'].' · '.$t['status']];
        }
        foreach (PenggunaController::daftarPengguna() as $p) {
            $hasil[] = ['jenis' => 'Pengguna', 'id' => $p['id'], 'judul' => $p['nama'], 'info' => $p['peran'].' · '.$p['id']];
        }
        foreach (PengaduanController::daftarPengaduan() as $a) {
            $hasil[] = ['jenis' => 'Pengaduan', 'id' => $a['id'], 'judul' => $a['id'].' · '.$a['pelapor'], 'info' => $a['kategori'].' · '.$a['status']];
        }

        foreach (UlasanController::daftarUlasan() as $u) {
            $hasil[] = ['jenis' => 'Ulasan', 'id' => $u['id'], 'judul' => $u['id'].' · '.$u['pelanggan'], 'info' => 'Rating '.$u['rating'].' untuk '.$u['teknisi'].' · '.$u['status']];
        }
        foreach (PencairanController::daftarPengajuan() as $p) {
            $hasil[] = ['jenis' => 'Pencairan', 'id' => $p['id'], 'judul' => $p['id'].' · '.$p['pemohon'], 'info' => $p['jenis'].' · '.$p['status']];
        }

        return $hasil;
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        View::composer('layouts.admin', function ($view): void {
            $view->with('jumlahTeknisiMenunggu', count(PenggunaController::teknisiMenunggu()));
            $view->with('jumlahPengaduanBaru', PengaduanController::jumlahBaru());
            $view->with('jumlahPengajuanMenunggu', PencairanController::jumlahMenunggu());
            $view->with('indeksCari', self::indeksCari());
        });

        View::composer('admin.partials.detail-transaksi', function ($view): void {
            $view->with('daftarTransaksi', TransaksiController::daftarTransaksi());
        });
    }
}
