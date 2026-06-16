import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

// ──────────────────────────────────────────────
// Service: HomeService
// ──────────────────────────────────────────────

class HomeService {
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;

  HomeService() {
    // Mengambil BASE_URL dari .env (contoh: http://192.168.1.14:8000/api)
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
    final cleanBase = baseUrl.replaceAll(RegExp(r'/mobile$'), '');

    _dio = Dio(
      BaseOptions(
        baseUrl: cleanBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  String get baseUrlForStorage {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
    return baseUrl.replaceAll(RegExp(r'/api$'), '').replaceAll(RegExp(r'/mobile$'), '');
  }

  // Helper untuk menyematkan token Sanctum ke Header
  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ───── GET /student/beranda ─────
  Future<Map<String, dynamic>> getBerandaData() async {
    try {
      final response = await _dio.get(
        '/student/beranda',
        options: await _authOptions(),
      );

      var body = response.data;
      
      // PELINDUNG: Jika response terbaca sebagai String, paksa jadi JSON
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Respons server tidak valid.');
        }
      }

      // Mengecek key 'status' sesuai dengan return JSON dari MahasiswaController
      if (body['status'] == 'success') {
        return body as Map<String, dynamic>;
      }
      
      throw Exception(body['message'] ?? 'Gagal mengambil data beranda');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Helper untuk parsing error Dio
  String _handleDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('message')) {
      return data['message'].toString();
    }
    return 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
  }
}