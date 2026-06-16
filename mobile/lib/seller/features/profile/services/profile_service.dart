import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/user_profile.dart';
import '../models/kantin_profile.dart';

class ProfileService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api',
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();
  static bool _interceptorAdded = false;

  // Add interceptor to include auth token (hanya sekali)
  static void _setupDio() {
    if (!_interceptorAdded) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            try {
              final token = await _getToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
                developer.log('Token added to request: Bearer ${token.substring(0, 20)}...');
              } else {
                developer.log('No token found');
              }
            } catch (e) {
              developer.log('Error adding token: $e');
            }
            return handler.next(options);
          },
          onError: (error, handler) {
            developer.log('Dio error: ${error.message}');
            if (error.response?.statusCode == 401) {
              developer.log('Unauthorized - Token may be invalid');
            }
            return handler.next(error);
          },
        ),
      );
      _interceptorAdded = true;
    }
  }

  static Future<String?> _getToken() async {
    try {
      final token = await _prefs.getString('auth_token');
      return token.isEmpty ? null : token;
    } catch (e) {
      developer.log('Error getting token: $e');
      return null;
    }
  }

  // Get user profile
  static Future<UserProfile> getProfile() async {
    _setupDio();
    try {
      developer.log('Fetching profile from /profile');
      final response = await _dio.get('/profile');

      developer.log('Profile response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final profileData = response.data['data'] as Map<String, dynamic>;
        developer.log('Profile data received: $profileData');
        return UserProfile.fromJson(profileData);
      }

      throw Exception(response.data['message'] ?? 'Gagal mengambil profil');
    } on DioException catch (exception) {
      developer.log('DioException: ${exception.message}, Response: ${exception.response?.statusCode}');
      if (exception.response != null) {
        final responseData = exception.response?.data;
        final message = responseData is Map<String, dynamic>
            ? responseData['message'] ?? exception.message
            : exception.message;
        throw Exception(message);
      }
      throw Exception('Tidak dapat terhubung dengan server: ${exception.message}');
    } catch (e) {
      developer.log('Unexpected error: $e');
      throw Exception('Error: $e');
    }
  }

  // Update user profile
  static Future<UserProfile> updateProfile({
    required String username,
    required String email,
    String? namaPemilik,
    String? noTelp,
    File? fotoProfil,
  }) async {
    _setupDio();
    try {
      developer.log('Updating profile');
      final formDataMap = <String, dynamic>{
        'username': username,
        'email': email,
      };
      // Always include optional fields so backend can update them
      formDataMap['nama_pemilik'] = namaPemilik ?? '';
      formDataMap['no_telp'] = noTelp ?? '';
      
      if (fotoProfil != null) {
        formDataMap['foto_profil'] = await MultipartFile.fromFile(
          fotoProfil.path,
          filename: fotoProfil.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(formDataMap);

      // Gunakan POST
      final response = await _dio.post('/profile', data: formData);

      developer.log('Update response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final profileData = response.data['data'] as Map<String, dynamic>;
        developer.log('Profile updated successfully');
        return UserProfile.fromJson(profileData);
      }

      throw Exception(response.data['message'] ?? 'Gagal memperbarui profil');
    } on DioException catch (exception) {
      // ... (kode error handling tetap sama seperti aslinya)
      developer.log('DioException on update: ${exception.message}, Status: ${exception.response?.statusCode}');
      if (exception.response != null) {
        final responseData = exception.response?.data;
        if (responseData is Map<String, dynamic> && responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values
              .whereType<List>()
              .expand((list) => list.cast<String>())
              .join(', ');
          throw Exception(errorMessages.isNotEmpty ? errorMessages : exception.message);
        }
        final message = responseData is Map<String, dynamic>
            ? responseData['message'] ?? exception.message
            : exception.message;
        throw Exception(message);
      }
      throw Exception('Tidak dapat terhubung dengan server: ${exception.message}');
    } catch (e) {
      developer.log('Unexpected error on update: $e');
      throw Exception('Error: $e');
    }
  }


  // Get kantin profile
  static Future<KantinProfile> getKantinProfile() async {
    _setupDio();
    try {
      final response = await _dio.get('/kantin/profile');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return KantinProfile.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal mengambil profil kantin');
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 404) {
        throw Exception('Kantin tidak ditemukan');
      }
      throw Exception(exception.message ?? 'Gagal mengambil profil kantin');
    }
  }

  // Update kantin profile
  static Future<KantinProfile> updateKantinProfile({
    required String namaKantin,
    File? fotoKantin,
  }) async {
    _setupDio();
    try {
      developer.log('Updating kantin profile');
      final formDataMap = <String, dynamic>{
        'nama_kantin': namaKantin,
      };
      
      if (fotoKantin != null) {
        formDataMap['foto_kantin'] = await MultipartFile.fromFile(
          fotoKantin.path,
          filename: fotoKantin.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(formDataMap);

      // Gunakan POST
      final response = await _dio.post('/kantin/profile', data: formData);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return KantinProfile.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Gagal memperbarui profil kantin');
    } on DioException catch (exception) {
      developer.log('DioException on kantin update: ${exception.message}');
      if (exception.response != null) {
        final responseData = exception.response?.data;
        final message = responseData is Map<String, dynamic>
            ? responseData['message'] ?? exception.message
            : exception.message;
        throw Exception(message);
      }
      throw Exception(exception.message ?? 'Gagal memperbarui profil kantin');
    }
  }

  // Change password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    _setupDio();
    try {
      developer.log('Changing password');
      
      if (newPassword != newPasswordConfirmation) {
        throw Exception('Password baru dan konfirmasi tidak sesuai');
      }

      final response = await _dio.put(
        '/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Gagal mengubah password');
      }

      developer.log('Password changed successfully');
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 401) {
        throw Exception('Password saat ini tidak sesuai');
      }
      throw Exception(exception.message ?? 'Gagal mengubah password');
    }
  }
}
