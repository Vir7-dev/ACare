<?php

namespace App\Http\Requests\Api;

use App\Support\NomorTelepon;
use Illuminate\Validation\Rule;

class DaftarPelangganRequest extends ApiRequest
{
    protected function prepareForValidation(): void
    {
        $this->merge([
            'nama' => trim((string) $this->input('nama')),
            'email' => strtolower(trim((string) $this->input('email'))),
            'no_telepon' => NomorTelepon::normalkan($this->input('no_telepon')),
        ]);
    }

    public function rules(): array
    {
        return [
            'nama' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:150', Rule::unique('pengguna', 'email')],
            'no_telepon' => ['required', 'regex:'.NomorTelepon::POLA, Rule::unique('pengguna', 'no_telepon')],
            'kata_sandi' => ['required', 'string', 'min:8', 'max:100'],
        ];
    }
}
