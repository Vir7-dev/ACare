<?php

namespace App\Http\Requests\Api;

use App\Models\DokumenVerifikasi;

class DaftarTeknisiRequest extends DaftarPelangganRequest
{
    /** Pola plat nomor Indonesia, misal "BP 1234 AC". */
    public const POLA_PLAT = '/^[A-Z]{1,2}\s?\d{1,4}\s?[A-Z]{0,3}$/';

    protected function prepareForValidation(): void
    {
        parent::prepareForValidation();
        $this->merge([
            'plat_nomor' => strtoupper(trim((string) $this->input('plat_nomor'))),
            'no_rekening' => preg_replace('/\D+/', '', (string) $this->input('no_rekening')),
        ]);
    }

    public function rules(): array
    {
        $aturanDokumen = ['required', 'file', 'mimes:jpg,jpeg,png', 'max:5120'];

        return [
            ...parent::rules(),
            'jenis_kendaraan' => ['required', 'string', 'max:50'],
            'plat_nomor' => ['required', 'string', 'max:15', 'regex:'.self::POLA_PLAT],
            'nama_bank' => ['required', 'string', 'max:50'],
            'no_rekening' => ['required', 'regex:/^[0-9]{5,30}$/'],
            'atas_nama' => ['required', 'string', 'max:100'],
            'dokumen' => ['required', 'array'],
            ...collect(DokumenVerifikasi::JENIS_WAJIB)
                ->mapWithKeys(fn (string $jenis) => ["dokumen.$jenis" => $aturanDokumen])
                ->all(),
        ];
    }
}
