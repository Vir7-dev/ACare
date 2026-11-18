<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Pengajuan dana yang ditransfer manual oleh Admin:
 * pencairan pendapatan teknisi atau refund pelanggan.
 */
class PengajuanDana extends Model
{
    public const PENCAIRAN = 'pencairan';

    public const REFUND = 'refund';

    /** Batas minimum pencairan pendapatan teknisi (Rp). */
    public const MINIMUM_PENCAIRAN = 50000;

    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = 'diubah_pada';

    protected $table = 'pengajuan_dana';

    protected $primaryKey = 'id_pengajuan';

    protected $fillable = [
        'jenis', 'id_pemohon', 'id_pesanan', 'nominal', 'nama_bank', 'no_rekening', 'atas_nama',
        'alasan', 'status', 'alasan_penolakan', 'id_admin', 'diproses_pada',
    ];

    protected function casts(): array
    {
        return [
            'nominal' => 'decimal:2',
            'diproses_pada' => 'datetime',
        ];
    }

    public function pemohon(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pemohon', 'id_pengguna');
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_admin', 'id_pengguna');
    }
}
