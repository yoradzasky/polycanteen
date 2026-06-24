<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\Seller\OrderController;
use App\Http\Controllers\Api\Seller\MenuController;
use App\Http\Controllers\Api\Seller\KantinController;
use App\Http\Controllers\Api\Seller\ScannerController;
use App\Http\Controllers\Api\Seller\DeliveryController;
use App\Http\Controllers\Api\Student\TrackingController;
use App\Http\Controllers\Api\Student\OrderController as StudentOrderController;
use App\Http\Controllers\Api\Student\MahasiswaController;
use App\Http\Controllers\Api\Student\KantinController as StudentKantinController;
use App\Http\Controllers\Api\Student\MenuController as StudentMenuController;
use App\Http\Controllers\Api\Student\CartController;
use App\Http\Controllers\Api\Student\ReviewController;
use App\Http\Controllers\Api\FcmTokenController;

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
Route::post('/register', [AuthController::class, 'register']);

// Satu grup besar untuk semua yang butuh Login (Token Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    // FCM Token Management
    Route::post('/fcm-token', [FcmTokenController::class, 'update']);
    Route::delete('/fcm-token', [FcmTokenController::class, 'delete']);

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

    // --- Grup Khusus Mahasiswa / Student (Prefix: /student) ---
    Route::prefix('student')->group(function () {

        // Rute untuk mengambil data beranda dinamis
        Route::get('/beranda', [MahasiswaController::class, 'getBerandaData']);

        Route::get('/kantin', [StudentKantinController::class, 'index']);

        Route::get('/kantin/{kantin_id}/menu', [StudentMenuController::class, 'index']);

        // Rute Keranjang (Cart)
        Route::get('/keranjang', [CartController::class, 'index']);
        Route::post('/keranjang', [CartController::class, 'store']);
        Route::post('/keranjang/checkout', [CartController::class, 'checkout']);
        Route::put('/keranjang/{id}', [CartController::class, 'update']);
        Route::delete('/keranjang/{menu_id}', [CartController::class, 'destroy']);
        Route::delete('/keranjang/clear/all', [CartController::class, 'clearAll']);

        // Rute untuk mengambil data profil mahasiswa (TAMBAHKAN DI SINI)
        Route::get('/profil', [MahasiswaController::class, 'getProfileData']);

        // TAMBAHKAN BARIS INI: Rute untuk update profil mahasiswa
        Route::post('/profil/update', [MahasiswaController::class, 'updateProfile']);

        // --- TAMBAHAN ROUTE UNTUK PEMBAYARAN MAHASISWA ---
        Route::get('/orders/latest-pending', [PaymentController::class, 'getLatestPendingOrder']);
        Route::post('/payment/{pesanan_id}', [PaymentController::class, 'createPayment']);
        Route::get('/payment/status/{pesanan_id}', [PaymentController::class, 'checkStatus']);
        Route::patch('/orders/{id}/submit', [StudentOrderController::class, 'submitOrder']);
        Route::patch('/orders/{id}/cancel', [StudentOrderController::class, 'cancelOrder']);
    });

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

        // Modul Profil Pemilik
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::post('/profile', [ProfileController::class, 'update']);
        Route::get('/kantin/profile', [ProfileController::class, 'getKantinProfile']);
        Route::post('/kantin/profile', [ProfileController::class, 'updateKantinProfile']);
        Route::put('/change-password', [ProfileController::class, 'changePassword']);
    });



    // --- Grup Khusus Mahasiswa (Prefix: /mahasiswa) ---
    Route::prefix('mahasiswa')->group(function () {
        // Rute untuk mengambil data beranda dinamis
        Route::get('/beranda', [MahasiswaController::class, 'getBerandaData']);

        Route::get('/kantin', [StudentKantinController::class, 'index']);
        Route::get('/kantin/{kantin_id}/menu', [StudentMenuController::class, 'index']);

        // Rute Keranjang (Cart)
        Route::get('/keranjang', [CartController::class, 'index']);
        Route::post('/keranjang', [CartController::class, 'store']);
        Route::post('/keranjang/checkout', [CartController::class, 'checkout']);
        Route::put('/keranjang/{id}', [CartController::class, 'update']);
        Route::delete('/keranjang/{menu_id}', [CartController::class, 'destroy']);
        Route::delete('/keranjang/clear/all', [CartController::class, 'clearAll']);

        // Rute profil mahasiswa
        Route::get('/profil', [MahasiswaController::class, 'getProfileData']);
        Route::post('/profil/update', [MahasiswaController::class, 'updateProfile']);

        // Modul Pesanan (Orders)
        Route::get('/orders', [StudentOrderController::class, 'index']);
        Route::get('/orders/{id}', [StudentOrderController::class, 'show']);
        Route::patch('/orders/{id}/submit', [StudentOrderController::class, 'submitOrder']);
        Route::patch('/orders/{id}/cancel', [StudentOrderController::class, 'cancelOrder']);
        
        // Modul Tracking
        Route::get('/deliveries/{pesanan}', [TrackingController::class, 'show']);
        
        // Modul Ulasan (Reviews)
        Route::post('/reviews', [ReviewController::class, 'store']);

        // Rute pembayaran & status pesanan
        Route::get('/orders/latest-pending', [PaymentController::class, 'getLatestPendingOrder']);
        Route::post('/payment/{pesanan_id}', [PaymentController::class, 'createPayment']);
        Route::get('/payment/status/{pesanan_id}', [PaymentController::class, 'checkStatus']);
    });
});