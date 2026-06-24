import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

class OrderService {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();

  Future<Map<String, dynamic>> getOrderDetail(int pesananId) async {
    final token = await _prefs.getString('auth_token');
    // Using student/payment/status/{id} (GET) which returns payment status and order details.
    final response = await http.get(
      Uri.parse('$_baseUrl/student/payment/status/$pesananId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    } else if (response.statusCode == 404) {
      throw Exception('Route API tidak ditemukan (404). Pastikan backend student/payment/{id} sudah ada.');
    } else {
      throw Exception('Gagal mengambil detail pesanan (Status: ${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>?> getLatestPendingOrder() async {
    final token = await _prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('$_baseUrl/student/orders/latest-pending'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    }
    return null;
  }

  Future<Map<String, dynamic>> submitOrder(
    int pesananId, {
    required String tipePesanan,
    String? alamatPengantaran,
    double? destLat,
    double? destLng,
    String? catatanPesanan,
  }) async {
    final token = await _prefs.getString('auth_token');
    final response = await http.patch(
      Uri.parse('$_baseUrl/student/orders/$pesananId/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}',
      },
      body: jsonEncode({
        'tipe_pesanan': tipePesanan,
        'alamat_pengantaran': alamatPengantaran,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'catatan_pesanan': catatanPesanan,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal mengajukan pesanan');
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int pesananId) async {
    final token = await _prefs.getString('auth_token');
    final response = await http.patch(
      Uri.parse('$_baseUrl/student/orders/$pesananId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal membatalkan pesanan');
    }
  }
}
