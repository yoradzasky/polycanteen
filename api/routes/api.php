<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Seller\OrderController;
use App\Http\Controllers\Api\Seller\MenuController;
use App\Http\Controllers\Api\Seller\KantinController;
use App\Http\Controllers\Api\Seller\ScannerController;
use App\Http\Controllers\Api\Seller\DeliveryController;
use App\Http\Controllers\Api\Student\TrackingController;
use App\Http\Controllers\Api\Student\OrderController as StudentOrderController;
use App\Http\Controllers\Api\Student\ReviewController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::post('/login', [AuthController::class, 'login']);

// Satu grup besar untuk semua yang butuh Login (Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    // --- Rute Auth & Profil ---
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::post('/logout', [AuthController::class, 'logout']);

    // --- Grup Khusus Penjual (Prefix: /pemilik) ---
    Route::prefix('pemilik')->group(function () {

        // Modul Pesanan (Orders)
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/orders/{id}', [OrderController::class, 'show']);
        Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);

        // Modul Manajemen Menu
        Route::apiResource('menus', MenuController::class);
        Route::patch('menus/{menu}/toggle-status', [MenuController::class, 'toggleStatus']);

        Route::patch('/kantin/status', [KantinController::class, 'updateStatus']);

        // Modul Scanner QR
        Route::post('/scanner/verify', [ScannerController::class, 'verify']);
        Route::post('/scanner/confirm', [ScannerController::class, 'confirm']);

        // Modul Pengantaran
        Route::get('/deliveries/{pesanan}', [DeliveryController::class, 'show']);
        Route::post('/deliveries/{pesanan}/start', [DeliveryController::class, 'start']);
        Route::post('/deliveries/{pesanan}/confirm', [DeliveryController::class, 'confirm']);
    });

    // --- Grup Khusus Mahasiswa (Prefix: /mahasiswa) ---
    Route::prefix('mahasiswa')->group(function () {
        // Modul Pesanan (Orders)
        Route::get('/orders', [StudentOrderController::class, 'index']);
        Route::get('/orders/{id}', [StudentOrderController::class, 'show']);
        // Modul Tracking
        Route::get('/deliveries/{pesanan}', [TrackingController::class, 'show']);
        // Modul Ulasan (Reviews)
        Route::post('/reviews', [ReviewController::class, 'store']);
    });
});