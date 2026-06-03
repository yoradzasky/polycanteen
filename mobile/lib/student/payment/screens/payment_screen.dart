import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../../orders/screens/queue_ticket_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int pesananId;

  const PaymentScreen({super.key, required this.pesananId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _paymentService.createPayment(widget.pesananId);
      final paymentUrl = result['data']['payment_url'];
      
      final Uri url = Uri.parse(paymentUrl);
      if (await canLaunchUrl(url)) {
        // Membuka halaman Midtrans di browser eksternal/in-app
        await launchUrl(url, mode: LaunchMode.inAppWebView);
        
        // Asumsi user kembali setelah membayar
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QueueTicketScreen(pesananId: widget.pesananId),
            ),
          );
        }
      } else {
        throw 'Tidak dapat membuka halaman pembayaran.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D50EE),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Bayar dengan Midtrans',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
      ),
    );
  }
}