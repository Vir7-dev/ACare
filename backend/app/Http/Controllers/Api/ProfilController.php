<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UbahFotoRequest;
use App\Http\Requests\Api\UbahKataSandiRequest;
use App\Http\Requests\Api\UbahProfilRequest;
use App\Http\Resources\PenggunaResource;
use App\Models\Pengguna;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

/** Akun milik pengguna yang sedang masuk. */
class ProfilController extends Controller
{
    public function tampil(Request $request): PenggunaResource
    {
        return new PenggunaResource($request->user()->load('teknisi'));
    }

    public function ubah(UbahProfilRequest $request): PenggunaResource
    {
        /** @var Pengguna $pengguna */
        $pengguna = $request->user();
        $data = $request->validated();

        DB::transaction(function () use ($pengguna, $data) {
            $pengguna->update(array_intersect_key($data, array_flip(['nama', 'email', 'no_telepon'])));

            if ($pengguna->role === Pengguna::ROLE_TEKNISI && $pengguna->teknisi) {
                $pengguna->teknisi->update(
                    array_intersect_key($data, array_flip(['jenis_kendaraan', 'plat_nomor', 'deskripsi', 'nama_bank', 'no_rekening', 'atas_nama'])),
                );
            }
        });

        return new PenggunaResource($pengguna->refresh()->load('teknisi'));
    }

    public function ubahFoto(UbahFotoRequest $request): PenggunaResource
    {
        /** @var Pengguna $pengguna */
        $pengguna = $request->user();
        $lama = $pengguna->foto_profil;
        $pengguna->update(['foto_profil' => $request->file('foto')->store('foto-profil', 'public')]);

        if ($lama) {
            Storage::disk('public')->delete($lama);
        }

        return new PenggunaResource($pengguna->load('teknisi'));
    }

    /**
     * Ganti kata sandi. Sesi di perangkat lain dikeluarkan; perangkat ini
     * tetap masuk.
     */
    public function ubahKataSandi(UbahKataSandiRequest $request): JsonResponse
    {
        /** @var Pengguna $pengguna */
        $pengguna = $request->user();

        if (! Hash::check($request->input('kata_sandi_lama'), $pengguna->kata_sandi)) {
            throw ValidationException::withMessages([
                'kata_sandi_lama' => 'Kata sandi lama tidak sesuai.',
            ]);
        }

        $pengguna->update(['kata_sandi' => $request->input('kata_sandi_baru')]);

        $tokenLain = $pengguna->tokens();
        $sekarang = $pengguna->currentAccessToken();
        if ($sekarang instanceof PersonalAccessToken) {
            $tokenLain->whereKeyNot($sekarang->getKey());
        }
        $tokenLain->delete();

        return response()->json(['message' => 'Kata sandi berhasil diubah.']);
    }
}
