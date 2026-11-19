<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DokumenVerifikasi extends Model
{
    protected $table = 'dokumen_verifikasi';

    protected $primaryKey = 'id_dokumen';

    public $timestamps = false;

    protected $fillable = ['id_teknisi', 'jenis_dokumen', 'path_file'];

    public function teknisi(): BelongsTo
    {
        return $this->belongsTo(Teknisi::class, 'id_teknisi', 'id_pengguna');
    }
}
