<?php

namespace App\Support;

/**
 * Menyeragamkan nomor telepon Indonesia ke format 08xxxxxxxxxx, supaya
 * "+62 812-3456-7890", "62812..." dan "0812..." dianggap nomor yang sama.
 */
class NomorTelepon
{
    public static function normalkan(?string $nomor): ?string
    {
        if ($nomor === null) {
            return null;
        }

        $angka = preg_replace('/\D+/', '', $nomor) ?? '';

        if (str_starts_with($angka, '62')) {
            $angka = '0'.substr($angka, 2);
        } elseif (str_starts_with($angka, '8')) {
            $angka = '0'.$angka;
        }

        return $angka;
    }

    /** Pola nomor yang diterima setelah dinormalkan: 0 lalu 8-14 digit. */
    public const POLA = '/^0[0-9]{8,14}$/';
}
