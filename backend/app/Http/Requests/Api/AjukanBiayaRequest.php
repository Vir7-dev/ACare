<?php

namespace App\Http\Requests\Api;

use App\Models\DetailPesanan;

class AjukanBiayaRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'item' => ['required', 'array', 'min:1', 'max:20'],
            'item.*.nama' => ['required', 'string', 'max:150'],
            'item.*.jenis' => ['required', 'in:'.DetailPesanan::JENIS_JASA.','.DetailPesanan::JENIS_SUKU_CADANG],
            'item.*.harga' => ['required', 'integer', 'min:1000', 'max:50000000'],
            'item.*.jumlah' => ['nullable', 'integer', 'min:1', 'max:20'],
            'catatan' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function attributes(): array
    {
        return [
            ...parent::attributes(),
            'item' => 'rincian biaya',
            'item.*.nama' => 'nama tindakan',
            'item.*.jenis' => 'jenis item',
            'item.*.harga' => 'nominal',
            'item.*.jumlah' => 'jumlah',
            'catatan' => 'catatan untuk pelanggan',
        ];
    }

    public function messages(): array
    {
        return [
            ...parent::messages(),
            'item.required' => 'Tambahkan minimal satu rincian biaya.',
            'item.min' => 'Tambahkan minimal satu rincian biaya.',
        ];
    }
}
