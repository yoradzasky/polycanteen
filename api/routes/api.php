<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\Seller\OrderController;
use App\Http\Controllers\Api\Seller\MenuController;
use App\Http\Controllers\Api\Seller\KantinController;

// --- TAMBAHKAN IMPORT INI UNTUK MAHASISWA ---
use App\Http\Controllers\Api\Student\PaymentController;
use App\Http\Controllers\Api\Student\MidtransWebhookController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// =================================================================
// ROUTE WEBHOOK MIDTRANS (TANPA MIDDLEWARE AUTH)
// =================================================================
Route::post('/webhooks/midtrans', [MidtransWebhookController::class, 'handle']);


Route::post('/login', [AuthController::class, 'login']);

// Satu grup besar untuk semua yang butuh Login (Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    // --- Rute Auth & Profil ---
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Profile routes
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::post('/profile', [ProfileController::class, 'update']);
    
    // Kantin profile routes
    Route::get('/kantin/profile', [ProfileController::class, 'getKantinProfile']);
    Route::post('/kantin/profile', [ProfileController::class, 'updateKantinProfile']);
    
    // Password routes
    Route::put('/change-password', [ProfileController::class, 'changePassword']);

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
    });

    // =================================================================
    // --- TAMBAHAN ROUTE UNTUK PEMBAYARAN MAHASISWA ---
    // =================================================================
    Route::get('/student/orders/latest-pending', [PaymentController::class, 'getLatestPendingOrder']);
    Route::post('/student/payment/{pesanan_id}', [PaymentController::class, 'createPayment']);
    Route::get('/student/payment/status/{pesanan_id}', [PaymentController::class, 'checkStatus']);

});