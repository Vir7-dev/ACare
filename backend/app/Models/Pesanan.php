<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Pesanan extends Model
{
    public const MENCARI_TEKNISI = 'mencari_teknisi';

    public const MENUJU_LOKASI = 'menuju_lokasi';

    public const TIBA = 'tiba';

    public const PENGECEKAN_AWAL = 'pengecekan_awal';

    public const MENUNGGU_PERSETUJUAN_BIAYA = 'menunggu_persetujuan_biaya';

    public const DIKERJAKAN = 'dikerjakan';

    public const MENUNGGU_PEMBAYARAN = 'menunggu_pembayaran';

    public const SELESAI = 'selesai';

    public const DIBATALKAN = 'dibatalkan';

    // Hasil persetujuan biaya perbaikan (kolom status_biaya).
    public const BIAYA_MENUNGGU = 'menunggu';

    public const BIAYA_DISETUJUI = 'disetujui';

    public const BIAYA_DITOLAK = 'ditolak';

    /**
     * Status yang ditampilkan ke pelanggan. Beberapa status database
     * digabung supaya garis waktu di aplikasi tetap ringkas.
     */
    public const LABEL_PELANGGAN = [
        self::MENCARI_TEKNISI => 'Mencari Teknisi',
        self::MENUJU_LOKASI => 'Teknisi Menuju Lokasi',
        self::TIBA => 'Teknisi Menuju Lokasi',
        self::PENGECEKAN_AWAL => 'Pengecekan',
        self::MENUNGGU_PERSETUJUAN_BIAYA => 'Pengecekan',
        self::DIKERJAKAN => 'Perbaikan',
        self::MENUNGGU_PEMBAYARAN => 'Menunggu Pembayaran',
        self::SELESAI => 'Selesai',
        self::DIBATALKAN => 'Dibatalkan',
    ];

    public const CREATED_AT = 'dibuat_pada';

    public const UPDATED_AT = 'diubah_pada';

    protected $table = 'pesanan';

    protected $primaryKey = 'id_pesanan';

    /** Nilai awal di model, sama dengan default kolom di database. */
    protected $attributes = [
        'status_pesanan' => self::MENCARI_TEKNISI,
        'total_biaya' => 0,
    ];

    protected $fillable = [
        'id_pelanggan', 'id_teknisi', 'id_lokasi', 'jadwal_service', 'jenis_ac', 'pk', 'merek',
        'catatan_pelanggan', 'catatan_biaya', 'catatan_pengerjaan', 'status_pesanan', 'total_biaya',
        'status_biaya', 'batas_tawaran', 'teknisi_menolak', 'batas_persetujuan_biaya',
        'biaya_ditanggapi_pada', 'alasan_pembatalan',
        'diterima_pada', 'tiba_pada', 'pengecekan_pada', 'dikerjakan_pada',
        'menunggu_pembayaran_pada', 'selesai_pada', 'dibatalkan_pada',
    ];

    protected function casts(): array
    {
        return [
            'jadwal_service' => 'datetime',
            'pk' => 'decimal:1',
            'total_biaya' => 'decimal:2',
            'batas_tawaran' => 'datetime',
            'teknisi_menolak' => 'array',
            'batas_persetujuan_biaya' => 'datetime',
            'biaya_ditanggapi_pada' => 'datetime',
            'diterima_pada' => 'datetime',
            'tiba_pada' => 'datetime',
            'pengecekan_pada' => 'datetime',
            'dikerjakan_pada' => 'datetime',
            'menunggu_pembayaran_pada' => 'datetime',
            'selesai_pada' => 'datetime',
            'dibatalkan_pada' => 'datetime',
        ];
    }

    /** Kode pesanan untuk ditampilkan, misal AC-000123. */
    public function getKodeAttribute(): string
    {
        return 'AC-'.str_pad((string) $this->id_pesanan, 6, '0', STR_PAD_LEFT);
    }

    public function getLabelStatusPelangganAttribute(): string
    {
        return self::LABEL_PELANGGAN[$this->status_pesanan] ?? $this->status_pesanan;
    }

    /** Pelanggan hanya boleh membatalkan selama teknisi belum ditemukan. */
    public function bisaDibatalkan(): bool
    {
        return $this->status_pesanan === self::MENCARI_TEKNISI;
    }

    /**
     * Baris biaya yang benar-benar ditagih: layanan selalu, item biaya
     * teknisi hanya bila disetujui pelanggan. Item yang ditolak tetap
     * tersimpan sebagai riwayat.
     */
    public function detailDitagih(): HasMany
    {
        $query = $this->detail();
        if ($this->status_biaya !== self::BIAYA_DISETUJUI) {
            $query->where('jenis_item', DetailPesanan::JENIS_LAYANAN);
        }

        return $query;
    }

    public function hitungTotalBiaya(): float
    {
        return (float) $this->detailDitagih()->get()->sum->subtotal;
    }

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'id_pelanggan', 'id_pengguna');
    }

    public function teknisi(): BelongsTo
    {
        return $this->belongsTo(Teknisi::class, 'id_teknisi', 'id_pengguna');
    }

    public function lokasi(): BelongsTo
    {
        return $this->belongsTo(Lokasi::class, 'id_lokasi', 'id_lokasi');
    }

    public function detail(): HasMany
    {
        return $this->hasMany(DetailPesanan::class, 'id_pesanan', 'id_pesanan');
    }

    public function pembayaran(): HasMany
    {
        return $this->hasMany(Pembayaran::class, 'id_pesanan', 'id_pesanan');
    }

    public function fotoBukti(): HasMany
    {
        return $this->hasMany(FotoBuktiPengerjaan::class, 'id_pesanan', 'id_pesanan');
    }

    public function pesan(): HasMany
    {
        return $this->hasMany(Pesan::class, 'id_pesanan', 'id_pesanan');
    }

    public function ratingUlasan(): HasOne
    {
        return $this->hasOne(RatingUlasan::class, 'id_pesanan', 'id_pesanan');
    }

    public function pendapatan(): HasOne
    {
        return $this->hasOne(Pendapatan::class, 'id_pesanan', 'id_pesanan');
    }
}
