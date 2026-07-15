import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

class PaymentService {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  
  // 2. Inisialisasi EncryptedSharedPreferences
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();

  Future<Map<String, dynamic>> createPayment(int pesananId, {String? paymentType}) async {
    // 3. Ambil token dari storage yang terenkripsi
    final token = await _prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$_baseUrl/mahasiswa/payment/$pesananId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Jika token kosong, tetap kirim string kosong agar tidak error null
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}', 
      },
      body: jsonEncode({
        'payment_type': paymentType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Menambahkan log detail error untuk debugging
      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');
      
      String message = 'Gagal membuat token pembayaran';
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['message'] ?? message;
      } catch (_) {}
      
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(int pesananId) async {
    final token = await _prefs.getString('auth_token');
    // Using mahasiswa/payment/status/{id} as the target endpoint.
    // Note: If this returns 404, it means the backend route is not yet implemented.
    final response = await http.get(
      Uri.parse('$_baseUrl/mahasiswa/payment/status/$pesananId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Log for debugging
      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');
      
      // Return the status code so the UI can decide what to do
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': 'Gagal mengambil status pembayaran',
      };
    }
  }
}