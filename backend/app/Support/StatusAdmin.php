<?php

namespace App\Support;

/**
 * Penyimpanan sementara perubahan Admin di session Laravel.
 *
 * Data contoh di controller tetap menjadi data dasar; perubahan status
 * ditumpuk di atasnya agar angka di Beranda, sidebar, dan tab ikut berubah.
 * Saat database tersedia, kelas ini diganti dengan model/repositori.
 */
class StatusAdmin
{
    private const KUNCI = 'admin_status';

    /**
     * @return array<string, mixed>|null
     */
    public static function ambil(string $kelompok, ?string $kunci = null): mixed
    {
        $data = session(self::KUNCI.'.'.$kelompok, []);

        return $kunci === null ? $data : ($data[$kunci] ?? null);
    }

    public static function simpan(string $kelompok, string $kunci, mixed $nilai): void
    {
        session([self::KUNCI.'.'.$kelompok.'.'.str_replace('.', '_', $kunci) => $nilai]);
    }

    public static function simpanSemua(string $kelompok, mixed $nilai): void
    {
        session([self::KUNCI.'.'.$kelompok => $nilai]);
    }
}
