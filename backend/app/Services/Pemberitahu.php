<?php

namespace App\Services;

use App\Jobs\KirimNotifikasiFcm;
use App\Models\Notifikasi;
use App\Models\Pesanan;
use Illuminate\Support\Facades\DB;

/**
 * Satu pintu untuk memberi tahu pengguna: dicatat di tabel `notifikasi`
 * (riwayat di aplikasi) lalu dikirim sebagai push FCM.
 */
class Pemberitahu
{
    /**
     * Dijalankan setelah transaksi database yang sedang berjalan selesai
     * (langsung bila tidak ada transaksi); batal bila transaksinya batal.
     */
    public function kirim(int $idPenerima, string $tipe, string $judul, string $isi, ?Pesanan $pesanan = null): void
    {
        $idPesanan = $pesanan?->id_pesanan;
        DB::afterCommit(fn () => $this->simpanDanKirim($idPenerima, $tipe, $judul, $isi, $idPesanan));
    }

    private function simpanDanKirim(int $idPenerima, string $tipe, string $judul, string $isi, ?int $idPesanan): void
    {
        Notifikasi::create([
            'id_penerima' => $idPenerima,
            'id_pesanan' => $idPesanan,
            'judul' => $judul,
            'tipe_notifikasi' => $tipe,
            'isi_notifikasi' => $isi,
        ]);

        KirimNotifikasiFcm::dispatchAfterResponse($idPenerima, $judul, $isi, array_filter([
            'tipe' => $tipe,
            'id_pesanan' => $idPesanan,
        ], fn ($v) => $v !== null));
    }
}
