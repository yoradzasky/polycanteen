import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

// ──────────────────────────────────────────────
// Service: CanteenListService
// ──────────────────────────────────────────────

class CanteenListService {
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;

  CanteenListService() {
    // Mengambil BASE_URL dari .env
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

  // URL dasar untuk mengambil gambar/logo dari storage Laravel
  String get baseUrlForStorage {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
    return baseUrl.replaceAll(RegExp(r'/api$'), '').replaceAll(RegExp(r'/mobile$'), '');
  }

  // Helper untuk menyematkan token Sanctum ke Header
  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ───── GET /student/kantin ─────
  Future<List<dynamic>> getKantinList() async {
    try {
      final response = await _dio.get(
        '/student/kantin',
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

      // Controller mereturn array JSON langsung, jadi kita cek apakah body berupa List
      if (body is List) {
        return body;
      }
      
      // Jika strukturnya tiba-tiba berubah (misal dari wrapper middleware), tangani di sini
      if (body is Map && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      
      throw Exception('Format data kantin tidak sesuai ekspektasi');
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