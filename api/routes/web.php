<?php

use App\Http\Controllers\Admin\CanteenController;
use App\Http\Controllers\Admin\BuyerController; // Jangan lupa tambahkan ini
use App\Http\Controllers\Admin\BuyerApprovalController;
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

    // ==========================================
    // MANAJEMEN KANTIN
    // ==========================================
    Route::get('/canteens', [CanteenController::class, 'index'])
        ->name('canteens.index');

    Route::get('/canteens/create', [CanteenController::class, 'create'])
        ->name('canteens.create');
    // URL: GET /admin/canteens/create
    // Name: admin.canteens.create

    Route::post('/canteens', [CanteenController::class, 'store'])
        ->name('canteens.store');
    // URL: POST /admin/canteens
    // Name: admin.canteens.store

    Route::get('/canteens/{id}', [CanteenController::class, 'show'])
        ->name('canteens.show');
    // URL: GET /admin/canteens/{id}
    // Name: admin.canteens.show

    Route::get('/canteens/{id}/edit', [CanteenController::class, 'edit'])
        ->name('canteens.edit');
    // URL: GET /admin/canteens/{id}/edit
    // Name: admin.canteens.edit

    Route::put('/canteens/{id}', [CanteenController::class, 'update'])
        ->name('canteens.update');
    // URL: PUT /admin/canteens/{id}
    // Name: admin.canteens.update

    Route::delete('/canteens/{id}', [CanteenController::class, 'destroy'])
        ->name('canteens.destroy');
    // URL: DELETE /admin/canteens/{id}
    // Name: admin.canteens.destroy


    // ==========================================
    // MANAJEMEN PEMBELI
    // ==========================================
    Route::get('/buyers', [BuyerController::class, 'index'])
        ->name('buyers.index');
    // URL: GET /admin/buyers
    // Name: admin.buyers.index

    Route::get('/buyers/{id}', [BuyerController::class, 'show'])
        ->name('buyers.show');
    // URL: GET /admin/buyers/{id}
    // Name: admin.buyers.show

    Route::patch('/buyers/{id}/expiration', [BuyerController::class, 'updateExpiration'])
        ->name('buyers.updateExpiration');
    // URL: PATCH /admin/buyers/{id}/expiration
    // Name: admin.buyers.updateExpiration

    Route::prefix('approvals')->name('approvals.')->group(function () {
        Route::get('/', [BuyerApprovalController::class, 'index'])
            ->name('index');

        Route::get('/{application}', [BuyerApprovalController::class, 'show'])
            ->name('show');

        Route::post('/{application}/approve', [BuyerApprovalController::class, 'approve'])
            ->name('approve');

        Route::post('/{application}/reject', [BuyerApprovalController::class, 'reject'])
            ->name('reject');
    });

    Route::prefix('buyer-applications')->name('buyer-applications.')->group(function () {
        Route::post('/{application}/approve', [BuyerApprovalController::class, 'approve'])
            ->name('approve');

        Route::post('/{application}/reject', [BuyerApprovalController::class, 'reject'])
            ->name('reject');
    });

});

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__ . '/auth.php';
