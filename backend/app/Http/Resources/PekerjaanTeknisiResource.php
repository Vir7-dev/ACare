<?php

namespace App\Http\Resources;

use App\Models\DetailPesanan;
use App\Models\FotoBuktiPengerjaan;
use App\Models\Pesanan;
use App\Support\Jarak;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Pesanan dilihat teknisi: sebagai tawaran (kontak pelanggan disembunyikan)
 * atau sebagai pekerjaan yang sudah diterima. Muat `detail.layanan`,
 * `lokasi`, `pelanggan`, dan `fotoBukti` sebelum memakai resource ini.
 *
 * @mixin Pesanan
 */
class PekerjaanTeknisiResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $layanan = $this->detail->firstWhere('jenis_item', DetailPesanan::JENIS_LAYANAN);
        $teknisi = $request->user()?->teknisi;
        $tawaran = $this->status_pesanan === Pesanan::MENCARI_TEKNISI;
        $km = ($teknisi?->latitude !== null && $this->lokasi)
            ? Jarak::km((float) $teknisi->latitude, (float) $teknisi->longitude,
                (float) $this->lokasi->latitude, (float) $this->lokasi->longitude)
            : null;
        $biayaDitagih = $this->status_biaya === Pesanan::BIAYA_DISETUJUI;

        return [
            'id' => $this->id_pesanan,
            'kode' => $this->kode,
            'status' => $this->status_pesanan,
            'layanan' => $layanan?->nama_item,
            'bisa_biaya_tambahan' => (bool) $layanan?->layanan?->bisaBiayaTambahan(),
            'jumlah_unit' => $layanan?->jumlah ?? 1,
            'jenis_ac' => $this->jenis_ac,
            'pk' => $this->pk === null ? null : (float) $this->pk,
            'merek' => $this->merek,
            'biaya_awal' => (int) ($layanan?->subtotal ?? 0),
            'detail_layanan' => $this->detail_layanan ?? (object) [],
            'catatan' => $this->catatan_pelanggan,
            'pelanggan' => [
                'nama' => $this->pelanggan?->nama,
                // Nomor telepon baru terlihat setelah tawaran diterima.
                'no_telepon' => $tawaran ? null : $this->pelanggan?->no_telepon,
            ],
            'alamat' => [
                'alamat_lengkap' => $this->lokasi?->alamat_lengkap,
                'detail_lokasi' => $this->detail_lokasi,
                'latitude' => $this->lokasi ? (float) $this->lokasi->latitude : null,
                'longitude' => $this->lokasi ? (float) $this->lokasi->longitude : null,
            ],
            'jarak_km' => $km === null ? null : round($km, 1),
            'menit_tempuh' => $km === null ? null : Jarak::menit($km),
            'jadwal_service' => $this->jadwal_service?->toIso8601String(),
            'tawaran' => $this->when($tawaran, fn () => [
                'batas' => $this->batas_tawaran?->toIso8601String(),
                'sisa_detik' => $this->batas_tawaran
                    ? max(0, (int) now()->diffInSeconds($this->batas_tawaran, false))
                    : 0,
            ]),
            'biaya' => [
                'rincian' => $this->detail->map(fn (DetailPesanan $d) => [
                    'nama' => $d->nama_item,
                    'jenis' => $d->jenis_item,
                    'jumlah' => $d->jumlah,
                    'harga' => (int) $d->harga,
                    'subtotal' => (int) $d->subtotal,
                    'ditagih' => ! $d->dariTeknisi() || $biayaDitagih,
                ])->values(),
                'total' => (int) $this->total_biaya,
                'status_biaya' => $this->status_biaya,
                'catatan' => $this->catatan_biaya,
                'batas_persetujuan' => $this->batas_persetujuan_biaya?->toIso8601String(),
            ],
            'foto' => $this->fotoBukti->map(fn (FotoBuktiPengerjaan $f) => [
                'id' => $f->id_foto,
                'tahap' => $f->tahap,
            ])->values(),
            'waktu' => [
                'diterima' => $this->diterima_pada?->toIso8601String(),
                'tiba' => $this->tiba_pada?->toIso8601String(),
                'pengecekan' => $this->pengecekan_pada?->toIso8601String(),
                'dikerjakan' => $this->dikerjakan_pada?->toIso8601String(),
                'menunggu_pembayaran' => $this->menunggu_pembayaran_pada?->toIso8601String(),
                'selesai' => $this->selesai_pada?->toIso8601String(),
            ],
        ];
    }
}
