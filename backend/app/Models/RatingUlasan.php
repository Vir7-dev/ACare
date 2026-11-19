<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RatingUlasan extends Model
{
    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'rating_ulasan';

    protected $primaryKey = 'id_rating';

    protected $fillable = ['id_pesanan', 'rating', 'ulasan', 'tag', 'ditampilkan'];

    protected function casts(): array
    {
        return [
            'rating' => 'integer',
            'tag' => 'array',
            'ditampilkan' => 'boolean',
        ];
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }
}
