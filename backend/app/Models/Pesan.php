<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Pesan chat antara pelanggan dan teknisi dalam satu pesanan. */
class Pesan extends Model
{
    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'pesan';

    protected $primaryKey = 'id_pesan';

    protected $fillable = ['id_pesanan', 'id_pengirim', 'tipe_pesan', 'isi', 'path_gambar', 'status_dibaca'];

    protected function casts(): array
    {
        return ['status_dibaca' => 'boolean'];
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }

    public function pengirim(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pengirim', 'id_pengguna');
    }
}
