<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FotoBuktiPengerjaan extends Model
{
    // Nilai kolom tahap; kondisi = foto dari pelanggan saat memesan.
    public const TAHAP = ['kondisi', 'pemeriksaan', 'sebelum', 'sesudah', 'tambahan'];

    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'foto_bukti_pengerjaan';

    protected $primaryKey = 'id_foto';

    protected $fillable = ['id_pesanan', 'tahap', 'path_foto'];

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }
}
