<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ulasan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pesanan_id')->constrained('pesanan')->onDelete('cascade');
            $table->foreignId('mahasiswa_id')->constrained('mahasiswa')->onDelete('cascade');
            $table->foreignId('kantin_id')->constrained('kantin')->onDelete('cascade');
            
            // TAMBAHAN: Relasi spesifik ke menu yang dibeli
            $table->foreignId('menu_id')->constrained('menu')->onDelete('cascade');
            
            $table->tinyInteger('rating'); // 1–5
            $table->text('komentar')->nullable();
            $table->timestamps();

            // PERBAIKAN: Kombinasi pesanan dan menu harus unik
            // (Satu pesanan hanya bisa mengulas satu menu spesifik sebanyak satu kali)
            $table->unique(['pesanan_id', 'menu_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ulasan');
    }
};