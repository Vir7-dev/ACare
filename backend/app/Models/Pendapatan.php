<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Bagi hasil satu pesanan selesai antara platform dan teknisi. */
class Pendapatan extends Model
{
    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'pendapatan';

    protected $primaryKey = 'id_pendapatan';

    protected $fillable = [
        'id_pesanan', 'id_teknisi', 'persentase_platform', 'pendapatan_platform', 'pendapatan_teknisi',
    ];

    protected function casts(): array
    {
        return [
            'persentase_platform' => 'decimal:2',
            'pendapatan_platform' => 'decimal:2',
            'pendapatan_teknisi' => 'decimal:2',
        ];
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }

    public function teknisi(): BelongsTo
    {
        return $this->belongsTo(Teknisi::class, 'id_teknisi', 'id_pengguna');
    }

    /**
     * Hitung bagi hasil dari total yang dibayar pelanggan.
     *
     * @return array{pendapatan_platform: float, pendapatan_teknisi: float}
     */
    public static function hitung(float $totalDibayar, float $persentasePlatform): array
    {
        $platform = round($totalDibayar * $persentasePlatform / 100, 2);

        return [
            'pendapatan_platform' => $platform,
            'pendapatan_teknisi' => round($totalDibayar - $platform, 2),
        ];
    }
}
