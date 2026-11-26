<?php

namespace App\Http\Resources;

use App\Models\Pengguna;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Data akun yang dikirim ke aplikasi mobile.
 *
 * @mixin Pengguna
 */
class PenggunaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $teknisi = $this->role === Pengguna::ROLE_TEKNISI ? $this->teknisi : null;

        return [
            'id' => $this->id_pengguna,
            'nama' => $this->nama,
            'email' => $this->email,
            'no_telepon' => $this->no_telepon,
            'role' => $this->role,
            // URL mengikuti alamat yang dipakai aplikasi (misal 10.0.2.2 dari
            // emulator), bukan APP_URL yang bisa berisi "localhost".
            // TODO: ganti ke Storage::url() bila foto pindah ke cloud storage.
            'foto_profil' => $this->foto_profil
                ? asset('storage/'.$this->foto_profil)
                : null,
            'status_akun' => $this->status_akun,
            'teknisi' => $this->when($teknisi !== null, fn () => [
                'status_verifikasi' => $teknisi->status_verifikasi,
                'alasan_penolakan' => $teknisi->alasan_penolakan,
                'jenis_kendaraan' => $teknisi->jenis_kendaraan,
                'plat_nomor' => $teknisi->plat_nomor,
                'deskripsi' => $teknisi->deskripsi,
                'nama_bank' => $teknisi->nama_bank,
                'no_rekening' => $teknisi->no_rekening,
                'atas_nama' => $teknisi->atas_nama,
                'status_ketersediaan' => $teknisi->status_ketersediaan,
            ]),
        ];
    }
}
