<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Dasar request API mobile: pesan validasi berbahasa Indonesia supaya bisa
 * langsung ditampilkan di bawah kolom form aplikasi.
 */
abstract class ApiRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function messages(): array
    {
        return [
            'required' => ':Attribute wajib diisi.',
            'string' => ':Attribute harus berupa teks.',
            'email' => 'Format :attribute tidak valid.',
            'unique' => ':Attribute sudah terdaftar.',
            'min' => [
                'string' => ':Attribute minimal :min karakter.',
                'numeric' => ':Attribute minimal :min.',
            ],
            'max' => [
                'string' => ':Attribute maksimal :max karakter.',
                'numeric' => ':Attribute maksimal :max.',
                'file' => 'Ukuran :attribute maksimal :max KB.',
                'array' => ':Attribute maksimal :max pilihan.',
            ],
            'between' => ['numeric' => ':Attribute tidak valid.'],
            'exists' => ':Attribute tidak ditemukan.',
            'integer' => ':Attribute harus berupa angka.',
            'numeric' => ':Attribute harus berupa angka.',
            'date' => ':Attribute tidak valid.',
            'boolean' => ':Attribute tidak valid.',
            'in' => ':Attribute tidak valid.',
            'regex' => 'Format :attribute tidak valid.',
            'confirmed' => 'Konfirmasi :attribute tidak sama.',
            'different' => ':Attribute harus berbeda dari kata sandi lama.',
            'file' => ':Attribute harus berupa berkas.',
            'image' => ':Attribute harus berupa foto.',
            'mimes' => ':Attribute harus berformat :values.',
            'array' => ':Attribute tidak valid.',
        ];
    }

    public function attributes(): array
    {
        return [
            'nama' => 'nama',
            'email' => 'email',
            'no_telepon' => 'nomor telepon',
            'kata_sandi' => 'kata sandi',
            'identitas' => 'email atau nomor telepon',
            'peran' => 'peran',
            'jenis_kendaraan' => 'jenis kendaraan',
            'plat_nomor' => 'plat nomor',
            'deskripsi' => 'tentang saya',
            'nama_bank' => 'bank',
            'no_rekening' => 'nomor rekening',
            'atas_nama' => 'nama pemilik rekening',
            'dokumen.cv' => 'CV',
            'dokumen.lamaran_kerja' => 'lamaran kerja',
            'dokumen.ktp' => 'KTP',
            'dokumen.ijazah' => 'ijazah',
            'dokumen.pas_foto' => 'pas foto',
            'kata_sandi_lama' => 'kata sandi lama',
            'kata_sandi_baru' => 'kata sandi baru',
            'foto' => 'foto profil',
        ];
    }
}
