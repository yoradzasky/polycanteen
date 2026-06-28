<?php

use App\Http\Controllers\Admin\CanteenController;
use App\Http\Controllers\Admin\BuyerApprovalController;
use App\Http\Controllers\Admin\BuyerController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\SellerController;
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

    // ==========================================
    // PERSETUJUAN AKUN PEMBELI
    // ==========================================
    Route::get('/approvals', [BuyerApprovalController::class, 'index'])
        ->name('approvals.index');

    Route::get('/approvals/{application}', [BuyerApprovalController::class, 'show'])
        ->name('approvals.show');

    Route::post('/approvals/{application}/approve', [BuyerApprovalController::class, 'approve'])
        ->name('approvals.approve');

    Route::post('/approvals/{application}/reject', [BuyerApprovalController::class, 'reject'])
        ->name('approvals.reject');

    // ==========================================
    // MANAJEMEN AKUN ADMIN
    // ==========================================
    Route::put('/password', [\App\Http\Controllers\AdminController::class, 'updatePassword'])
        ->name('password.update');

});

Route::middleware('auth')->group(function () {
    Route::get('/profile', [SellerController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [SellerController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [SellerController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__ . '/auth.php';
