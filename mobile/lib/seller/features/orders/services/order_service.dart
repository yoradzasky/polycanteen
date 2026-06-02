import 'dart:convert'; // Jangan lupa tambahkan ini untuk jsonDecode
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

// ──────────────────────────────────────────────
// Service: OrderService
// ──────────────────────────────────────────────

class OrderService {
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;

  OrderService() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.22:8000/api';
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

  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ───── GET /pemilik/orders ─────
  Future<Map<String, dynamic>> getOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/pemilik/orders',
        queryParameters: queryParams,
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

      if (body['success'] == true) {
        return body as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Gagal mengambil data pesanan');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ───── GET /pemilik/orders/{id} ─────
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      final response = await _dio.get(
        '/pemilik/orders/$orderId',
        options: await _authOptions(),
      );

      var body = response.data;
      // PELINDUNG
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Respons server tidak valid.');
        }
      }

      if (body['success'] == true) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body['message'] ?? 'Gagal mengambil detail pesanan');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ───── PATCH /pemilik/orders/{id}/status ─────
  Future<void> updateOrderStatus(
    int orderId,
    String status, {
    String? alasanPenolakan,
  }) async {
    try {
      final data = <String, dynamic>{'status_pesanan': status};

      // Karena fitur ini kita hold, kita biarkan logicnya tetap ada tapi nanti jgn dipanggil dulu
      if (alasanPenolakan != null) {
        data['alasan_penolakan'] = alasanPenolakan;
      }

      final response = await _dio.patch(
        '/pemilik/orders/$orderId/status',
        data: data,
        options: await _authOptions(),
      );

      var body = response.data;
      // PELINDUNG
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Respons server tidak valid.');
        }
      }

      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Gagal mengupdate status pesanan');
      }
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

  // ───── PATCH /pemilik/kantin/status ─────
  Future<void> updateStatusKantin(String statusToko) async {
    try {
      final response = await _dio.patch(
        '/pemilik/kantin/status',
        data: {'status_toko': statusToko},
        options: await _authOptions(),
      );

      var body = response.data;
      // PELINDUNG
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Respons server tidak valid.');
        }
      }

      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Gagal mengupdate status kantin');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
}
