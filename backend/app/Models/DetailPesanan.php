<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Baris biaya pesanan: layanan yang dipesan pelanggan, atau item biaya
 * perbaikan (jasa/suku cadang) yang diajukan teknisi.
 */
class DetailPesanan extends Model
{
    protected $table = 'detail_pesanan';

    protected $primaryKey = 'id_detail';

    public $timestamps = false;

    protected $fillable = ['id_pesanan', 'id_layanan', 'nama_item', 'jumlah', 'harga', 'diajukan_oleh'];

    protected function casts(): array
    {
        return [
            'jumlah' => 'integer',
            'harga' => 'decimal:2',
        ];
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }

    public function layanan(): BelongsTo
    {
        return $this->belongsTo(Layanan::class, 'id_layanan', 'id_layanan');
    }

    public function getSubtotalAttribute(): float
    {
        return $this->jumlah * (float) $this->harga;
    }
}
