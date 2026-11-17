<?php

namespace App\Http\Controllers;

use App\Models\Menu;
use Illuminate\Http\Request;

class MenuController extends Controller
{
    // GET /api/menu?restaurantId=1  (public)
    public function index(Request $request)
    {
        $restaurantId = $request->query('restaurantId');

        $menu = $restaurantId
            ? Menu::where('restaurantId', $restaurantId)->get()
            : Menu::all();

        return response()->json($menu);
    }

    // GET /api/menu/{id}  (public)
    public function show($id)
    {
        $item = Menu::findOrFail($id);
        return response()->json($item);
    }

    // POST /api/admin/menu  (admin only)
    public function store(Request $request)
    {
        $request->validate([
            'restaurantId' => 'required|exists:restaurants,id',
            'name'         => 'required|string|max:255',
            'price'        => 'required|numeric|min:0',
            'image'        => 'required|string',
            'available'    => 'boolean',
        ]);

        $item = Menu::create($request->all());
        return response()->json($item, 201);
    }

    // PUT /api/admin/menu/{id}  (admin only)
    public function update(Request $request, $id)
    {
        $item = Menu::findOrFail($id);

        $request->validate([
            'restaurantId' => 'exists:restaurants,id',
            'name'         => 'string|max:255',
            'price'        => 'numeric|min:0',
            'image'        => 'string',
            'available'    => 'boolean',
        ]);

        $item->update($request->all());
        return response()->json($item);
    }

    // DELETE /api/admin/menu/{id}  (admin only)
    public function destroy($id)
    {
        $item = Menu::findOrFail($id);
        $item->delete();
        return response()->json(['message' => 'Menu item deleted successfully']);
    }
}