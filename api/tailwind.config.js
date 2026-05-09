import defaultTheme from 'tailwindcss/defaultTheme';

/** @type {import('tailwindcss').Config} */
export default {
    content: [
        './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
        './storage/framework/views/*.php',
        './resources/views/**/*.blade.php',
        './resources/js/**/*.jsx', // Pastikan baris ini ada
    ],
    theme: {
        extend: {
            colors: {
                cobalt: "var(--cobalt)",
                "d-9d-9d-9": "var(--d-9d-9d-9)",
                periwinkle: "var(--periwinkle)",
                sand: "var(--sand)",
                "variable-collection-color": "var(--variable-collection-color)",
                "warm-orange": "var(--warm-orange)",
            },
        },
    },
    plugins: [],
};