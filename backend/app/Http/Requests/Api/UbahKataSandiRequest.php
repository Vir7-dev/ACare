<?php

namespace App\Http\Requests\Api;

class UbahKataSandiRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'kata_sandi_lama' => ['required', 'string'],
            'kata_sandi_baru' => ['required', 'string', 'min:8', 'max:100', 'confirmed', 'different:kata_sandi_lama'],
        ];
    }
}
