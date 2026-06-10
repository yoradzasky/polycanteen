import 'package:flutter/material.dart';

class QueueTicketScreen extends StatelessWidget {
  final int pesananId;

  const QueueTicketScreen({super.key, required this.pesananId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Antrian')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            Text(
              'Pembayaran Berhasil!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('ID Pesanan: $pesananId'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Menghapus semua tumpukan halaman dan kembali ke Beranda utama
                Navigator.of(context).pushNamedAndRemoveUntil('/student-main', (route) => false);
              },
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}
