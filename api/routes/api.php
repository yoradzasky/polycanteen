<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\Seller\FinanceController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    // Rute profil user bawaan
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/logout', [AuthController::class, 'logout']);

    // ===== CART ROUTES (AC 1) =====
    Route::prefix('cart')->group(function () {
        Route::get('/', [CartController::class, 'index']); // GET /api/cart - List semua item
        Route::post('/', [CartController::class, 'store']); // POST /api/cart - Tambah item
        Route::put('/{id}', [CartController::class, 'update']); // PUT /api/cart/{id} - Update item
        Route::delete('/{id}', [CartController::class, 'destroy']); // DELETE /api/cart/{id} - Hapus item
        Route::delete('/clear/all', [CartController::class, 'clearAll']); // DELETE /api/cart/clear/all - Clear semua
    });

    // ===== CHECKOUT ROUTES (AC 2 & AC 3) =====
    Route::prefix('checkout')->group(function () {
        Route::post('/', [CheckoutController::class, 'checkout']); // POST /api/checkout - Process checkout
        Route::get('/preview', [CheckoutController::class, 'preview']); // GET /api/checkout/preview - Preview biaya
    });

    // ===== ORDERS ROUTES =====
    Route::get('/pesanan/{id}', [CheckoutController::class, 'getOrder']); // GET /api/pesanan/{id} - View order detail

    // Seller Routes
    Route::prefix('pemilik')->group(function () {
        Route::apiResource('menus', \App\Http\Controllers\Api\Seller\MenuController::class);
        Route::patch('menus/{menu}/toggle-status', [\App\Http\Controllers\Api\Seller\MenuController::class, 'toggleStatus']);

        Route::prefix('finance')->name('pemilik.finance.')->group(function () {
            Route::get('summary', [FinanceController::class, 'summary'])->name('summary');
            Route::get('revenue', [FinanceController::class, 'revenue'])->name('revenue');
            Route::get('withdrawals', [FinanceController::class, 'withdrawals'])->name('withdrawals');
        });
    });
});
