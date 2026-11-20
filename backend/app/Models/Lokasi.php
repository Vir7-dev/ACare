<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Alamat tersimpan milik pelanggan.
 *
 * Dihapus secara lunak (dihapus_pada): alamat hilang dari daftar pelanggan,
 * tetapi pesanan lama tetap bisa menampilkan alamatnya.
 */
class Lokasi extends Model
{
    use SoftDeletes;

    public const DELETED_AT = 'dihapus_pada';

    protected $table = 'lokasi';

    protected $primaryKey = 'id_lokasi';

    public $timestamps = false;

    protected $fillable = ['id_pengguna', 'label_alamat', 'alamat_lengkap', 'latitude', 'longitude'];

    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'dihapus_pada' => 'datetime',
        ];
    }

    public function pengguna(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pengguna', 'id_pengguna');
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'id_lokasi', 'id_lokasi');
    }

    /** Isi alamat yang sudah dipakai pesanan tidak boleh diubah. */
    public function sudahDipakai(): bool
    {
        return $this->pesanan()->exists();
    }

    /**
     * Alamat yang sedang dipakai pesanan berjalan tidak boleh dihapus;
     * alamat dari pesanan yang sudah selesai/dibatalkan boleh.
     */
    public function bisaDihapus(): bool
    {
        return ! $this->pesanan()
            ->whereNotIn('status_pesanan', [Pesanan::SELESAI, Pesanan::DIBATALKAN])
            ->exists();
    }
}
