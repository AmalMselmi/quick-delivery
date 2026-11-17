<?php

namespace App\Services;

use App\Models\Restaurant;

class DeliveryFee
{
    public const BASE = 2.00;
    public const PER_KM = 0.50;
    public const MAX = 15.00;
    public const FLAT = 3.00;

    public static function distanceKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        return 2 * $earthRadius * asin(sqrt($a));
    }

    public static function calculate(?Restaurant $restaurant, ?float $lat, ?float $lng): float
    {
        if (
            !$restaurant
            || $restaurant->latitude === null
            || $restaurant->longitude === null
            || $lat === null
            || $lng === null
        ) {
            return self::FLAT;
        }

        $km = self::distanceKm(
            (float) $restaurant->latitude,
            (float) $restaurant->longitude,
            $lat,
            $lng
        );

        return round(min(self::MAX, self::BASE + self::PER_KM * $km), 2);
    }
}