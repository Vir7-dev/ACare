<?php

namespace App\Http\Middleware;

use App\Models\Pengguna;
use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

/**
 * Akun yang diblokir Admin saat masih login langsung dikeluarkan:
 * token perangkat ini dihapus dan permintaan ditolak.
 */
class PastikanAkunAktif
{
    public function handle(Request $request, Closure $next): Response
    {
        $pengguna = $request->user();

        if ($pengguna instanceof Pengguna && ! $pengguna->isAktif()) {
            $token = $pengguna->currentAccessToken();
            if ($token instanceof PersonalAccessToken) {
                $token->delete();
            }

            return response()->json([
                'message' => 'Akun kamu diblokir. Hubungi Pusat Bantuan ACare.',
                'kode' => 'akun_diblokir',
            ], 403);
        }

        return $next($request);
    }
}
