<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Batasi rute untuk peran tertentu, misal `peran:pelanggan`.
 */
class CekPeran
{
    public function handle(Request $request, Closure $next, string ...$peran): Response
    {
        if (! in_array($request->user()?->role, $peran, true)) {
            return response()->json([
                'message' => 'Fitur ini hanya untuk akun '.implode(' atau ', $peran).'.',
                'kode' => 'peran_tidak_sesuai',
            ], 403);
        }

        return $next($request);
    }
}
