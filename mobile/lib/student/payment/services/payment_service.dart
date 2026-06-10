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
      Uri.parse('$_baseUrl/student/payment/$pesananId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Jika token kosong, tetap kirim string kosong agar tidak error null
        'Authorization': 'Bearer ${token.isNotEmpty ? token : ''}', 
      },
      body: jsonEncode({
        'payment_type': ?paymentType,
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
}