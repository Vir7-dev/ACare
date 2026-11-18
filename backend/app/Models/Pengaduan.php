<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pengaduan extends Model
{
    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = 'diubah_pada';

    protected $table = 'pengaduan';

    protected $primaryKey = 'id_pengaduan';

    protected $fillable = [
        'id_pelapor', 'id_pesanan', 'id_admin', 'jenis_pengaduan', 'deskripsi', 'bukti',
        'status_pengaduan', 'tanggapan_admin', 'selesai_pada',
    ];

    protected function casts(): array
    {
        return [
            'bukti' => 'array',
            'selesai_pada' => 'datetime',
        ];
    }

    public function pelapor(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pelapor', 'id_pengguna');
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'id_pesanan', 'id_pesanan');
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_admin', 'id_pengguna');
    }

    /** Tanpa pesanan berarti aduan jalur "Sistem & Aplikasi". */
    public function isAduanSistem(): bool
    {
        return $this->id_pesanan === null;
    }

    /**
     * Pihak yang dilaporkan: teknisi bila pelapor pelanggan, pelanggan bila
     * pelapor teknisi, dan null untuk aduan sistem.
     */
    public function terlapor(): ?Pengguna
    {
        if ($this->isAduanSistem()) {
            return null;
        }

        $pesanan = $this->pesanan;

        return $this->id_pelapor === $pesanan->id_pelanggan
            ? $pesanan->teknisi?->pengguna
            : $pesanan->pelanggan;
    }
}
