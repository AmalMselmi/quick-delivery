<?php

namespace App\Http\Controllers;

use App\Models\Restaurant;
use Illuminate\Http\Request;

class RestaurantController extends Controller
{
    public function index()
    {
        return response()->json(Restaurant::all());
    }

    public function show($id)
    {
        return response()->json(Restaurant::findOrFail($id));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'        => 'required|string|max:255',
            'image'       => 'required|string',
            'rating'      => 'required|numeric|min:0|max:5',
            'cuisineType' => 'required|string|max:100',
            'latitude'    => 'nullable|numeric|between:-90,90',
            'longitude'   => 'nullable|numeric|between:-180,180',
        ]);

        return response()->json(Restaurant::create($data), 201);
    }

    public function update(Request $request, $id)
    {
        $restaurant = Restaurant::findOrFail($id);

        $data = $request->validate([
            'name'        => 'string|max:255',
            'image'       => 'string',
            'rating'      => 'numeric|min:0|max:5',
            'cuisineType' => 'string|max:100',
            'latitude'    => 'nullable|numeric|between:-90,90',
            'longitude'   => 'nullable|numeric|between:-180,180',
        ]);

        $restaurant->update($data);

        return response()->json($restaurant);
    }

    public function destroy($id)
    {
        Restaurant::findOrFail($id)->delete();

        return response()->json(['message' => 'Restaurant deleted successfully']);
    }
}