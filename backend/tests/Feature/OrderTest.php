<?php

namespace Tests\Feature;

use App\Models\Menu;
use App\Models\Order;
use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrderTest extends TestCase
{
    use RefreshDatabase;

    private function client(string $email = 'c@test.com'): User
    {
        return User::create([
            'name' => 'Client', 'email' => $email,
            'password' => 'secret123', 'role' => 'client',
        ]);
    }

    private function restaurant(array $extra = []): Restaurant
    {
        return Restaurant::create(array_merge([
            'name' => 'R', 'image' => 'x', 'rating' => 4, 'cuisineType' => 'Italian',
        ], $extra));
    }

    private function menuItem(?Restaurant $r = null, bool $available = true): Menu
    {
        $r = $r ?? $this->restaurant();

        return Menu::create([
            'restaurantId' => $r->id, 'name' => 'Pizza', 'price' => 10,
            'image' => 'x', 'available' => $available,
        ]);
    }

    public function test_guest_cannot_place_order(): void
    {
        $this->postJson('/api/orders', [])->assertUnauthorized();
    }

    public function test_client_can_place_order_and_total_is_computed_by_server(): void
    {
        $item = $this->menuItem();
        Sanctum::actingAs($this->client());

        $this->postJson('/api/orders', [
            'address' => 'Tunis',
            'items'   => [['id' => $item->id, 'quantity' => 2]],
        ])->assertCreated();

        $this->assertDatabaseHas('orders', [
            'total' => 23, 'delivery_fee' => 3, 'status' => 'pending',
        ]);
        $this->assertDatabaseHas('order_items', ['name' => 'Pizza', 'quantity' => 2]);
    }

    public function test_unavailable_item_is_rejected(): void
    {
        $item = $this->menuItem(null, false);
        Sanctum::actingAs($this->client());

        $this->postJson('/api/orders', [
            'address' => 'Tunis',
            'items'   => [['id' => $item->id, 'quantity' => 1]],
        ])->assertStatus(422);
    }

    public function test_client_only_sees_own_orders(): void
    {
        $owner = $this->client('a@test.com');
        $other = $this->client('b@test.com');
        Order::create(['user_id' => $owner->id, 'total' => 10, 'address' => 'Tunis']);

        Sanctum::actingAs($other);
        $this->getJson('/api/orders')->assertOk()->assertJsonCount(0);

        Sanctum::actingAs($owner);
        $this->getJson('/api/orders')->assertOk()->assertJsonCount(1);
    }

    public function test_delivery_fee_grows_with_distance(): void
    {
        $r = $this->restaurant(['latitude' => 36.8065, 'longitude' => 10.1815]);
        $item = $this->menuItem($r);
        Sanctum::actingAs($this->client());

        $res = $this->postJson('/api/orders/quote', [
            'latitude'  => 36.8065,
            'longitude' => 10.2815,
            'items'     => [['id' => $item->id, 'quantity' => 1]],
        ])->assertOk();

        $this->assertGreaterThan(6.0, $res->json('delivery_fee'));
        $this->assertLessThan(7.0, $res->json('delivery_fee'));
    }

    public function test_flat_fee_when_no_location(): void
    {
        $item = $this->menuItem();
        Sanctum::actingAs($this->client());

        $res = $this->postJson('/api/orders/quote', [
            'items' => [['id' => $item->id, 'quantity' => 1]],
        ])->assertOk();

        $this->assertEquals(3.0, $res->json('delivery_fee'));
        $this->assertEquals(13.0, $res->json('total'));
    }

    public function test_items_from_two_restaurants_are_rejected(): void
    {
        $a = $this->menuItem($this->restaurant());
        $b = $this->menuItem($this->restaurant());
        Sanctum::actingAs($this->client());

        $this->postJson('/api/orders', [
            'address' => 'Tunis',
            'items'   => [
                ['id' => $a->id, 'quantity' => 1],
                ['id' => $b->id, 'quantity' => 1],
            ],
        ])->assertStatus(422);
    }
}