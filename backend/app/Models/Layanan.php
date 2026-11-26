<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Layanan extends Model
{
    public const SERVICE_AC = 'Service AC';

    public const ISI_FREON = 'Isi Freon';

    public const BONGKAR_PASANG = 'Bongkar Pasang';

    public const CEK_AC = 'Cek AC';

    /**
     * Layanan yang biayanya belum termasuk komponen: setelah pengecekan
     * teknisi boleh mengajukan biaya perbaikan.
     */
    public const BERBIAYA_TAMBAHAN = [self::SERVICE_AC, self::CEK_AC];

    /** Isian khusus per layanan (kolom pesanan.detail_layanan). */
    public const JENIS_FREON = ['R32', 'R410A', 'R22'];

    public const JENIS_PEKERJAAN = ['pasangBaru', 'pindah', 'bongkar'];

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

    public function isAktif(): bool
    {
        return $this->status_layanan === 'aktif';
    }

    public function bisaBiayaTambahan(): bool
    {
        return in_array($this->nama_layanan, self::BERBIAYA_TAMBAHAN, true);
    }

    public function detailPesanan(): HasMany
    {
        return $this->hasMany(DetailPesanan::class, 'id_layanan', 'id_layanan');
    }
}
