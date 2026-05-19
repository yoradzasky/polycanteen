import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────────
// Model: Menu
// ──────────────────────────────────────────────

class Menu {
  final int id;
  final String namaItem;
  final int harga;
  final String? fotoMenu;
  final String statusStok;
  final String kategori;
  final String? deskripsi;
  final int? estimasiWaktu;
  final List<String>? pilihanLayanan;
  final List<Map<String, dynamic>>? varian;
  final List<dynamic>? topping;

  Menu({
    required this.id,
    required this.namaItem,
    required this.harga,
    this.fotoMenu,
    required this.statusStok,
    required this.kategori,
    this.deskripsi,
    this.estimasiWaktu,
    this.pilihanLayanan,
    this.varian,
    this.topping,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse stringified JSON or direct List
    List<dynamic>? parseJsonList(dynamic field) {
      if (field == null) return null;
      if (field is String) {
        try {
          return jsonDecode(field) as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      if (field is List) return field;
      return null;
    }

    final varList = parseJsonList(json['varian']);
    final layList = parseJsonList(json['pilihan_layanan']);
    final topList = parseJsonList(json['topping']);

    return Menu(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      namaItem: (json['nama_item'] ?? '').toString(),
      harga: json['harga'] is int
          ? json['harga']
          : json['harga'] is double
              ? (json['harga'] as double).toInt()
              : int.tryParse(json['harga'].toString().split('.').first) ?? 0,
      fotoMenu: json['foto_menu']?.toString(),
      statusStok: json['status_stok_label']?.toString() ??
          (json['status_stok'] == true || json['status_stok'] == 1 ? 'tersedia' : 'habis'),
      kategori: (json['kategori'] ?? '').toString(),
      deskripsi: json['deskripsi']?.toString(),
      estimasiWaktu: json['estimasi_waktu'] != null
          ? (json['estimasi_waktu'] is int
              ? json['estimasi_waktu']
              : int.tryParse(json['estimasi_waktu'].toString()))
          : null,
      pilihanLayanan: layList != null ? List<String>.from(layList.map((e) => e.toString())) : null,
      varian: varList != null
          ? List<Map<String, dynamic>>.from(
              varList.map((e) => Map<String, dynamic>.from(e)),
            )
          : null,
      topping: topList,
    );
  }
}

// ──────────────────────────────────────────────
// Model: MenuFormData (untuk add / edit)
// ──────────────────────────────────────────────

class MenuFormData {
  final String namaItem;
  final int harga;
  final String kategori;
  final List<String> pilihanLayanan;
  final String? deskripsi;
  final int? estimasiWaktu;
  final File? fotoMenu;
  final List<Map<String, dynamic>>? varian;
  final List<dynamic>? topping;

  MenuFormData({
    required this.namaItem,
    required this.harga,
    required this.kategori,
    required this.pilihanLayanan,
    this.deskripsi,
    this.estimasiWaktu,
    this.fotoMenu,
    this.varian,
    this.topping,
  });
}

// ──────────────────────────────────────────────
// Service: MenuService
// ──────────────────────────────────────────────

class MenuService {
  late final Dio _dio;
  late final String _storageBase;

  MenuService() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api';
    // Strip trailing /mobile if present so we can append /seller/menus
    final cleanBase = baseUrl.replaceAll(RegExp(r'/mobile$'), '');

    _dio = Dio(BaseOptions(
      baseUrl: cleanBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));

    // For building storage URLs: strip /api from the base
    _storageBase = cleanBase.replaceAll(RegExp(r'/api$'), '');
  }

  /// Base URL without /api, for building storage photo URLs
  String get baseUrlForStorage => _storageBase;

  /// Ambil token dari SharedPreferences dan set di header
  Future<Options> _authOptions({String? contentType}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return Options(
      headers: {'Authorization': 'Bearer $token'},
      contentType: contentType,
    );
  }

  // ───── GET  /seller/menus ─────
  Future<List<Menu>> getMenus({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get(
        '/pemilik/menus',
        queryParameters: queryParams,
        options: await _authOptions(),
      );

      var body = response.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Server mengembalikan respons tidak valid (bukan JSON). Pastikan token Sanctum sudah benar.');
        }
      }
      
      if (body['success'] == true) {
        final list = body['data'] as List;
        return list.map((e) => Menu.fromJson(e)).toList();
      }
      throw Exception((body['message'] ?? 'Gagal mengambil data menu').toString());
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg;
      if (data is Map && data.containsKey('message')) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      } else {
        msg = 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
      }
      throw Exception(msg);
    }
  }

  // ───── POST  /seller/menus ─────
  Future<void> addMenu(MenuFormData data) async {
    try {
      final formMap = <String, dynamic>{
        'nama_item': data.namaItem,
        'harga': data.harga,
        'kategori': data.kategori,
      };

      // Kirim pilihan_layanan sebagai array terpisah agar Laravel menerimanya sebagai array
      for (int i = 0; i < data.pilihanLayanan.length; i++) {
        formMap['pilihan_layanan[$i]'] = data.pilihanLayanan[i];
      }

      if (data.deskripsi != null && data.deskripsi!.isNotEmpty) {
        formMap['deskripsi'] = data.deskripsi;
      }
      if (data.estimasiWaktu != null) {
        formMap['estimasi_waktu'] = data.estimasiWaktu;
      }
      if (data.varian != null && data.varian!.isNotEmpty) {
        formMap['varian'] = jsonEncode(data.varian);
      }
      if (data.topping != null && data.topping!.isNotEmpty) {
        formMap['topping'] = jsonEncode(data.topping);
      }
      if (data.fotoMenu != null) {
        formMap['foto_menu'] = await MultipartFile.fromFile(
          data.fotoMenu!.path,
          filename: data.fotoMenu!.path.split(Platform.pathSeparator).last,
        );
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post(
        '/pemilik/menus',
        data: formData,
        options: await _authOptions(contentType: 'multipart/form-data'),
      );

      var body = response.data;
      if (body is String) {
        try { body = jsonDecode(body); } catch (_) { throw Exception('Respons bukan JSON. Pastikan token valid.'); }
      }
      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Gagal menambahkan menu');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg;
      if (data is Map && data.containsKey('message')) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      } else {
        msg = 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
      }
      throw Exception(msg);
    }
  }

  // ───── PUT  /seller/menus/{id} ─────
  Future<void> updateMenu(int menuId, MenuFormData data) async {
    try {
      final formMap = <String, dynamic>{
        'nama_item': data.namaItem,
        'harga': data.harga,
        'kategori': data.kategori,
      };

      // Kirim pilihan_layanan sebagai array terpisah agar Laravel menerimanya sebagai array
      for (int i = 0; i < data.pilihanLayanan.length; i++) {
        formMap['pilihan_layanan[$i]'] = data.pilihanLayanan[i];
      }

      if (data.deskripsi != null) {
        formMap['deskripsi'] = data.deskripsi;
      }
      if (data.estimasiWaktu != null) {
        formMap['estimasi_waktu'] = data.estimasiWaktu;
      }
      if (data.varian != null) {
        formMap['varian'] = jsonEncode(data.varian);
      }
      if (data.topping != null) {
        formMap['topping'] = jsonEncode(data.topping);
      }
      if (data.fotoMenu != null) {
        formMap['foto_menu'] = await MultipartFile.fromFile(
          data.fotoMenu!.path,
          filename: data.fotoMenu!.path.split(Platform.pathSeparator).last,
        );
      }

      // Laravel requires _method override for PUT with multipart
      formMap['_method'] = 'PUT';
      final formData = FormData.fromMap(formMap);

      final response = await _dio.post(
        '/pemilik/menus/$menuId',
        data: formData,
        options: await _authOptions(contentType: 'multipart/form-data'),
      );

      var body = response.data;
      if (body is String) {
        try { body = jsonDecode(body); } catch (_) { throw Exception('Respons bukan JSON. Pastikan token valid.'); }
      }
      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Gagal memperbarui menu');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg;
      if (data is Map && data.containsKey('message')) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      } else {
        msg = 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
      }
      throw Exception(msg);
    }
  }

  // ───── DELETE  /seller/menus/{id} ─────
  Future<void> deleteMenu(int menuId) async {
    try {
      final response = await _dio.delete(
        '/pemilik/menus/$menuId',
        options: await _authOptions(),
      );

      var body = response.data;
      if (body is String) {
        try { body = jsonDecode(body); } catch (_) { throw Exception('Respons bukan JSON. Pastikan token valid.'); }
      }
      if (body['success'] != true) {
        throw Exception(body['message'] ?? 'Gagal menghapus menu');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg;
      if (data is Map && data.containsKey('message')) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      } else {
        msg = 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
      }
      throw Exception(msg);
    }
  }

  // ───── PATCH  /seller/menus/{id}/toggle-status ─────
  Future<Menu> toggleMenuStatus(int menuId) async {
    try {
      final response = await _dio.patch(
        '/pemilik/menus/$menuId/toggle-status',
        options: await _authOptions(),
      );

      var body = response.data;
      if (body is String) {
        try { body = jsonDecode(body); } catch (_) { throw Exception('Respons bukan JSON.'); }
      }
      if (body['success'] == true) {
        return Menu.fromJson(body['data']);
      }
      throw Exception(body['message'] ?? 'Gagal mengubah status stok');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg;
      if (data is Map && data.containsKey('message')) {
        msg = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      } else {
        msg = 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
      }
      throw Exception(msg);
    }
  }
}
