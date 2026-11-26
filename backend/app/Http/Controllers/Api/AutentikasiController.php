<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\DaftarPelangganRequest;
use App\Http\Requests\Api\DaftarTeknisiRequest;
use App\Http\Requests\Api\MasukRequest;
use App\Http\Resources\PenggunaResource;
use App\Models\DokumenVerifikasi;
use App\Models\Pengguna;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\PersonalAccessToken;
use Throwable;

/**
 * Daftar, masuk, dan keluar untuk aplikasi mobile (pelanggan & teknisi).
 * Admin tidak masuk lewat sini; Admin memakai panel web.
 */
class AutentikasiController extends Controller
{
    /** Percobaan masuk yang salah sebelum dikunci sementara. */
    public const MAKS_PERCOBAAN = 5;

    /** Lama kunci setelah terlalu banyak percobaan (detik). */
    public const DETIK_KUNCI = 60;

    public function daftar(DaftarPelangganRequest $request): JsonResponse
    {
        $pengguna = Pengguna::create([
            ...$request->safe()->only(['nama', 'email', 'no_telepon', 'kata_sandi']),
            'role' => Pengguna::ROLE_PELANGGAN,
        ]);

        return response()->json([
            'message' => 'Pendaftaran berhasil, silakan masuk.',
            'pengguna' => new PenggunaResource($pengguna),
        ], 201);
    }

    /**
     * Registrasi teknisi beserta dokumen. Akun berstatus menunggu verifikasi
     * Admin, jadi belum diberi token.
     */
    public function daftarTeknisi(DaftarTeknisiRequest $request): JsonResponse
    {
        $tersimpan = [];

        try {
            $pengguna = DB::transaction(function () use ($request, &$tersimpan) {
                $pengguna = Pengguna::create([
                    ...$request->safe()->only(['nama', 'email', 'no_telepon', 'kata_sandi']),
                    'role' => Pengguna::ROLE_TEKNISI,
                ]);

                $teknisi = $pengguna->teknisi()->create([
                    ...$request->safe()->only([
                        'jenis_kendaraan', 'plat_nomor', 'nama_bank', 'no_rekening', 'atas_nama',
                    ]),
                    'status_verifikasi' => 'menunggu',
                ]);

                foreach (DokumenVerifikasi::JENIS_WAJIB as $jenis) {
                    $path = $request->file("dokumen.$jenis")->store(
                        'dokumen-teknisi/'.$pengguna->id_pengguna,
                        DokumenVerifikasi::DISK,
                    );
                    $tersimpan[] = $path;
                    $teknisi->dokumen()->create(['jenis_dokumen' => $jenis, 'path_file' => $path]);
                }

                return $pengguna;
            });
        } catch (Throwable $e) {
            // Berkas yang sempat tersimpan dihapus supaya tidak jadi sampah.
            Storage::disk(DokumenVerifikasi::DISK)->delete($tersimpan);
            throw $e;
        }

        return response()->json([
            'message' => 'Pendaftaran berhasil. Akun kamu menunggu verifikasi Admin.',
            'pengguna' => new PenggunaResource($pengguna->load('teknisi')),
        ], 201);
    }

    public function masuk(MasukRequest $request): JsonResponse
    {
        $kunci = 'masuk:'.$request->nilaiIdentitas().'|'.$request->ip();

        if (RateLimiter::tooManyAttempts($kunci, self::MAKS_PERCOBAAN)) {
            $detik = RateLimiter::availableIn($kunci);

            return $this->tolak(429, 'terlalu_banyak_percobaan',
                "Terlalu banyak percobaan masuk. Coba lagi dalam {$detik} detik.");
        }

        $pengguna = Pengguna::query()
            ->where($request->kolomIdentitas(), $request->nilaiIdentitas())
            ->first();

        if (! $pengguna || ! Hash::check($request->input('kata_sandi'), $pengguna->kata_sandi)) {
            RateLimiter::hit($kunci, self::DETIK_KUNCI);

            return $this->tolak(401, 'kredensial_salah',
                'Email/nomor telepon atau kata sandi salah.');
        }

        RateLimiter::clear($kunci);

        if ($pengguna->role === Pengguna::ROLE_ADMIN) {
            return $this->tolak(403, 'peran_tidak_sesuai',
                'Akun Admin hanya bisa masuk lewat panel web.');
        }

        if ($pengguna->role !== $request->input('peran')) {
            $label = ucfirst($pengguna->role);

            return $this->tolak(403, 'peran_tidak_sesuai',
                "Akun ini terdaftar sebagai {$label}. Pilih peran {$label} untuk masuk.");
        }

        if (! $pengguna->isAktif()) {
            return $this->tolak(403, 'akun_diblokir',
                'Akun kamu diblokir. Hubungi Pusat Bantuan ACare.');
        }

        if ($pengguna->role === Pengguna::ROLE_TEKNISI) {
            $teknisi = $pengguna->teknisi;

            if ($teknisi?->status_verifikasi === 'ditolak') {
                return $this->tolak(403, 'verifikasi_ditolak',
                    'Pendaftaran kamu ditolak Admin.', ['alasan' => $teknisi->alasan_penolakan]);
            }

            if (! $teknisi?->isTerverifikasi()) {
                return $this->tolak(403, 'belum_terverifikasi',
                    'Akun kamu belum diverifikasi oleh Admin. Kami akan mengirim notifikasi '
                    .'setelah dokumenmu selesai diperiksa.');
            }
        }

        $token = $pengguna->createToken($request->input('nama_perangkat') ?: 'aplikasi-mobile');

        return response()->json([
            'token' => $token->plainTextToken,
            'pengguna' => new PenggunaResource($pengguna),
        ]);
    }

    /** Keluar dari perangkat ini saja; perangkat lain tetap masuk. */
    public function keluar(Request $request): JsonResponse
    {
        $token = $request->user()->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        return response()->json(['message' => 'Kamu sudah keluar.']);
    }

    private function tolak(int $status, string $kode, string $pesan, array $tambahan = []): JsonResponse
    {
        return response()->json(['message' => $pesan, 'kode' => $kode, ...$tambahan], $status);
    }
}
