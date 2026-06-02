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
        Schema::create('pesanan_detail', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pesanan_id')->constrained('pesanan')->onDelete('cascade');
            $table->foreignId('menu_id')->constrained('menu')->onDelete('cascade');
            
            // SNAPSHOT HARGA DAN VARIAN
            // Menyimpan harga menu saat pembelian untuk konsistensi riwayat transaksi
            // Jika harga menu berubah kemudian, riwayat tetap menampilkan harga saat itu
            $table->decimal('harga_saat_beli', 10, 2);
            $table->integer('jumlah_pesanan');
            $table->decimal('subtotal', 10, 2); // harga_saat_beli * jumlah_pesanan
            
            // SNAPSHOT VARIAN & TOPPING
            // JSON untuk menyimpan pilihan varian dan topping dengan harganya
            // Format: [{ id, nama, harga }, ...]
            $table->json('varian_snapshot')->nullable();
            $table->json('topping_snapshot')->nullable();
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pesanan_detail');
    }
};