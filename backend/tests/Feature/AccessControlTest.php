<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccessControlTest extends TestCase
{
    use RefreshDatabase;

    private function makeUser(string $role): User
    {
        return User::create([
            'name'     => ucfirst($role),
            'email'    => "{$role}@test.com",
            'password' => 'secret123',
            'role'     => $role,
        ]);
    }

    private function restaurantPayload(): array
    {
        return [
            'name'        => 'Test Place',
            'image'       => 'https://example.com/a.jpg',
            'rating'      => 4.5,
            'cuisineType' => 'Italian',
        ];
    }

    public function test_login_returns_token_and_role(): void
    {
        $this->makeUser('client');

        $this->postJson('/api/login', [
            'email'    => 'client@test.com',
            'password' => 'secret123',
        ])
            ->assertOk()
            ->assertJsonStructure(['token', 'role', 'name', 'email'])
            ->assertJsonPath('role', 'client');
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $this->makeUser('client');

        $this->postJson('/api/login', [
            'email'    => 'client@test.com',
            'password' => 'wrong',
        ])->assertStatus(401);
    }

    public function test_guest_gets_401_on_admin_route(): void
    {
        $this->postJson('/api/admin/restaurants', $this->restaurantPayload())
            ->assertUnauthorized();
    }

    public function test_client_gets_403_on_admin_route(): void
    {
        Sanctum::actingAs($this->makeUser('client'));

        $this->postJson('/api/admin/restaurants', $this->restaurantPayload())
            ->assertForbidden();
    }

    public function test_admin_can_create_restaurant(): void
    {
        Sanctum::actingAs($this->makeUser('admin'));

        $this->postJson('/api/admin/restaurants', $this->restaurantPayload())
            ->assertCreated()
            ->assertJsonPath('name', 'Test Place');
    }

    public function test_register_ignores_requested_role(): void
{
    $this->postJson('/api/register', [
        'name'     => 'Sneaky',
        'email'    => 'sneaky@test.com',
        'password' => 'secret123',
        'role'     => 'admin',
    ])
        ->assertCreated()
        ->assertJsonPath('role', 'client');
}
}