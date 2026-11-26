<?php

namespace App\Http\Requests\Api;

class SimpanAlamatRequest extends ApiRequest
{
    protected function prepareForValidation(): void
    {
        $this->merge([
            'label' => trim((string) $this->input('label')),
            'alamat_lengkap' => trim((string) $this->input('alamat_lengkap')),
        ]);
    }

    public function rules(): array
    {
        return [
            'label' => ['required', 'string', 'max:50'],
            'alamat_lengkap' => ['required', 'string', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ];
    }

    public function attributes(): array
    {
        return [
            ...parent::attributes(),
            'label' => 'label alamat',
            'alamat_lengkap' => 'alamat lengkap',
            'latitude' => 'titik lokasi',
            'longitude' => 'titik lokasi',
        ];
    }
}
