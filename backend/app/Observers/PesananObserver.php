<?php

namespace App\Observers;

use App\Models\Pesanan;
use App\Services\Pemberitahu;

/**
 * Notifikasi untuk setiap perpindahan status pesanan, dari mana pun
 * asalnya (aplikasi, scheduler, webhook Xendit). Perubahan dibaca saat
 * model disimpan; pengirimannya ditunda sampai transaksi selesai
 * (Pemberitahu), jadi tidak ada notifikasi untuk perubahan yang batal.
 */
class PesananObserver
{
    public function __construct(private Pemberitahu $pemberitahu) {}

    public function updated(Pesanan $p): void
    {
        if ($p->wasChanged('id_teknisi_ditawari') && $p->id_teknisi_ditawari) {
            $this->pemberitahu->kirim(
                (int) $p->id_teknisi_ditawari, 'tawaran', 'Pesanan masuk!',
                $this->namaLayanan($p).' di '.($p->lokasi?->label_alamat ?: 'dekatmu')
                    .'. Jawab dalam '.Pesanan::BATAS_TAWARAN_DETIK.' detik.',
                $p,
            );
        }

        if (! $p->wasChanged('status_pesanan')) {
            return;
        }

        $sebelum = $p->getOriginal('status_pesanan');
        $teknisi = $p->teknisi?->pengguna?->nama ?? 'Teknisi';

        match ($p->status_pesanan) {
            Pesanan::MENUJU_LOKASI => $this->kePelanggan($p, 'teknisi_ditemukan', 'Teknisi ditemukan',
                "{$teknisi} sedang menuju lokasimu."),
            Pesanan::TIBA => $this->kePelanggan($p, 'teknisi_tiba', 'Teknisi sudah tiba',
                "{$teknisi} sudah sampai di lokasi."),
            Pesanan::MENUNGGU_PERSETUJUAN_BIAYA => $this->kePelanggan($p, 'persetujuan_biaya', 'Rincian biaya perlu persetujuan',
                'Tanggapi rincian biaya perbaikan dalam '.Pesanan::BATAS_PERSETUJUAN_MENIT.' menit.'),
            Pesanan::DIKERJAKAN => $sebelum === Pesanan::MENUNGGU_PERSETUJUAN_BIAYA
                ? $this->keTeknisi($p, 'biaya_ditanggapi',
                    $p->status_biaya === Pesanan::BIAYA_DISETUJUI ? 'Biaya disetujui' : 'Biaya tidak disetujui',
                    $p->status_biaya === Pesanan::BIAYA_DISETUJUI
                        ? 'Pelanggan menyetujui rincian biaya. Lanjutkan perbaikan.'
                        : 'Lanjutkan pekerjaan dengan biaya awal saja.')
                : null,
            Pesanan::MENUNGGU_PEMBAYARAN => $this->kePelanggan($p, 'pelunasan', 'Pekerjaan selesai',
                'Lunasi biaya perbaikan untuk menyelesaikan pesanan.'),
            Pesanan::SELESAI => $this->selesai($p, $sebelum),
            Pesanan::DIBATALKAN => $p->alasan_pembatalan === Pesanan::ALASAN_TANPA_TEKNISI
                ? $this->kePelanggan($p, 'tanpa_teknisi', 'Belum ada teknisi tersedia',
                    'Pesanan dibatalkan otomatis. Dana kamu ditahan dan bisa diajukan refund.')
                : null,
            default => null,
        };
    }

    private function selesai(Pesanan $p, ?string $sebelum): void
    {
        $this->kePelanggan($p, 'selesai', 'Pesanan selesai', 'Terima kasih! Beri ulasan untuk teknisimu.');
        if ($sebelum === Pesanan::MENUNGGU_PEMBAYARAN) {
            $this->keTeknisi($p, 'pelunasan_diterima', 'Pelunasan diterima', 'Pendapatan pesanan '.$p->kode.' sudah masuk dompet.');
        } else {
            $this->keTeknisi($p, 'pesanan_selesai', 'Pesanan selesai', 'Pendapatan pesanan '.$p->kode.' sudah masuk dompet.');
        }
    }

    private function kePelanggan(Pesanan $p, string $tipe, string $judul, string $isi): void
    {
        $this->pemberitahu->kirim((int) $p->id_pelanggan, $tipe, $judul, $isi, $p);
    }

    private function keTeknisi(Pesanan $p, string $tipe, string $judul, string $isi): void
    {
        if ($p->id_teknisi) {
            $this->pemberitahu->kirim((int) $p->id_teknisi, $tipe, $judul, $isi, $p);
        }
    }

    private function namaLayanan(Pesanan $p): string
    {
        return $p->detail()->where('jenis_item', 'layanan')->value('nama_item') ?? 'Pesanan servis AC';
    }
}
