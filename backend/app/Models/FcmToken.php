<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FcmToken extends Model
{
    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'fcm_token';

    protected $primaryKey = 'id_fcm';

    protected $fillable = ['id_pengguna', 'token'];

    public function pengguna(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pengguna', 'id_pengguna');
    }
}
