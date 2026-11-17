<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Create default admin account
        User::create([
            'name'     => 'Admin',
            'email'    => 'admin@quickdelivery.com',
            'password' => Hash::make('admin123'),
            'role'     => 'admin',
        ]);

        // Create a test client account
        User::create([
            'name'     => 'Test Client',
            'email'    => 'client@quickdelivery.com',
            'password' => Hash::make('client123'),
            'role'     => 'client',
        ]);

        $this->call([
            RestaurantSeeder::class,
            MenuSeeder::class,
        ]);
    }
}