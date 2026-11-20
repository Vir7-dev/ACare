<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * Akun ACare untuk semua peran (pelanggan, teknisi, admin).
 * Login memakai email atau nomor telepon. Aplikasi mobile memakai token
 * Sanctum (tabel personal_access_tokens).
 */
class Pengguna extends Authenticatable
{
    use HasApiTokens, Notifiable;

    public const ROLE_PELANGGAN = 'pelanggan';

    public const ROLE_TEKNISI = 'teknisi';

    public const ROLE_ADMIN = 'admin';

    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = null;

    protected $table = 'pengguna';

    protected $primaryKey = 'id_pengguna';

    protected $fillable = [
        'nama', 'email', 'no_telepon', 'kata_sandi', 'role', 'foto_profil', 'status_akun',
    ];

    protected $hidden = ['kata_sandi'];

    protected function casts(): array
    {
        return [
            'kata_sandi' => 'hashed',
            'dibuat_pada' => 'datetime',
        ];
    }

    public function getAuthPassword(): string
    {
        return $this->kata_sandi;
    }

    public function getAuthPasswordName(): string
    {
        return 'kata_sandi';
    }

    /** Tabel pengguna tidak memakai fitur "ingat saya". */
    public function getRememberTokenName(): string
    {
        return '';
    }

    public function teknisi(): HasOne
    {
        return $this->hasOne(Teknisi::class, 'id_pengguna', 'id_pengguna');
    }

    public function lokasi(): HasMany
    {
        return $this->hasMany(Lokasi::class, 'id_pengguna', 'id_pengguna');
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'id_pelanggan', 'id_pengguna');
    }

    public function notifikasi(): HasMany
    {
        return $this->hasMany(Notifikasi::class, 'id_penerima', 'id_pengguna');
    }

    public function fcmToken(): HasMany
    {
        return $this->hasMany(FcmToken::class, 'id_pengguna', 'id_pengguna');
    }

    public function pengajuanDana(): HasMany
    {
        return $this->hasMany(PengajuanDana::class, 'id_pemohon', 'id_pengguna');
    }

    public function isAktif(): bool
    {
        return $this->status_akun === 'aktif';
    }
}
