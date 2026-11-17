<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Menu extends Model
{
    protected $table = 'menu';
    protected $fillable = ['restaurantId', 'name', 'price', 'image', 'available'];

    protected $casts = ['available' => 'boolean'];

    public function restaurant()
    {
        return $this->belongsTo(Restaurant::class, 'restaurantId');
    }
}