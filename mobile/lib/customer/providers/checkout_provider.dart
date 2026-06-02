import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pesanan.dart';

/// Checkout Provider - Mengelola proses checkout
class CheckoutProvider extends ChangeNotifier {
  final String apiBaseUrl = 'http://192.168.1.100:8000/api'; // Ganti dengan URL backend Anda
  
  bool _isLoading = false;
  String? _error;
  Pesanan? _currentOrder;
  
  Map<String, dynamic>? _checkoutPreview;

  // GETTER
  bool get isLoading => _isLoading;
  String? get error => _error;
  Pesanan? get currentOrder => _currentOrder;
  Map<String, dynamic>? get checkoutPreview => _checkoutPreview;

  /// PREVIEW CHECKOUT
  /// Menampilkan preview biaya sebelum checkout (untuk validasi di UI)
  Future<bool> previewCheckout({
    required String token,
    required int kantinId,
    required String tipePesanan,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/checkout/preview?kantin_id=$kantinId&tipe_pesanan=$tipePesanan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _checkoutPreview = data['data'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to load checkout preview';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// PROCESS CHECKOUT
  /// AC 2: Fungsi Checkout dapat mengonversi seluruh isi keranjang menjadi data pada tabel `pesanan` dan `pesanan_detail`.
  /// AC 3: Sistem mutlak harus menyimpan snapshot harga dan varian pada `pesanan_detail`
  Future<bool> processCheckout({
    required String token,
    required int kantinId,
    required String tipePesanan,
    required String catatanPesanan,
    String? alamatPengiriman,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'kantin_id': kantinId,
        'tipe_pesanan': tipePesanan,
        'catatan_pesanan': catatanPesanan,
        'alamat_pengiriman': ?alamatPengiriman,
        'latitude': ?latitude,
        'longitude': ?longitude,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentOrder = Pesanan.fromJson(data['data']['pesanan']);
        _checkoutPreview = null; // Clear preview
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Failed to process checkout';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// GET ORDER DETAIL
  Future<bool> getOrderDetail({
    required String token,
    required int pesananId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/pesanan/$pesananId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentOrder = Pesanan.fromJson(data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to fetch order detail';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Format currency untuk IDR
  static String formatCurrency(double amount) {
    return 'Rp${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }
}
