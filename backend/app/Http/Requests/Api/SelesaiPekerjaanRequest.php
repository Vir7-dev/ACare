<?php

namespace App\Http\Requests\Api;

class SelesaiPekerjaanRequest extends ApiRequest
{
    public function rules(): array
    {
        $foto = ['file', 'mimes:jpg,jpeg,png', 'max:5120'];

        return [
            'foto_sebelum' => ['required', ...$foto],
            'foto_sesudah' => ['required', ...$foto],
            'foto_tambahan' => ['nullable', 'array', 'max:3'],
            'foto_tambahan.*' => $foto,
            'catatan' => ['required', 'string', 'max:500'],
        ];
    }

    public function attributes(): array
    {
        return [
            ...parent::attributes(),
            'foto_sebelum' => 'foto sebelum',
            'foto_sesudah' => 'foto sesudah',
            'foto_tambahan' => 'foto tambahan',
            'foto_tambahan.*' => 'foto tambahan',
            'catatan' => 'catatan pengerjaan',
        ];
    }
}
