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
        Schema::create('menu', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kantin_id')->constrained('kantin')->onDelete('cascade');
            $table->string('nama_item');
            $table->string('kategori');
            $table->decimal('harga', 10, 2);
            $table->string('foto_menu')->nullable();
            $table->boolean('status_stok')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('menu');
    }
};
