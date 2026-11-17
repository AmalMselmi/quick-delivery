<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Menu;

class MenuSeeder extends Seeder
{
    public function run(): void
    {
        $items = [
            ['restaurantId' => 1, 'name' => 'Classic Burger',     'price' => 8.99,  'image' => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200', 'available' => true],
            ['restaurantId' => 1, 'name' => 'Cheese Burger',      'price' => 10.49, 'image' => 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=200', 'available' => true],
            ['restaurantId' => 1, 'name' => 'BBQ Burger',         'price' => 11.99, 'image' => 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=200', 'available' => false],
            ['restaurantId' => 2, 'name' => 'Margherita Pizza',   'price' => 12.99, 'image' => 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200', 'available' => true],
            ['restaurantId' => 2, 'name' => 'Pepperoni Pizza',    'price' => 14.99, 'image' => 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=200', 'available' => true],
            ['restaurantId' => 2, 'name' => 'Four Cheese Pizza',  'price' => 15.49, 'image' => 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200', 'available' => false],
            ['restaurantId' => 3, 'name' => 'Salmon Sushi Roll',  'price' => 13.99, 'image' => 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=200', 'available' => true],
            ['restaurantId' => 3, 'name' => 'Tuna Nigiri',        'price' => 11.99, 'image' => 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=200', 'available' => true],
            ['restaurantId' => 3, 'name' => 'Dragon Roll',        'price' => 15.99, 'image' => 'https://images.unsplash.com/photo-1562802378-063ec186a863?w=200', 'available' => true],
            ['restaurantId' => 4, 'name' => 'Beef Tacos',         'price' => 9.99,  'image' => 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=200', 'available' => true],
            ['restaurantId' => 4, 'name' => 'Chicken Quesadilla', 'price' => 10.99, 'image' => 'https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?w=200', 'available' => false],
            ['restaurantId' => 4, 'name' => 'Nachos Supreme',     'price' => 8.49,  'image' => 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=200', 'available' => true],
        ];

        foreach ($items as $item) {
            Menu::create($item);
        }
    }
}