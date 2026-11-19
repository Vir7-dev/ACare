<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notifikasi extends Model
{
    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'notifikasi';

    protected $primaryKey = 'id_notifikasi';

    protected $fillable = ['id_penerima', 'id_pesanan', 'judul', 'tipe_notifikasi', 'isi_notifikasi', 'status_dibaca'];

    protected function casts(): array
    {
        return ['status_dibaca' => 'boolean'];
    }

    public function penerima(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_penerima', 'id_pengguna');
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }
}
