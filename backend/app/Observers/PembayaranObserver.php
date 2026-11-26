<?php

namespace App\Observers;

use App\Models\Pembayaran;
use App\Services\Pemberitahu;

/**
 * Pelanggan diberi tahu saat biaya awal diterima. Pelunasan tidak perlu:
 * pesanan langsung selesai dan PesananObserver yang memberi tahu.
 */
class PembayaranObserver
{
    public function __construct(private Pemberitahu $pemberitahu) {}

    public function updated(Pembayaran $b): void
    {
        if (! $b->wasChanged('status_pembayaran')
            || $b->status_pembayaran !== Pembayaran::BERHASIL
            || $b->jenis_pembayaran !== Pembayaran::AWAL) {
            return;
        }

        $pesanan = $b->pesanan;
        $this->pemberitahu->kirim(
            (int) $pesanan->id_pelanggan, 'pembayaran_berhasil', 'Pembayaran diterima',
            'Terima kasih! Kami sedang mencarikan teknisi terdekat.', $pesanan,
        );
    }
}
