<?php

namespace App\Http\Requests\Api;

use App\Models\Layanan;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class BuatPesananRequest extends ApiRequest
{
    /** Jumlah unit AC maksimal dalam satu pesanan (sama dengan aplikasi). */
    public const MAKS_UNIT = 5;

    /** Pilihan kapasitas di aplikasi. */
    public const PILIHAN_PK = [0.5, 1, 1.5, 2];

    /** Jadwal paling jauh dari hari ini. */
    public const MAKS_HARI_JADWAL = 30;

    private ?Layanan $layanan = null;

    public function rules(): array
    {
        $idPengguna = $this->user()->id_pengguna;

        return [
            'id_layanan' => ['required', 'integer',
                Rule::exists('layanan', 'id_layanan')->where('status_layanan', 'aktif')],
            'jumlah_unit' => ['required', 'integer', 'min:1', 'max:'.self::MAKS_UNIT],
            'jenis_ac' => ['required', 'in:split,cassette,standing,window'],
            'pk' => ['required', 'numeric', Rule::in(self::PILIHAN_PK)],
            'merek' => ['nullable', 'string', 'max:50'],
            'id_lokasi' => ['required', 'integer',
                Rule::exists('lokasi', 'id_lokasi')
                    ->where('id_pengguna', $idPengguna)
                    ->whereNull('dihapus_pada')],
            'detail_lokasi' => ['nullable', 'string', 'max:150'],
            // Toleransi 10 menit untuk pesanan "sekarang" yang dikirim agak lambat.
            'jadwal_service' => ['required', 'date',
                'after_or_equal:'.now()->subMinutes(10)->toDateTimeString(),
                'before:'.now()->addDays(self::MAKS_HARI_JADWAL)->toDateTimeString()],
            'catatan' => ['nullable', 'string', 'max:500'],
            'detail_layanan' => ['nullable', 'array'],
            'detail_layanan.keluhan' => ['nullable', 'array', 'max:10'],
            'detail_layanan.keluhan.*' => ['string', 'max:100'],
            'detail_layanan.jenis_freon' => ['nullable', Rule::in(Layanan::JENIS_FREON)],
            'detail_layanan.jenis_pekerjaan' => ['nullable', Rule::in(Layanan::JENIS_PEKERJAAN)],
        ];
    }

    /** Isian wajib bergantung pada layanan yang dipilih. */
    public function after(): array
    {
        return [function (Validator $v) {
            $layanan = $this->layanan();
            if ($layanan === null) {
                return;
            }
            if ($layanan->nama_layanan === Layanan::ISI_FREON && ! $this->input('detail_layanan.jenis_freon')) {
                $v->errors()->add('detail_layanan.jenis_freon', 'Jenis freon wajib dipilih.');
            }
            if ($layanan->nama_layanan === Layanan::BONGKAR_PASANG && ! $this->input('detail_layanan.jenis_pekerjaan')) {
                $v->errors()->add('detail_layanan.jenis_pekerjaan', 'Jenis pekerjaan wajib dipilih.');
            }
        }];
    }

    public function layanan(): ?Layanan
    {
        return $this->layanan ??= Layanan::find($this->input('id_layanan'));
    }

    /** Hanya isian yang berlaku untuk layanan yang dipilih yang disimpan. */
    public function detailLayanan(): array
    {
        $isi = (array) $this->validated('detail_layanan', []);

        return array_filter(match ($this->layanan()?->nama_layanan) {
            Layanan::SERVICE_AC => ['keluhan' => array_values($isi['keluhan'] ?? [])],
            Layanan::ISI_FREON => ['jenis_freon' => $isi['jenis_freon'] ?? null],
            Layanan::BONGKAR_PASANG => ['jenis_pekerjaan' => $isi['jenis_pekerjaan'] ?? null],
            default => [],
        });
    }

    public function attributes(): array
    {
        return [
            ...parent::attributes(),
            'id_layanan' => 'layanan',
            'jumlah_unit' => 'jumlah unit',
            'jenis_ac' => 'jenis AC',
            'pk' => 'kapasitas PK',
            'merek' => 'merek AC',
            'id_lokasi' => 'alamat',
            'detail_lokasi' => 'detail lokasi',
            'jadwal_service' => 'jadwal servis',
            'catatan' => 'catatan',
        ];
    }

    public function messages(): array
    {
        return [
            ...parent::messages(),
            'jadwal_service.after_or_equal' => 'Jadwal servis tidak boleh di masa lalu.',
            'jadwal_service.before' => 'Jadwal servis paling lambat '.self::MAKS_HARI_JADWAL.' hari dari sekarang.',
        ];
    }
}
