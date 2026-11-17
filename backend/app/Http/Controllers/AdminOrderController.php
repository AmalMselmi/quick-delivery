<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminOrderController extends Controller
{
    public const STATUSES = ['pending', 'preparing', 'on_the_way', 'delivered', 'cancelled'];

    public function index(Request $request)
    {
        $query = Order::with(['items', 'user:id,name,email'])->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        return response()->json($query->get());
    }

    public function updateStatus(Request $request, $id)
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(self::STATUSES)],
        ]);

        $order = Order::findOrFail($id);
        $order->update(['status' => $data['status']]);

        return response()->json($order->fresh(['items', 'user:id,name,email']));
    }

    public function stats()
    {
        $ordersToday = Order::whereDate('created_at', today())->count();
        $revenueToday = Order::whereDate('created_at', today())
            ->where('status', '!=', 'cancelled')
            ->sum('total');

        return response()->json([
            'orders_today'  => $ordersToday,
            'revenue_today' => (float) $revenueToday,
            'pending'       => Order::where('status', 'pending')->count(),
            'restaurants'   => Restaurant::count(),
            'clients'       => User::where('role', 'client')->count(),
            'recent'        => Order::with(['items', 'user:id,name,email'])
                ->latest()
                ->take(5)
                ->get(),
        ]);
    }
}