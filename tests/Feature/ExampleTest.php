<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    /**
     * A basic test example.
     *
     * @return void
     */
    public function testBasicTest()
    {
        User::factory()->create([
            'name' => 'John',
        ]);

        $user = User::where('name', 'John')->first();

        self::assertEquals($user->name, 'John');

        $response = $this->get('/');

        $response->assertStatus(200);
    }
}
