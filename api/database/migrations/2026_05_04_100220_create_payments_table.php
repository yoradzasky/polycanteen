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
        Schema::create('payment', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pesanan_id')->constrained('pesanan')->onDelete('cascade');
            $table->string('metode_bayar');
            $table->string('status_bayar');
            $table->text('log_transaksi')->nullable();
            $table->integer('nominal')->nullable();
            $table->timestamp('waktu_bayar')->nullable();
            $table->string('midtrans_order_id')->nullable();
            $table->string('midtrans_snap_token')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment');
    }
};
