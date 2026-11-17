<?php

namespace Database\Seeders;

use App\Models\Restaurant;
use Illuminate\Database\Seeder;

class RestaurantSeeder extends Seeder
{
    public function run(): void
    {
        $restaurants = [
            ['name' => 'Burger Palace', 'image' => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300', 'rating' => 4.5, 'cuisineType' => 'American', 'latitude' => 36.8065, 'longitude' => 10.1815],
            ['name' => 'Pizza Roma',    'image' => 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300', 'rating' => 4.2, 'cuisineType' => 'Italian',  'latitude' => 36.8190, 'longitude' => 10.1658],
            ['name' => 'Sushi Garden',  'image' => 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=300', 'rating' => 4.8, 'cuisineType' => 'Japanese', 'latitude' => 36.8420, 'longitude' => 10.2080],
            ['name' => 'Taco Fiesta',   'image' => 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=300', 'rating' => 4.1, 'cuisineType' => 'Mexican',  'latitude' => 36.7990, 'longitude' => 10.1800],
        ];

        foreach ($restaurants as $r) {
            Restaurant::create($r);
        }
    }
}