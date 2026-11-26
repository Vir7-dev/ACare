<?php

namespace App\Http\Resources;

use App\Models\DetailPesanan;
use App\Models\Pembayaran;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Pesanan dilihat pelanggan. Muat relasi `detail.layanan`, `lokasi`,
 * `pembayaran`, dan `teknisi.pengguna` sebelum memakai resource ini.
 *
 * @mixin Pesanan
 */
class PesananResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $layanan = $this->detail->firstWhere('jenis_item', DetailPesanan::JENIS_LAYANAN);
        $biayaDitagih = $this->status_biaya === Pesanan::BIAYA_DISETUJUI;
        $teknisi = $this->teknisi;

        return [
            'id' => $this->id_pesanan,
            'kode' => $this->kode,
            'status' => $this->status_pesanan,
            'label_status' => $this->label_status_pelanggan,
            'layanan' => $layanan ? [
                'id' => $layanan->id_layanan,
                'nama' => $layanan->nama_item,
                'harga' => (int) $layanan->harga,
                'bisa_biaya_tambahan' => (bool) $layanan->layanan?->bisaBiayaTambahan(),
            ] : null,
            'jumlah_unit' => $layanan?->jumlah ?? 1,
            'jenis_ac' => $this->jenis_ac,
            'pk' => $this->pk === null ? null : (float) $this->pk,
            'merek' => $this->merek,
            'alamat' => new LokasiResource($this->lokasi),
            'detail_lokasi' => $this->detail_lokasi,
            'jadwal_service' => $this->jadwal_service?->toIso8601String(),
            'detail_layanan' => $this->detail_layanan ?? (object) [],
            'catatan' => $this->catatan_pelanggan,
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
                'catatan_teknisi' => $this->catatan_biaya,
                'batas_persetujuan' => $this->batas_persetujuan_biaya?->toIso8601String(),
            ],
            'pembayaran' => $this->pembayaran->sortBy('id_pembayaran')->map(fn (Pembayaran $p) => [
                'id' => $p->id_pembayaran,
                'jenis' => $p->jenis_pembayaran,
                'status' => $p->status_pembayaran,
                'jumlah' => (int) $p->jumlah_bayar,
                'metode' => $p->metode_pembayaran,
                'kedaluwarsa_pada' => $p->kedaluwarsa_pada?->toIso8601String(),
                'dibayar_pada' => $p->waktu_pembayaran?->toIso8601String(),
            ])->values(),
            'teknisi' => $teknisi ? [
                'id' => $teknisi->id_pengguna,
                'nama' => $teknisi->pengguna?->nama,
                'no_telepon' => $teknisi->pengguna?->no_telepon,
                'jenis_kendaraan' => $teknisi->jenis_kendaraan,
                'plat_nomor' => $teknisi->plat_nomor,
                'deskripsi' => $teknisi->deskripsi,
                'foto_profil' => $teknisi->pengguna?->foto_profil
                    ? asset('storage/'.$teknisi->pengguna->foto_profil)
                    : null,
            ] : null,
            'bisa_dibatalkan' => $this->bisaDibatalkan(),
            'alasan_pembatalan' => $this->alasan_pembatalan,
            'waktu' => [
                'dibuat' => $this->dibuat_pada?->toIso8601String(),
                'diterima' => $this->diterima_pada?->toIso8601String(),
                'tiba' => $this->tiba_pada?->toIso8601String(),
                'pengecekan' => $this->pengecekan_pada?->toIso8601String(),
                'dikerjakan' => $this->dikerjakan_pada?->toIso8601String(),
                'menunggu_pembayaran' => $this->menunggu_pembayaran_pada?->toIso8601String(),
                'selesai' => $this->selesai_pada?->toIso8601String(),
                'dibatalkan' => $this->dibatalkan_pada?->toIso8601String(),
            ],
        ];
    }
}
