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
        // Mahasiswa: +foto_profil_path
        Schema::table('mahasiswa', function (Blueprint $table) {
            $table->string('foto_profil_path')->nullable()->after('masa_aktif');
        });

        // Pemilik: +foto_profil_path
        Schema::table('pemilik', function (Blueprint $table) {
            $table->string('foto_profil_path')->nullable()->after('no_telp');
        });

        // Pegawai: +foto_profil_path
        Schema::table('pegawai', function (Blueprint $table) {
            $table->string('foto_profil_path')->nullable()->after('no_telp');
        });

        // Menu: +deskripsi, estimasi_waktu, pilihan_layanan (JSON), varian (JSON), topping (JSON)
        Schema::table('menu', function (Blueprint $table) {
            $table->text('deskripsi')->nullable()->after('status_stok');
            $table->integer('estimasi_waktu')->nullable()->after('deskripsi');
            $table->json('pilihan_layanan')->nullable()->after('estimasi_waktu');
            $table->json('varian')->nullable()->after('pilihan_layanan');
            $table->json('topping')->nullable()->after('varian');
        });

        // Keranjang: +varian_selected (JSON), topping_selected (JSON)
        Schema::table('keranjang', function (Blueprint $table) {
            $table->json('varian_selected')->nullable()->after('jumlah');
            $table->json('topping_selected')->nullable()->after('varian_selected');
        });

        // Pesanan: +nomor_antrian, catatan_pesanan
        Schema::table('pesanan', function (Blueprint $table) {
            $table->string('nomor_antrian')->nullable()->after('total_harga');
            $table->text('catatan_pesanan')->nullable()->after('nomor_antrian');
            $table->text('alasan_penolakan')->nullable()->after('catatan_pesanan');
        });

        // PesananDetail: +varian_snapshot (JSON), topping_snapshot (JSON)
        Schema::table('pesanan_detail', function (Blueprint $table) {
            $table->json('varian_snapshot')->nullable()->after('subtotal');
            $table->json('topping_snapshot')->nullable()->after('varian_snapshot');
        });

        // Payment: +nominal, waktu_bayar, midtrans_order_id, midtrans_snap_token
        Schema::table('payment', function (Blueprint $table) {
            $table->integer('nominal')->nullable()->after('log_transaksi');
            $table->timestamp('waktu_bayar')->nullable()->after('nominal');
            $table->string('midtrans_order_id')->nullable()->after('waktu_bayar');
            $table->string('midtrans_snap_token')->nullable()->after('midtrans_order_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('mahasiswa', function (Blueprint $table) {
            $table->dropColumn('foto_profil_path');
        });

        Schema::table('pemilik', function (Blueprint $table) {
            $table->dropColumn('foto_profil_path');
        });

        Schema::table('pegawai', function (Blueprint $table) {
            $table->dropColumn('foto_profil_path');
        });

        Schema::table('menu', function (Blueprint $table) {
            $table->dropColumn(['deskripsi', 'estimasi_waktu', 'pilihan_layanan', 'varian', 'topping']);
        });

        Schema::table('keranjang', function (Blueprint $table) {
            $table->dropColumn(['varian_selected', 'topping_selected']);
        });

        Schema::table('pesanan', function (Blueprint $table) {
            $table->dropColumn(['nomor_antrian', 'catatan_pesanan', 'alasan_penolakan']);
        });

        Schema::table('pesanan_detail', function (Blueprint $table) {
            $table->dropColumn(['varian_snapshot', 'topping_snapshot']);
        });

        Schema::table('payment', function (Blueprint $table) {
            $table->dropColumn(['nominal', 'waktu_bayar', 'midtrans_order_id', 'midtrans_snap_token']);
        });
    }
};
