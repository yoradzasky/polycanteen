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
use App\Http\Controllers\Api\Seller\FinanceController;
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
Route::middleware(['auth:sanctum', 'check.status'])->group(function () {

    // FCM Token Management
    Route::post('/fcm-token', [FcmTokenController::class, 'update']);
    Route::delete('/fcm-token', [FcmTokenController::class, 'delete']);

    // --- Rute Auth & Profil ---
    Route::get('/user', function (Request $request) {
        return $request->user();
    });




    // --- Grup Khusus Penjual (Prefix: /penjual) ---
    Route::prefix('penjual')->group(function () {

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
        Route::post('/logout', [AuthController::class, 'logout']);

        // Modul Keuangan & Laporan
        Route::get('/finance/summary', [FinanceController::class, 'summary']);
        Route::get('/finance/history', [FinanceController::class, 'history']);
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
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::post('/profile', [ProfileController::class, 'update']);
        Route::put('/change-password', [ProfileController::class, 'changePassword']);
        Route::post('/logout', [AuthController::class, 'logout']);

        // Modul Pesanan (Orders)
        Route::get('/orders', [StudentOrderController::class, 'index']);
        Route::get('/orders/latest-pending', [PaymentController::class, 'getLatestPendingOrder']);
        Route::get('/orders/{id}', [StudentOrderController::class, 'show']);
        Route::patch('/orders/{id}/submit', [StudentOrderController::class, 'submitOrder']);
        Route::patch('/orders/{id}/cancel', [StudentOrderController::class, 'cancelOrder']);
        Route::patch('/orders/{id}/items', [StudentOrderController::class, 'updateItemQuantity']);
        
        // Modul Tracking
        Route::get('/deliveries/{pesanan}', [TrackingController::class, 'show']);
        
        // Modul Ulasan (Reviews)
        Route::post('/reviews', [ReviewController::class, 'store']);

        // Rute pembayaran & status pesanan
        Route::post('/payment/{pesanan_id}', [PaymentController::class, 'createPayment']);
        Route::get('/payment/status/{pesanan_id}', [PaymentController::class, 'checkStatus']);
    });
});