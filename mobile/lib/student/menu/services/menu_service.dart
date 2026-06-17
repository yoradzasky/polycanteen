import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

// ──────────────────────────────────────────────
// Service: MenuService
// ──────────────────────────────────────────────

class MenuService {
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;

  MenuService() {
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

  String get baseUrlForStorage {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
    return baseUrl.replaceAll(RegExp(r'/api$'), '').replaceAll(RegExp(r'/mobile$'), '');
  }

  // Helper untuk menyematkan token Sanctum ke Header
  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ───── GET /mahasiswa/kantin/{kantinId}/menu ─────
  Future<List<dynamic>> getMenuByKantin(int kantinId) async {
    try {
      final response = await _dio.get(
        '/mahasiswa/kantin/$kantinId/menu',
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

      // Cek jika Controller mereturn array JSON langsung
      if (body is List) {
        return body;
      }
      
      // Cek jika data dibungkus dalam key 'data' (misal menggunakan Resource API)
      if (body is Map && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      
      throw Exception('Format data menu tidak sesuai ekspektasi');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ───── GET /mahasiswa/keranjang ─────
  // Untuk mengambil data keranjang dari database saat halaman dibuka
  Future<List<dynamic>> getCartItems() async {
    try {
      final response = await _dio.get(
        '/mahasiswa/keranjang',
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

      // Sesuai dengan format response dari CartController (punya key 'data')
      if (body is Map && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      } else if (body is List) {
        return body;
      }
      
      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ───── POST /mahasiswa/keranjang ─────
  // Digunakan saat tombol (+) atau "Tambah ke Keranjang" diklik
  Future<void> addToCart({
    required int menuId, 
    required int jumlah, 
    Map? varianSelected, 
  }) async {
    try {
      await _dio.post(
        '/mahasiswa/keranjang',
        data: {
          'menu_id': menuId,
          'jumlah': jumlah,
          'varian_selected': varianSelected,
        },
        options: await _authOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ───── DELETE/PUT /mahasiswa/keranjang/{menuId} ─────
  // Digunakan saat tombol (-) diklik untuk mengurangi atau menghapus dari keranjang
  Future<void> decreaseCartQty(int menuId) async {
    try {
      // Sesuaikan endpoint ini dengan rute di backend Laravel kamu nanti
      await _dio.delete(
        '/mahasiswa/keranjang/$menuId',
        options: await _authOptions(),
      );
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