<?php

namespace App\Http\Requests\Api;

use App\Support\NomorTelepon;
use Illuminate\Validation\Rule;

/**
 * Ubah profil sebagian: kolom yang tidak dikirim tidak diubah. Kolom
 * kendaraan dan "tentang saya" hanya berlaku untuk teknisi.
 */
class UbahProfilRequest extends ApiRequest
{
    protected function prepareForValidation(): void
    {
        $ubah = [];
        if ($this->has('nama')) {
            $ubah['nama'] = trim((string) $this->input('nama'));
        }
        if ($this->has('email')) {
            $ubah['email'] = strtolower(trim((string) $this->input('email')));
        }
        if ($this->has('no_telepon')) {
            $ubah['no_telepon'] = NomorTelepon::normalkan($this->input('no_telepon'));
        }
        if ($this->has('plat_nomor')) {
            $ubah['plat_nomor'] = strtoupper(trim((string) $this->input('plat_nomor')));
        }
        $this->merge($ubah);
    }

    public function rules(): array
    {
        $id = $this->user()->id_pengguna;

        return [
            'nama' => ['sometimes', 'required', 'string', 'max:100'],
            'email' => ['sometimes', 'required', 'email', 'max:150',
                Rule::unique('pengguna', 'email')->ignore($id, 'id_pengguna')],
            'no_telepon' => ['sometimes', 'required', 'regex:'.NomorTelepon::POLA,
                Rule::unique('pengguna', 'no_telepon')->ignore($id, 'id_pengguna')],
            'jenis_kendaraan' => ['sometimes', 'required', 'string', 'max:50'],
            'plat_nomor' => ['sometimes', 'required', 'string', 'max:15', 'regex:'.DaftarTeknisiRequest::POLA_PLAT],
            'deskripsi' => ['sometimes', 'nullable', 'string', 'max:300'],
        ];
    }
}
