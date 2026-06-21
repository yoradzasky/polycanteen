import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../orders/screens/queue_ticket_screen.dart';
import '../services/payment_service.dart';

class QrisPaymentScreen extends StatefulWidget {
  final String qrUrl; // Berisi raw string QR dari Midtrans Core API
  final String totalAmount;
  final int pesananId;

  const QrisPaymentScreen({
    super.key,
    required this.qrUrl,
    required this.totalAmount,
    required this.pesananId,
  });

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  Timer? _timer;
  Timer? _statusTimer;
  int _secondsRemaining = 900; // 15 menit
  final ScreenshotController screenshotController = ScreenshotController();
  final PaymentService _paymentService = PaymentService();
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startStatusPolling();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startStatusPolling() {
    // Poll every 5 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus(isAuto: true);
    });
  }

  Future<void> _checkPaymentStatus({bool isAuto = false}) async {
    if (_isCheckingStatus) return;
    
    try {
      if (!isAuto) setState(() => _isCheckingStatus = true);
      
      final response = await _paymentService.getPaymentStatus(widget.pesananId);
      debugPrint('DEBUG: Payment Status Response: $response');
      
      // Handle 404 from our updated service
      if (response['status_code'] == 404) {
        if (!isAuto && mounted) {
          _showRouteMissingDialog();
        }
        return;
      }

      final data = response['data'] ?? response; // Handle both wrapped and unwrapped data
      final String? transStatus = data['transaction_status'];
      final String? orderStatus = data['status_pesanan'];

      // Success conditions:
      // 1. Midtrans status is settlement or capture
      // 2. Local order status is 'dibayar' (means backend already updated it)
      if (transStatus == 'settlement' || 
          transStatus == 'capture' || 
          orderStatus == 'dibayar' ||
          orderStatus == 'proses') { 
        
        debugPrint('DEBUG: Payment Success detected! Status: $transStatus, Order: $orderStatus');
        _statusTimer?.cancel();
        _timer?.cancel();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QueueTicketScreen(pesananId: widget.pesananId),
            ),
          );
        }
      } else if (!isAuto) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pembayaran belum diterima. Silakan selesaikan pembayaran.")),
          );
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Error checking payment status: $e');
      if (!isAuto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && !isAuto) setState(() => _isCheckingStatus = false);
    }
  }

  void _showRouteMissingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Belum Siap'),
        content: const Text(
          'Endpoint api/student/payment/status/{id} tidak ditemukan (404) di backend.\n\n'
          'Anda harus menambahkan route tersebut di Laravel agar pengecekan otomatis berfungsi.\n\n'
          'Ingin lanjut ke halaman tiket untuk sementara (Simulasi Berhasil)?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tunggu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QueueTicketScreen(pesananId: widget.pesananId),
                ),
              );
            },
            child: const Text('Bypass (Lanjut)'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadQRIS() async {
    try {
      final image = await screenshotController.capture();
      if (image != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qris_${widget.pesananId}.png').create();
        await file.writeAsBytes(image);
        
        await Gal.putImage(file.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("QRIS berhasil disimpan ke galeri!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan QRIS: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF3852B4), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Pembayaran QRIS',
          style: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Screenshot(
              controller: screenshotController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 60,
                      left: 0,
                      child: Container(
                        width: 8,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFED2B2A),
                          borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFED2B2A),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'QRIS',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('QR Code Standar', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                  Text('Pembayaran Nasional', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'PolyCanteen',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: widget.qrUrl,
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('ID Pesanan: ${widget.pesananId}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('Dicetak oleh: Midtrans / GoPay', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Selesaikan pembayaran dalam $_formattedTime', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
            const SizedBox(height: 16),
            const Text('Total Pembayaran', style: TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.totalAmount, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _downloadQRIS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF08D38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Unduh QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCheckingStatus ? null : () => _checkPaymentStatus(isAuto: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BBD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isCheckingStatus 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Cek Status Pembayaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
