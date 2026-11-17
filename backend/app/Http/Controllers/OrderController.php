<?php

namespace App\Http\Controllers;

use App\Models\Menu;
use App\Models\Order;
use App\Models\Restaurant;
use App\Services\DeliveryFee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = $request->user()
            ->orders()
            ->with('items')
            ->latest()
            ->get();

        return response()->json($orders);
    }

    public function quote(Request $request)
    {
        $data = $request->validate($this->rules(false));
        $priced = $this->price($data);

        return response()->json([
            'subtotal'     => $priced['subtotal'],
            'delivery_fee' => $priced['delivery_fee'],
            'total'        => round($priced['subtotal'] + $priced['delivery_fee'], 2),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate($this->rules(true));
        $priced = $this->price($data);

        $order = DB::transaction(function () use ($data, $priced, $request) {
            $order = Order::create([
                'user_id'        => $request->user()->id,
                'restaurant_id'  => $priced['restaurant_id'],
                'status'         => 'pending',
                'total'          => round($priced['subtotal'] + $priced['delivery_fee'], 2),
                'delivery_fee'   => $priced['delivery_fee'],
                'address'        => $data['address'],
                'latitude'       => $data['latitude'] ?? null,
                'longitude'      => $data['longitude'] ?? null,
                'payment_method' => 'cash',
            ]);

            $order->items()->createMany($priced['lines']);

            return $order;
        });

        return response()->json($order->fresh('items'), 201);
    }

    private function rules(bool $withAddress): array
    {
        return [
            'address'          => ($withAddress ? 'required' : 'nullable') . '|string|max:500',
            'latitude'         => 'nullable|numeric|between:-90,90',
            'longitude'        => 'nullable|numeric|between:-180,180',
            'items'            => 'required|array|min:1',
            'items.*.id'       => 'required|integer|exists:menu,id',
            'items.*.quantity' => 'required|integer|min:1|max:50',
        ];
    }

    private function price(array $data): array
    {
        $subtotal = 0;
        $lines = [];
        $restaurantIds = [];

        foreach ($data['items'] as $line) {
            $menuItem = Menu::findOrFail($line['id']);

            if (!$menuItem->available) {
                abort(422, "{$menuItem->name} is not available");
            }

            $restaurantIds[$menuItem->restaurantId] = true;
            $subtotal += (float) $menuItem->price * $line['quantity'];
            $lines[] = [
                'name'     => $menuItem->name,
                'price'    => $menuItem->price,
                'quantity' => $line['quantity'],
            ];
        }

        if (count($restaurantIds) > 1) {
            abort(422, 'Your cart contains items from more than one restaurant');
        }

        $restaurantId = array_key_first($restaurantIds);
        $restaurant = Restaurant::find($restaurantId);

        $fee = DeliveryFee::calculate(
            $restaurant,
            isset($data['latitude']) ? (float) $data['latitude'] : null,
            isset($data['longitude']) ? (float) $data['longitude'] : null,
        );

        return [
            'restaurant_id' => $restaurantId,
            'subtotal'      => round($subtotal, 2),
            'delivery_fee'  => $fee,
            'lines'         => $lines,
        ];
    }
}