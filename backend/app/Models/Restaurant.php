<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Restaurant extends Model
{
    protected $fillable = ['name', 'image', 'rating', 'cuisineType', 'latitude', 'longitude'];

    public function menu()
    {
        return $this->hasMany(Menu::class, 'restaurantId');
    }
}