<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;
use Dedoc\Scramble\Scramble;
use Dedoc\Scramble\Support\Generator\OpenApi;
use Dedoc\Scramble\Support\Generator\SecurityScheme;


use Illuminate\Support\Facades\URL;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Paksa HTTPS jika menggunakan Ngrok atau di production
        if (str_contains(config('app.url'), 'ngrok-free.dev') || config('app.env') !== 'local') {
            URL::forceScheme('https');
        }

        // 1. Mengizinkan akses ke dokumentasi API (wajib jika APP_ENV bukan local)
        Gate::define('viewApi', function ($user = null) {
            return true; // Semua orang bisa melihat dokumentasi. Sesuaikan jika butuh batasan.
        });

        // 2. Tambahkan kode ini agar gembok JWT-nya muncul
        Scramble::extendOpenApi(function (OpenApi $openApi) {
            $openApi->secure(
                SecurityScheme::http('bearer', 'JWT')
            );
        });
    }
}