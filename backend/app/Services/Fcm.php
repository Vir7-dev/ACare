<?php

namespace App\Services;

use App\Models\FcmToken;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Kirim notifikasi push lewat Firebase Cloud Messaging HTTP v1.
 *
 * Token akses Google dibuat dari file service account (JWT RS256) dan
 * disimpan di cache sampai hampir kedaluwarsa. Token perangkat yang
 * ditolak FCM (aplikasi dihapus, token kedaluwarsa) langsung dihapus.
 */
class Fcm
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    private const KUNCI_CACHE = 'fcm-token-akses';

    /** Kanal notifikasi Android (harus sama dengan aplikasi mobile). */
    public const KANAL_ANDROID = 'acare_pesanan';

    /** File service account terbaca. */
    public function aktif(): bool
    {
        return $this->akun() !== null;
    }

    /**
     * Kirim ke semua perangkat milik pengguna. Mengembalikan jumlah
     * perangkat yang berhasil dikirimi.
     *
     * @param  array<string, string|int>  $data
     */
    public function kirimKePengguna(int $idPengguna, string $judul, string $isi, array $data = []): int
    {
        if (! $this->aktif()) {
            return 0;
        }

        $berhasil = 0;
        foreach (FcmToken::query()->where('id_pengguna', $idPengguna)->pluck('token') as $token) {
            $berhasil += (int) $this->kirim($token, $judul, $isi, $data);
        }

        return $berhasil;
    }

    /** @param  array<string, string|int>  $data */
    public function kirim(string $token, string $judul, string $isi, array $data = []): bool
    {
        $akun = $this->akun();
        $akses = $akun ? $this->tokenAkses($akun) : null;
        if (! $akses) {
            return false;
        }

        $proyek = config('services.firebase.project_id') ?: $akun['project_id'];

        try {
            $res = Http::withToken($akses)->acceptJson()->timeout(10)
                ->post("https://fcm.googleapis.com/v1/projects/{$proyek}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => ['title' => $judul, 'body' => $isi],
                        // Nilai data FCM wajib berupa teks.
                        'data' => array_map('strval', $data),
                        'android' => [
                            'priority' => 'HIGH',
                            'notification' => ['channel_id' => self::KANAL_ANDROID, 'sound' => 'default'],
                        ],
                    ],
                ]);
        } catch (ConnectionException $e) {
            Log::warning('FCM tidak bisa dihubungi', ['galat' => $e->getMessage()]);

            return false;
        }

        if ($res->successful()) {
            return true;
        }

        $status = $res->json('error.status');
        $kode = collect($res->json('error.details', []))->pluck('errorCode')->filter()->first();
        if ($res->status() === 404 || $kode === 'UNREGISTERED' || ($status === 'INVALID_ARGUMENT' && $kode === 'INVALID_ARGUMENT')) {
            // Perangkat tidak terdaftar lagi: jangan dikirimi lagi.
            FcmToken::query()->where('token', $token)->delete();
        } elseif ($res->status() === 401) {
            Cache::forget(self::KUNCI_CACHE);
        }
        Log::warning('FCM menolak notifikasi', ['status' => $res->status(), 'kode' => $kode ?? $status]);

        return false;
    }

    /** @return array{client_email: string, private_key: string, token_uri?: string, project_id: string}|null */
    private function akun(): ?array
    {
        $path = config('services.firebase.credentials');
        if (! $path) {
            return null;
        }
        $path = preg_match('/^([A-Za-z]:[\\\\\/]|\/)/', $path) ? $path : base_path($path);
        if (! is_readable($path)) {
            return null;
        }

        $akun = json_decode((string) file_get_contents($path), true);

        return is_array($akun) && isset($akun['client_email'], $akun['private_key'], $akun['project_id']) ? $akun : null;
    }

    private function tokenAkses(array $akun): ?string
    {
        if ($token = Cache::get(self::KUNCI_CACHE)) {
            return $token;
        }

        $uri = $akun['token_uri'] ?? 'https://oauth2.googleapis.com/token';
        $sekarang = time();
        $b64 = fn (string $s) => rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
        $tanpaTtd = $b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])).'.'.$b64(json_encode([
            'iss' => $akun['client_email'],
            'scope' => self::SCOPE,
            'aud' => $uri,
            'iat' => $sekarang,
            'exp' => $sekarang + 3600,
        ]));

        if (! openssl_sign($tanpaTtd, $ttd, $akun['private_key'], OPENSSL_ALGO_SHA256)) {
            Log::error('FCM: kunci service account tidak bisa dipakai');

            return null;
        }

        try {
            $res = Http::asForm()->timeout(10)->post($uri, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $tanpaTtd.'.'.$b64($ttd),
            ]);
        } catch (ConnectionException $e) {
            Log::warning('Google OAuth tidak bisa dihubungi', ['galat' => $e->getMessage()]);

            return null;
        }

        $token = $res->json('access_token');
        if (! $res->successful() || ! $token) {
            Log::error('FCM: token akses ditolak Google', ['status' => $res->status(), 'galat' => $res->json('error')]);

            return null;
        }

        Cache::put(self::KUNCI_CACHE, $token, max(60, (int) $res->json('expires_in', 3600) - 300));

        return $token;
    }
}
