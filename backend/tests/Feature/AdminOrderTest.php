<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminOrderTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role): User
    {
        return User::create([
            'name' => ucfirst($role), 'email' => "{$role}@test.com",
            'password' => 'secret123', 'role' => $role,
        ]);
    }

    private function order(User $u, string $status = 'pending', float $total = 10): Order
    {
        return Order::create([
            'user_id' => $u->id, 'status' => $status,
            'total' => $total, 'address' => 'Tunis',
        ]);
    }

    public function test_client_cannot_list_admin_orders(): void
    {
        Sanctum::actingAs($this->user('client'));

        $this->getJson('/api/admin/orders')->assertForbidden();
    }

    public function test_admin_can_list_orders(): void
    {
        $this->order($this->user('client'));
        Sanctum::actingAs($this->user('admin'));

        $this->getJson('/api/admin/orders')->assertOk()->assertJsonCount(1);
    }

    public function test_admin_can_update_status(): void
    {
        $order = $this->order($this->user('client'));
        Sanctum::actingAs($this->user('admin'));

        $this->putJson("/api/admin/orders/{$order->id}/status", ['status' => 'delivered'])
            ->assertOk();

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'delivered']);
    }

    public function test_invalid_status_is_rejected(): void
    {
        $order = $this->order($this->user('client'));
        Sanctum::actingAs($this->user('admin'));

        $this->putJson("/api/admin/orders/{$order->id}/status", ['status' => 'flying'])
            ->assertStatus(422);
    }

    public function test_stats_exclude_cancelled_orders_from_revenue(): void
    {
        $client = $this->user('client');
        $this->order($client, 'pending', 10);
        $this->order($client, 'cancelled', 5);
        Sanctum::actingAs($this->user('admin'));

        $res = $this->getJson('/api/admin/stats')
            ->assertOk()
            ->assertJsonStructure(['orders_today', 'revenue_today', 'pending', 'restaurants', 'clients', 'recent']);

        $this->assertEquals(2, $res->json('orders_today'));
        $this->assertEquals(10.0, $res->json('revenue_today'));
    }
}