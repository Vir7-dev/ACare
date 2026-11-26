<?php

use App\Models\Pesanan;
use App\Services\AlurPesanan;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
| Batas waktu pesanan (tawaran 30 detik, persetujuan biaya 5 menit,
| pencarian 15 menit) juga diperiksa setiap ada permintaan API. Perintah ini
| cadangan untuk pesanan yang tidak sedang dibuka siapa pun.
*/
Artisan::command('pesanan:proses', function (AlurPesanan $alur) {
    $jumlah = 0;
    Pesanan::query()
        ->where(fn ($q) => $q
            ->where(fn ($q) => $q->where('status_pesanan', Pesanan::MENCARI_TEKNISI)->whereNotNull('pencarian_dimulai_pada'))
            ->orWhere('status_pesanan', Pesanan::MENUNGGU_PERSETUJUAN_BIAYA))
        ->each(function (Pesanan $p) use ($alur, &$jumlah) {
            $alur->perbarui($p);
            $jumlah++;
        });
    $this->info("Diperiksa: {$jumlah} pesanan.");
})->purpose('Proses batas waktu tawaran, persetujuan biaya, dan pencarian teknisi');

Schedule::command('pesanan:proses')->everyMinute()->withoutOverlapping();
