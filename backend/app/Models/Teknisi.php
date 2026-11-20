<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Teknisi extends Model
{
    protected $table = 'teknisi';

    protected $primaryKey = 'id_pengguna';

    public $incrementing = false;

    public $timestamps = false;

    protected $fillable = [
        'id_pengguna', 'pengalaman', 'deskripsi', 'kendaraan', 'nama_bank', 'no_rekening',
        'atas_nama', 'status_verifikasi', 'alasan_penolakan', 'diverifikasi_oleh', 'diverifikasi_pada',
        'status_ketersediaan', 'latitude', 'longitude', 'lokasi_diperbarui_pada',
    ];

    protected function casts(): array
    {
        return [
            'pengalaman' => 'integer',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'lokasi_diperbarui_pada' => 'datetime',
            'diverifikasi_pada' => 'datetime',
        ];
    }

    public function pengguna(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pengguna', 'id_pengguna');
    }

    public function dokumen(): HasMany
    {
        return $this->hasMany(DokumenVerifikasi::class, 'id_teknisi', 'id_pengguna');
    }

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'id_teknisi', 'id_pengguna');
    }

    public function pendapatan(): HasMany
    {
        return $this->hasMany(Pendapatan::class, 'id_teknisi', 'id_pengguna');
    }

    /** Admin yang memverifikasi atau menolak pendaftaran. */
    public function verifikator(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'diverifikasi_oleh', 'id_pengguna');
    }

    public function isTerverifikasi(): bool
    {
        return $this->status_verifikasi === 'terverifikasi';
    }

    /**
     * Saldo yang bisa dicairkan: total pendapatan dikurangi pencairan yang
     * sedang diajukan atau sudah ditransfer (yang ditolak tidak dihitung).
     */
    public function saldo(): float
    {
        $masuk = (float) $this->pendapatan()->sum('pendapatan_teknisi');
        $keluar = (float) PengajuanDana::query()
            ->where('jenis', 'pencairan')
            ->where('id_pemohon', $this->id_pengguna)
            ->where('status', '!=', 'ditolak')
            ->sum('nominal');

        return $masuk - $keluar;
    }
}
