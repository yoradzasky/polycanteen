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
        Schema::create('pesanan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mahasiswa_id')->constrained('mahasiswa')->onDelete('cascade');
            $table->foreignId('kantin_id')->constrained('kantin')->onDelete('cascade');
            
            // TIPE PENGIRIMAN: dine_in, takeaway, delivery
            $table->enum('tipe_pesanan', ['dine_in', 'takeaway', 'delivery'])->default('dine_in');
            $table->enum('status_pesanan', ['pending', 'dibayar', 'diproses', 'siap', 'selesai', 'dibatalkan'])->default('pending');
            
            $table->decimal('total_harga', 10, 2);
            $table->decimal('biaya_layanan', 10, 2)->default(0); // Service fee untuk delivery
            
            // DETAIL PESANAN
            $table->text('catatan_pesanan')->nullable(); // Catatan khusus dari pembeli
            $table->text('alamat_pengiriman')->nullable(); // Alamat untuk delivery
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 10, 8)->nullable();
            
            // NOMOR ANTRIAN AUTO-GENERATED
            $table->string('nomor_antrian')->nullable()->unique();
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pesanan');
    }
};
