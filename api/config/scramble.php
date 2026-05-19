<?php

use Dedoc\Scramble\Http\Middleware\RestrictedDocsAccess;

return [
    /*
     * biarkan ini 'api'. Scramble akan otomatis membaca file routes/api.php
     */
    'api_path' => 'api',

    'api_domain' => null,

    'export_path' => 'api.json',

    'info' => [
        'version' => env('API_VERSION', '1.0.0'),
        // Tambahkan deskripsi agar dokumentasinya terlihat profesional
        'description' => 'Dokumentasi API resmi untuk aplikasi PolyCanteen (Mobile & Web). Terintegrasi dengan sistem otentikasi Bearer Token.',
    ],

    'ui' => [
        // Beri nama judul dokumentasinya
        'title' => 'PolyCanteen API Docs',
        'theme' => 'light',
        'hide_try_it' => false, // Biarkan false agar kamu bisa test API langsung dari web!
        'logo' => '',
        'try_it_credentials_policy' => 'include',
    ],

    /*
     * Atur server URL agar fitur "Try It" bisa langsung menembak ke URL yang benar.
     * Sesuaikan dengan URL lokal kamu (biasanya 127.0.0.1:8000)
     */
    'servers' => [
        'Local' => 'api', // Akan otomatis menjadi http://127.0.0.1:8000/api
        // 'Production' => 'https://api.polycanteen.com/api', // Buka komentar ini nanti saat rilis
    ],

    'middleware' => [
        'web',
        RestrictedDocsAccess::class,
    ],

    'extensions' => [],
];