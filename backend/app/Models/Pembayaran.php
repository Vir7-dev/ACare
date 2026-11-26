<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Pembayaran pelanggan lewat Xendit (awal dan pelunasan). */
class Pembayaran extends Model
{
    public const AWAL = 'awal';

    public const PELUNASAN = 'pelunasan';

    public const MENUNGGU = 'menunggu';

    public const BERHASIL = 'berhasil';

    public const KEDALUWARSA = 'kedaluwarsa';

    /** Sudah dibayar tetapi pesanan batal: menunggu pengajuan refund. */
    public const TERTAHAN = 'tertahan';

    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'pembayaran';

    protected $primaryKey = 'id_pembayaran';

    protected $fillable = [
        'id_pesanan', 'jenis_pembayaran', 'metode_pembayaran', 'jumlah_bayar', 'status_pembayaran',
        'referensi_transaksi', 'url_pembayaran', 'kedaluwarsa_pada', 'waktu_pembayaran',
    ];

    protected function casts(): array
    {
        return [
            'jumlah_bayar' => 'decimal:2',
            'kedaluwarsa_pada' => 'datetime',
            'waktu_pembayaran' => 'datetime',
        ];
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }
}
