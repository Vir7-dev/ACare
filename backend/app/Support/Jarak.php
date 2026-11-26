<?php

namespace App\Support;

/** Jarak dan perkiraan waktu tempuh antar titik koordinat. */
class Jarak
{
    /** Kecepatan rata-rata motor di dalam kota untuk perkiraan waktu (km/jam). */
    public const KECEPATAN_KMJ = 25;

    /** Jarak lurus (haversine) dalam kilometer. */
    public static function km(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return 2 * $r * asin(min(1, sqrt($a)));
    }

    /** Perkiraan menit tempuh, minimal 1 menit. */
    public static function menit(float $km): int
    {
        return max(1, (int) ceil($km / self::KECEPATAN_KMJ * 60));
    }
}
