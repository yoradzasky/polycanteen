import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

class AuthService {
  static final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api',
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        final token = data['data']?['token'] as String?;
        if (token == null || token.isEmpty) {
          throw Exception('Token tidak ditemukan di respons API.');
        }

        await _saveToken(token);
        return token;
      }

      throw Exception(data['message'] ?? 'Login gagal.');
    } on DioException catch (exception) {
      if (exception.response != null) {
        final responseData = exception.response?.data;
        final message = responseData is Map<String, dynamic>
            ? responseData['message'] ?? exception.message
            : exception.message;
        throw Exception(message);
      }
      throw Exception('Tidak dapat terhubung dengan server.');
    }
  }

  static Future<void> _saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final token = await _prefs.getString('auth_token');
    return token.isEmpty ? null : token;
  }

  static Future<void> logout() async {
    try {
      // Ambil token dari storage lokal
      final token = await getToken();
      final role = await _prefs.getString('user_role');

      if (token != null) {
        String logoutUrl = '/logout';
        if (role == 'pemilik') {
          logoutUrl = '/penjual/logout';
        } else if (role == 'mahasiswa') {
          logoutUrl = '/mahasiswa/logout';
        }

        // Tembak API logout Laravel
        await _dio.post(
          logoutUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );
      }
    } catch (e) {
      // Abaikan jika terjadi error dari server (misal tidak ada koneksi internet).
      // Yang terpenting proses di blok finally tetap berjalan.
    } finally {
      // Selalu pastikan token dan role dihapus dari HP, apa pun balasan dari server
      await _prefs.remove('auth_token');
      await _prefs.remove('user_role');
    }
  }
}
