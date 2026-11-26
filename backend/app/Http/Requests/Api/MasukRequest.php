<?php

namespace App\Http\Requests\Api;

use App\Models\Pengguna;
use App\Support\NomorTelepon;

class MasukRequest extends ApiRequest
{
    public function rules(): array
    {
        return [
            'identitas' => ['required', 'string', 'max:150'],
            'kata_sandi' => ['required', 'string'],
            'peran' => ['required', 'in:'.Pengguna::ROLE_PELANGGAN.','.Pengguna::ROLE_TEKNISI],
            'nama_perangkat' => ['nullable', 'string', 'max:100'],
        ];
    }

    /** Kolom yang dicocokkan: email (huruf kecil) atau nomor telepon. */
    public function kolomIdentitas(): string
    {
        return str_contains((string) $this->input('identitas'), '@') ? 'email' : 'no_telepon';
    }

    /** Nilai identitas yang sudah diseragamkan. */
    public function nilaiIdentitas(): string
    {
        $mentah = trim((string) $this->input('identitas'));

        return $this->kolomIdentitas() === 'email'
            ? strtolower($mentah)
            : (string) NomorTelepon::normalkan($mentah);
    }
}
