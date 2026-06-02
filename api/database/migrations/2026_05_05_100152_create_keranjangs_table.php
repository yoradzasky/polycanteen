<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('keranjang', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mahasiswa_id')->constrained('mahasiswa')->onDelete('cascade');
            $table->foreignId('menu_id')->constrained('menu')->onDelete('cascade');
            $table->foreignId('kantin_id')->constrained('kantin')->onDelete('cascade'); // FK ke kantin
            
            $table->integer('jumlah');
            
            // VARIAN & TOPPING SELECTION
            // JSON untuk menyimpan pilihan varian dan topping yang dipilih
            // Format: [{ id, nama, harga }, ...]
            $table->json('varian_selected')->nullable();
            $table->json('topping_selected')->nullable();
            
            // UNIQUE CONSTRAINT untuk mencegah duplikasi item dengan varian sama
            // Setiap kombinasi mahasiswa-menu-varian harus unik
            $table->timestamps();
            $table->unique(['mahasiswa_id', 'menu_id', 'varian_selected', 'topping_selected'], 'unique_cart_item');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('keranjang');
    }
};
