<?php

use App\Http\Controllers\Admin\CanteenController;
use App\Http\Controllers\ProfileController;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\DashboardController;
use Inertia\Inertia;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return redirect()->route('login');
});

Route::prefix('admin')->middleware(['auth', 'role:admin'])->name('admin.')->group(function () {

    Route::get('/dashboard', [DashboardController::class, 'index'])
        ->name('dashboard');

    Route::get('/canteens', [CanteenController::class, 'index'])
        ->name('canteens.index');

    Route::get('/canteens/create', [CanteenController::class, 'create'])
        ->name('canteens.create');
    // URL: GET /admin/kantin/create
    // Name: admin.canteens.create

    Route::post('/canteens', [CanteenController::class, 'store'])
        ->name('canteens.store');
    // URL: POST /admin/kantin
    // Name: admin.canteens.store

    Route::get('/canteens/{id}', [CanteenController::class, 'show'])
        ->name('canteens.show');
    // URL: GET /admin/kantin/{id}
    // Name: admin.canteens.show

    Route::get('/canteens/{id}/edit', [CanteenController::class, 'edit'])
        ->name('canteens.edit');
    // URL: GET /admin/kantin/{id}/edit
    // Name: admin.canteens.edit

    Route::put('/canteens/{id}', [CanteenController::class, 'update'])
        ->name('canteens.update');
    // URL: PUT /admin/kantin/{id}
    // Name: admin.canteens.update

    Route::delete('/canteens/{id}', [CanteenController::class, 'destroy'])
        ->name('canteens.destroy');
    // URL: DELETE /admin/kantin/{id}
    // Name: admin.canteens.destroy

});

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__ . '/auth.php';
