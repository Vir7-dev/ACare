<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FcmToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Token FCM perangkat untuk notifikasi push. Satu token hanya milik satu
 * akun: bila akun lain masuk di HP yang sama, token pindah ke akun itu.
 */
class PerangkatController extends Controller
{
    private const ATURAN = ['token' => ['required', 'string', 'max:512']];

    private const PESAN = ['required' => 'Token perangkat wajib diisi.', 'max' => 'Token perangkat terlalu panjang.'];

    public function simpan(Request $request): JsonResponse
    {
        $data = $request->validate(self::ATURAN, self::PESAN);

        FcmToken::query()->updateOrCreate(
            ['token' => $data['token']],
            ['id_pengguna' => $request->user()->id_pengguna],
        );

        return response()->json(['message' => 'Perangkat terdaftar untuk notifikasi.']);
    }

    public function hapus(Request $request): JsonResponse
    {
        $data = $request->validate(self::ATURAN, self::PESAN);

        FcmToken::query()
            ->where('token', $data['token'])
            ->where('id_pengguna', $request->user()->id_pengguna)
            ->delete();

        return response()->json(['message' => 'Notifikasi untuk perangkat ini dimatikan.']);
    }
}
