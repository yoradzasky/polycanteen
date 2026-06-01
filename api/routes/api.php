<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;

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

    // Profile routes
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::post('/profile', [ProfileController::class, 'update']);
    
    // Kantin profile routes
    Route::get('/kantin/profile', [ProfileController::class, 'getKantinProfile']);
    Route::post('/kantin/profile', [ProfileController::class, 'updateKantinProfile']);
    
    // Password routes
    Route::put('/change-password', [ProfileController::class, 'changePassword']);

    Route::post('/logout', [AuthController::class, 'logout']);

    // Seller Routes
    Route::prefix('pemilik')->group(function () {
        Route::apiResource('menus', \App\Http\Controllers\Api\Seller\MenuController::class);
        Route::patch('menus/{menu}/toggle-status', [\App\Http\Controllers\Api\Seller\MenuController::class, 'toggleStatus']);
    });
});
