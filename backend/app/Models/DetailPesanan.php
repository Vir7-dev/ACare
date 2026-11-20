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

    public const JENIS_LAYANAN = 'layanan';

    public const JENIS_JASA = 'jasa';

    public const JENIS_SUKU_CADANG = 'suku_cadang';

    protected $fillable = ['id_pesanan', 'id_layanan', 'jenis_item', 'nama_item', 'jumlah', 'harga'];

    protected $attributes = ['jenis_item' => self::JENIS_LAYANAN];

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

    /** Item jasa/suku cadang diajukan teknisi; layanan dipesan pelanggan. */
    public function dariTeknisi(): bool
    {
        return $this->jenis_item !== self::JENIS_LAYANAN;
    }

    public function getSubtotalAttribute(): float
    {
        return $this->jumlah * (float) $this->harga;
    }
}
