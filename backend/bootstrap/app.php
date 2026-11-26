<?php

use App\Http\Middleware\AdminAuth;
use App\Http\Middleware\CekPeran;
use App\Http\Middleware\PastikanAkunAktif;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'akun.aktif' => PastikanAkunAktif::class,
            'peran' => CekPeran::class,
            'admin.auth' => AdminAuth::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        // Pesan galat umum API dalam bahasa Indonesia, siap tampil di aplikasi.
        $exceptions->render(fn (AuthenticationException $e, Request $request) => $request->is('api/*')
            ? response()->json(['message' => 'Sesi kamu sudah berakhir. Silakan masuk lagi.', 'kode' => 'tidak_masuk'], 401)
            : null);
        $exceptions->render(fn (NotFoundHttpException $e, Request $request) => $request->is('api/*')
            ? response()->json(['message' => 'Data tidak ditemukan.', 'kode' => 'tidak_ditemukan'], 404)
            : null);
        $exceptions->render(fn (ThrottleRequestsException $e, Request $request) => $request->is('api/*')
            ? response()->json(['message' => 'Terlalu banyak permintaan. Coba lagi sebentar lagi.', 'kode' => 'terlalu_banyak_permintaan'], 429, $e->getHeaders())
            : null);
    })->create();
