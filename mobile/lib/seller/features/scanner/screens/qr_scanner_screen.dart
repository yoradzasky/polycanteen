import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ──────────────────────────────────────────────
// Warna utama
// ──────────────────────────────────────────────
const Color _kPrimaryIndigo = Color(0xFF3D3DBF);
const Color _kAccentAmber = Color(0xFFF5A623);
const Color _kBackgroundLight = Color(0xFFF0F2FF);

/// Layar utama scanner QR untuk sisi penjual (pegawai / pemilik).
///
/// Flow:
///   1. Scanning  → kamera aktif, card kosong
///   2. Loading   → loading indicator
///   3. Detected  → data pesanan tampil di card
///   4. Confirmed → snackbar sukses → reset ke scanning
///   5. Error     → snackbar error
class QrScannerScreen extends StatefulWidget {
  final bool returnMode;
  const QrScannerScreen({super.key, this.returnMode = false});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  // ── Scanner ──
  late MobileScannerController _cameraController;

  // ── Scan‑line animation ──
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  // ── State ──
  bool _isLoading = false;
  bool _isDetected = false;
  bool _isConfirming = false;
  Map<String, dynamic>? _orderData;

  // ── API ──
  late final Dio _dio;
  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();

  // Untuk mencegah scan ganda
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
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

  @override
  void dispose() {
    _cameraController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  Future<Options> _authOptions() async {
    final token = await _prefs.getString('auth_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Panggil POST /penjual/scanner/verify
  Future<void> _verifyQr(String qrData) async {
    setState(() {
      _isLoading = true;
      _isDetected = false;
      _orderData = null;
    });

    try {
      final response = await _dio.post(
        '/penjual/scanner/verify',
        data: {'qr_data': qrData},
        options: await _authOptions(),
      );

      var body = response.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Respons server tidak valid.');
        }
      }

      if (body['success'] == true) {
        setState(() {
          _orderData = body['data'] as Map<String, dynamic>;
          _isDetected = true;
        });
      } else {
        _showError(body['message'] ?? 'Gagal memverifikasi QR');
        _resetScanner();
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data.containsKey('message'))
          ? data['message'].toString()
          : 'Terjadi kesalahan jaringan (${e.response?.statusCode})';
      _showError(msg);
      _resetScanner();
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
      _resetScanner();
    } finally {
      setState(() => _isLoading = false);
      _isProcessing = false;
    }
  }

  /// Panggil POST /penjual/scanner/confirm
  Future<void> _confirmOrder() async {
    if (_orderData == null || _isConfirming) return;

    setState(() => _isConfirming = true);

    try {
      final response = await _dio.post(
        '/penjual/scanner/confirm',
        data: {'pesanan_id': _orderData!['pesanan_id']},
        options: await _authOptions(),
      );

      var body = response.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          throw Exception('Respons server tidak valid.');
        }
      }

      if (body['success'] == true) {
        _showSuccess(body['message'] ?? 'Pesanan berhasil dikonfirmasi');
        _resetScanner();
      } else {
        _showError(body['message'] ?? 'Gagal mengkonfirmasi pesanan');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data.containsKey('message'))
          ? data['message'].toString()
          : 'Terjadi kesalahan jaringan (${e.response?.statusCode})';
      _showError(msg);
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isConfirming = false);
    }
  }

  void _resetScanner() {
    setState(() {
      _isDetected = false;
      _orderData = null;
      _isProcessing = false;
    });
    _cameraController.start();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background for camera
      body: Stack(
        children: [
          // ─── Kamera + scanner (Background) ───
          Positioned.fill(
            child: _buildCameraSection(),
          ),

          // ─── BOTTOM: Result card + buttons (Draggable) ───
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return _buildResultSection(scrollController);
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // TOP SECTION — Camera / QR Scanner area
  // ════════════════════════════════════════════════
  Widget _buildCameraSection() {
    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _cameraController,
          onDetect: _onBarcodeDetected,
        ),

        // Dark overlay with transparent cutout
        _ScannerOverlay(animation: _scanAnimation),

        // App bar
        _buildAppBar(),

        // "Mendeteksi kode..." text
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: _buildScanningStatusText(),
        ),
      ],
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || _isDetected || _isLoading) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _isProcessing = true;
    _cameraController.stop();

    if (widget.returnMode) {
      Navigator.pop(context, rawValue);
      return;
    }

    _verifyQr(rawValue);
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 4,
          right: 4,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _kPrimaryIndigo.withValues(alpha: 0.95),
              _kPrimaryIndigo.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
            const Text(
              'Scan QR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            IconButton(
              onPressed: () => _cameraController.toggleTorch(),
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: _cameraController,
                builder: (_, state, _) {
                  final torchState = state.torchState;
                  return Icon(
                    torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: torchState == TorchState.on
                        ? _kAccentAmber
                        : Colors.white,
                    size: 24,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningStatusText() {
    if (_isDetected || _isLoading) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _amberDot(),
        _amberDot(),
        const SizedBox(width: 10),
        const Text(
          'Mendeteksi kode...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        _amberDot(),
        _amberDot(),
      ],
    );
  }

  Widget _amberDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: _kAccentAmber,
        shape: BoxShape.circle,
      ),
    );
  }

  // ════════════════════════════════════════════════
  // BOTTOM SECTION — Result card + action buttons
  // ════════════════════════════════════════════════
  Widget _buildResultSection(ScrollController scrollController) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kBackgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: _isLoading ? _buildLoadingState() : _buildResultContent(scrollController),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kPrimaryIndigo),
          SizedBox(height: 16),
          Text(
            'Memverifikasi pesanan...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Result card
          _buildResultCard(),

          const SizedBox(height: 20),

          // Action buttons (hanya muncul kalau sudah terdeteksi)
          if (_isDetected && _orderData != null) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryIndigo.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isDetected && _orderData != null
          ? _buildDetectedCard()
          : _buildEmptyCard(),
    );
  }

  // ── Empty / placeholder state ──
  Widget _buildEmptyCard() {
    return Column(
      children: [
        Icon(Icons.qr_code_scanner_rounded,
            size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          'Arahkan kamera ke QR Code pesanan',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Detected / populated state ──
  Widget _buildDetectedCard() {
    final data = _orderData!;

    final pesananId = data['pesanan_id'];
    final nomorAntrian = data['nomor_antrian'] ?? '-';
    final namaPembeli = data['nama_pembeli'] ?? '-';
    final totalHarga =
        (double.tryParse(data['total_harga'].toString()) ?? 0).toInt();
    final statusPesanan = data['status_pesanan'] ?? '-';
    final tipePesanan = data['tipe_pesanan'] ?? '-';
    final catatan = data['catatan_pesanan'] ?? '';
    final details = data['details'] as List<dynamic>? ?? [];

    // Map order type colors
    Color typeColor = Colors.grey;
    Color typeBgColor = Colors.grey.shade100;
    if (tipePesanan.toLowerCase().contains('dine in') ||
        tipePesanan.toLowerCase().contains('makan di tempat')) {
      typeColor = const Color(0xFF27AE60);
      typeBgColor = const Color(0xFFE8F5E9);
    } else if (tipePesanan.toLowerCase().contains('take away') ||
        tipePesanan.toLowerCase().contains('bungkus')) {
      typeColor = const Color(0xFFF2994A);
      typeBgColor = const Color(0xFFFFF3F0);
    } else if (tipePesanan.toLowerCase().contains('delivery') ||
        tipePesanan.toLowerCase().contains('pengantaran')) {
      typeColor = const Color(0xFF2F80ED);
      typeBgColor = const Color(0xFFE3F2FD);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pill badge "Pesanan Terdeteksi" ──
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimaryIndigo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Pesanan Terdeteksi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Order number ──
        Center(
          child: Text(
            '#ORD-$pesananId',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // ── Queue number ──
        Center(
          child: Text(
            'Antrian: $nomorAntrian',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade200, thickness: 1),
        const SizedBox(height: 12),

        // ── Tipe Pesanan row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tipe Pesanan',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tipePesanan.toUpperCase(),
                style: TextStyle(
                  color: typeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Pembeli row ──
        _buildInfoRow(
          icon: Icons.person_outline_rounded,
          label: 'Pembeli',
          value: namaPembeli,
        ),

        const SizedBox(height: 16),

        // ── Status row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status Pesanan',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kPrimaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: _kPrimaryIndigo),
                  const SizedBox(width: 6),
                  Text(
                    _mapStatusLabel(statusPesanan),
                    style: const TextStyle(
                      color: _kPrimaryIndigo,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade200, thickness: 1),
        const SizedBox(height: 16),

        // ── Item Pesanan (Rincian) ──
        const Text(
          'Rincian Menu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),

        // List item details
        ...List.generate(details.length, (idx) {
          final item = details[idx];
          final namaMenu = item['menu']?['nama_item'] ?? 'Item';
          final qty = int.tryParse(item['jumlah_pesanan']?.toString() ?? '1') ?? 1;
          final hargaSatuan = (double.tryParse(item['harga_saat_beli']?.toString() ?? '0') ?? 0).toInt();
          final hasVarian = item['varian_snapshot'] != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kBackgroundLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${qty}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: _kPrimaryIndigo,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaMenu,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (hasVarian) ...[
                        const SizedBox(height: 2),
                        const Text(
                          '• Memiliki varian',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(hargaSatuan * qty)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          );
        }),

        // ── Catatan Pembeli ──
        if (catatan.toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF2994A).withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Color(0xFFF2994A), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Catatan: "$catatan"',
                    style: const TextStyle(
                      color: Color(0xFFF2994A),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade200, thickness: 1),
        const SizedBox(height: 16),

        // ── Total Pembayaran ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Pembayaran',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF828282),
                fontSize: 13,
              ),
            ),
            Text(
              'Rp ${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
              style: const TextStyle(
                color: _kPrimaryIndigo,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kBackgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _kPrimaryIndigo, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _mapStatusLabel(String status) {
    switch (status) {
      case 'dibayar':
        return 'Menunggu Konfirmasi';
      case 'diproses':
        return 'Sedang Diproses';
      case 'dimasak':
        return 'Sedang Dimasak';
      case 'siap_diambil':
        return 'Siap Diambil';
      case 'menunggu_dikirim':
        return 'Menunggu Dikirim';
      case 'dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
  }

  // ── Action Buttons ──
  Widget _buildActionButtons() {
    final status = _orderData?['status_pesanan'] ?? '';
    final canConfirm = [
      'dibayar',
      'dikonfirmasi',
      'diproses',
      'dimasak',
      'siap_diambil',
      'dalam_perjalanan',
      'menunggu_dikirim'
    ].contains(status);

    return Column(
      children: [
        // Primary button — Konfirmasi Pesanan
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canConfirm && !_isConfirming ? _confirmOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccentAmber,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isConfirming
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Konfirmasi Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary button — Scan Ulang
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _resetScanner,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimaryIndigo,
              side: const BorderSide(color: _kPrimaryIndigo, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Scan Ulang',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════
// Custom Painter: scanner overlay + corner brackets + scan line
// ════════════════════════════════════════════════

class _ScannerOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _ScannerOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ScannerOverlayPainter(
            scanLineProgress: animation.value,
          ),
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanLineProgress;

  _ScannerOverlayPainter({required this.scanLineProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Scan frame dimensions
    final double frameSize = math.min(size.width, size.height) * 0.6;
    final double left = (size.width - frameSize) / 2;
    final double top = (size.height - frameSize) / 2 - 20;
    final Rect frameRect =
        Rect.fromLTWH(left, top, frameSize, frameSize);

    // ── 1. Dark overlay with transparent cutout ──
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Draw surrounding rectangles
    // Top
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, frameRect.top), overlayPaint);
    // Bottom
    canvas.drawRect(
        Rect.fromLTWH(0, frameRect.bottom, size.width, size.height - frameRect.bottom),
        overlayPaint);
    // Left
    canvas.drawRect(
        Rect.fromLTWH(0, frameRect.top, frameRect.left, frameSize),
        overlayPaint);
    // Right
    canvas.drawRect(
        Rect.fromLTWH(frameRect.right, frameRect.top,
            size.width - frameRect.right, frameSize),
        overlayPaint);

    // ── 2. Corner brackets ──
    final cornerPaint = Paint()
      ..color = _kAccentAmber
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 28;
    const double radius = 8;

    // Top-left corner
    final topLeftPath = Path()
      ..moveTo(frameRect.left, frameRect.top + cornerLength)
      ..lineTo(frameRect.left, frameRect.top + radius)
      ..quadraticBezierTo(
          frameRect.left, frameRect.top, frameRect.left + radius, frameRect.top)
      ..lineTo(frameRect.left + cornerLength, frameRect.top);
    canvas.drawPath(topLeftPath, cornerPaint);

    // Top-right corner
    final topRightPath = Path()
      ..moveTo(frameRect.right - cornerLength, frameRect.top)
      ..lineTo(frameRect.right - radius, frameRect.top)
      ..quadraticBezierTo(frameRect.right, frameRect.top, frameRect.right,
          frameRect.top + radius)
      ..lineTo(frameRect.right, frameRect.top + cornerLength);
    canvas.drawPath(topRightPath, cornerPaint);

    // Bottom-left corner
    final bottomLeftPath = Path()
      ..moveTo(frameRect.left, frameRect.bottom - cornerLength)
      ..lineTo(frameRect.left, frameRect.bottom - radius)
      ..quadraticBezierTo(frameRect.left, frameRect.bottom,
          frameRect.left + radius, frameRect.bottom)
      ..lineTo(frameRect.left + cornerLength, frameRect.bottom);
    canvas.drawPath(bottomLeftPath, cornerPaint);

    // Bottom-right corner
    final bottomRightPath = Path()
      ..moveTo(frameRect.right - cornerLength, frameRect.bottom)
      ..lineTo(frameRect.right - radius, frameRect.bottom)
      ..quadraticBezierTo(frameRect.right, frameRect.bottom, frameRect.right,
          frameRect.bottom - radius)
      ..lineTo(frameRect.right, frameRect.bottom - cornerLength);
    canvas.drawPath(bottomRightPath, cornerPaint);

    // ── 3. QR placeholder icon (faint) ──
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double iconSize = frameSize * 0.3;
    final double iconLeft = frameRect.center.dx - iconSize / 2;
    final double iconTop = frameRect.center.dy - iconSize / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(iconLeft, iconTop, iconSize, iconSize),
        const Radius.circular(4),
      ),
      iconPaint,
    );
    // Inner grid lines for QR look
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final third = iconSize / 3;
    canvas.drawLine(Offset(iconLeft + third, iconTop),
        Offset(iconLeft + third, iconTop + iconSize), gridPaint);
    canvas.drawLine(Offset(iconLeft + 2 * third, iconTop),
        Offset(iconLeft + 2 * third, iconTop + iconSize), gridPaint);
    canvas.drawLine(Offset(iconLeft, iconTop + third),
        Offset(iconLeft + iconSize, iconTop + third), gridPaint);
    canvas.drawLine(Offset(iconLeft, iconTop + 2 * third),
        Offset(iconLeft + iconSize, iconTop + 2 * third), gridPaint);

    // ── 4. Animated scan line ──
    final scanY = frameRect.top + (frameSize * scanLineProgress);

    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _kAccentAmber.withValues(alpha: 0.0),
          _kAccentAmber.withValues(alpha: 0.8),
          _kAccentAmber.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(frameRect.left + 8, scanY, frameSize - 16, 2),
      )
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(frameRect.left + 12, scanY),
      Offset(frameRect.right - 12, scanY),
      scanLinePaint,
    );

    // Glow effect below scan line
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kAccentAmber.withValues(alpha: 0.25),
          _kAccentAmber.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(frameRect.left + 12, scanY, frameSize - 24, 30),
      );

    canvas.drawRect(
      Rect.fromLTWH(frameRect.left + 12, scanY, frameSize - 24, 30),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLineProgress != scanLineProgress;
  }
}
