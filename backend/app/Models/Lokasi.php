<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Alamat tersimpan milik pelanggan. */
class Lokasi extends Model
{
    protected $table = 'lokasi';

    protected $primaryKey = 'id_lokasi';

    public $timestamps = false;

    protected $fillable = ['id_pengguna', 'label_alamat', 'alamat_lengkap', 'latitude', 'longitude'];

    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
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

    /** Alamat yang sudah dipakai pesanan tidak boleh diubah atau dihapus. */
    public function sudahDipakai(): bool
    {
        return $this->pesanan()->exists();
    }
}
