import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- SERVICE ---
class FinanceService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  Future<Map<String, dynamic>> getFinanceSummary() async {
    final prefs = EncryptedSharedPreferences();
    final token = await prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/pemilik/finance/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('Akses Ditolak. Fitur ini hanya untuk Pemilik.');
    } else {
      throw Exception('Gagal memuat ringkasan keuangan');
    }
  }

  Future<List<dynamic>> getFinanceHistory() async {
    final prefs = EncryptedSharedPreferences();
    final token = await prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/pemilik/finance/history'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Gagal memuat riwayat transaksi');
    }
  }
}

// --- PROVIDER (STATE MANAGEMENT) ---
class FinanceProvider with ChangeNotifier {
  final FinanceService _financeService = FinanceService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _summary;
  Map<String, dynamic>? get summary => _summary;

  List<dynamic> _history = [];
  List<dynamic> get history => _history;

  Future<void> fetchFinanceData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryResponse = await _financeService.getFinanceSummary();
      _summary = summaryResponse['data'];

      final historyResponse = await _financeService.getFinanceHistory();
      _history = historyResponse;

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
