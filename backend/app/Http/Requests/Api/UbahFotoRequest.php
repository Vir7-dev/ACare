<?php

namespace App\Http\Requests\Api;

class UbahFotoRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'foto' => ['required', 'file', 'mimes:jpg,jpeg,png', 'max:2048'],
        ];
    }
}
