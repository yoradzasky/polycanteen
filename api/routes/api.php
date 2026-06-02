<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CheckoutController;
use App\Http\Controllers\Api\Seller\FinanceController;
use App\Http\Controllers\Api\Seller\KantinController;
use App\Http\Controllers\Api\Seller\MenuController;
use App\Http\Controllers\Api\Seller\OrderController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::prefix('cart')->group(function () {
        Route::get('/', [CartController::class, 'index']);
        Route::post('/', [CartController::class, 'store']);
        Route::put('/{id}', [CartController::class, 'update']);
        Route::delete('/{id}', [CartController::class, 'destroy']);
        Route::delete('/clear/all', [CartController::class, 'clearAll']);
    });

    Route::prefix('checkout')->group(function () {
        Route::post('/', [CheckoutController::class, 'checkout']);
        Route::get('/preview', [CheckoutController::class, 'preview']);
    });

    Route::get('/pesanan/{id}', [CheckoutController::class, 'getOrder']);

    Route::prefix('pemilik')->group(function () {
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/orders/{id}', [OrderController::class, 'show']);
        Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);

        Route::apiResource('menus', MenuController::class);
        Route::patch('menus/{menu}/toggle-status', [MenuController::class, 'toggleStatus']);

        Route::patch('/kantin/status', [KantinController::class, 'updateStatus']);

        Route::prefix('finance')->name('pemilik.finance.')->group(function () {
            Route::get('summary', [FinanceController::class, 'summary'])->name('summary');
            Route::get('revenue', [FinanceController::class, 'revenue'])->name('revenue');
            Route::get('withdrawals', [FinanceController::class, 'withdrawals'])->name('withdrawals');
        });
    });

});
