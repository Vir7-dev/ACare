<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Layanan extends Model
{
    protected $table = 'layanan';

    protected $primaryKey = 'id_layanan';

    public $timestamps = false;

    protected $fillable = [
        'nama_layanan', 'deskripsi_layanan', 'harga', 'estimasi_durasi',
        'persentase_platform', 'status_layanan',
    ];

    protected function casts(): array
    {
        return [
            'harga' => 'decimal:2',
            'estimasi_durasi' => 'integer',
            'persentase_platform' => 'decimal:2',
        ];
    }

    public function detailPesanan(): HasMany
    {
        return $this->hasMany(DetailPesanan::class, 'id_layanan', 'id_layanan');
    }
}
