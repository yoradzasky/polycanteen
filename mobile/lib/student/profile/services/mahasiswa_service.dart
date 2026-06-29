import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

// ──────────────────────────────────────────────
// Service: MahasiswaService
// ──────────────────────────────────────────────

class MahasiswaService {
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  late final Dio _dio;

  MahasiswaService() {
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
    return baseUrl
        .replaceAll(RegExp(r'/api$'), '')
        .replaceAll(RegExp(r'/mobile$'), '');
  }

  // Helper untuk menyematkan token Sanctum ke Header
  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ───── GET /mahasiswa/profil ─────
  Future<Map<String, dynamic>> getProfileData() async {
    try {
      final response = await _dio.get(
        '/mahasiswa/profil',
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
        return body['data'] as Map<String, dynamic>;
      }

      throw Exception(body['message'] ?? 'Gagal mengambil data profil');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // Helper untuk parsing error Dio
  String _handleDioError(DioException e) {
    final data = e.response?.data;

    if (data is Map) {
      // 1. Cek apakah Laravel mengirimkan detail array 'errors' (Validasi gagal)
      if (data.containsKey('errors')) {
        final errors = data['errors'] as Map<String, dynamic>;
        List<String> errorMessages = [];

        // Gabungkan semua pesan error spesifik menjadi satu paragraf
        errors.forEach((key, value) {
          if (value is List) {
            errorMessages.add(value.join(', '));
          }
        });
        return errorMessages.join('\n'); // Pisahkan dengan baris baru (enter)
      }

      // 2. Jika tidak ada array 'errors', ambil pesan umum 'message'
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }

    return 'Terjadi kesalahan jaringan (Kode: ${e.response?.statusCode})';
  }

  // ───── POST /mahasiswa/profil/update ─────
  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String nim,
    required String jurusan,
    required String telp,
    required String email,
    File?
    fotoFile, // File bersifat opsional (jika user tidak ganti foto, tetap null)
  }) async {
    try {
      // 1. Persiapkan data teks dalam Map
      Map<String, dynamic> data = {
        'nama_mahasiswa': nama,
        'nim': nim,
        'jurusan': jurusan,
        'no_telp': telp,
        'email': email,
      };

      // 2. Jika user memilih foto baru, tambahkan ke FormData sebagai MultipartFile
      if (fotoFile != null) {
        String fileName = fotoFile.path.split('/').last;
        data['foto_profile'] = await MultipartFile.fromFile(
          fotoFile.path,
          filename: fileName,
        );
      }

      // 3. Konversi Map menjadi FormData (wajib untuk kirim file)
      FormData formData = FormData.fromMap(data);

      // 4. Kirim request ke Laravel
      final response = await _dio.post(
        '/mahasiswa/profil/update',
        data: formData,
        options: await _authOptions(),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
}
