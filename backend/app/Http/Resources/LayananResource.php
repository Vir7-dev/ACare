<?php

namespace App\Http\Resources;

use App\Models\Layanan;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Layanan */
class LayananResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id_layanan,
            'nama' => $this->nama_layanan,
            'deskripsi' => $this->deskripsi_layanan,
            'harga' => (int) $this->harga,
            'estimasi_durasi' => $this->estimasi_durasi,
            'bisa_biaya_tambahan' => $this->bisaBiayaTambahan(),
        ];
    }
}
