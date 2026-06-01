import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentProofScreen extends StatelessWidget {
  // 1. Terima data asli dari API
  final Map<String, dynamic> order;

  const PaymentProofScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // 2. Ekstrak data payment dari relasi API
    final payment = order['payment'] ?? {};
    final totalHarga = (double.tryParse(order['total_harga']?.toString() ?? '0') ?? 0).toInt();
    
    // Data Pembayaran Dinamis
    final trxId = payment['midtrans_order_id'] ?? 'TRX-PLN-${order['id'] ?? '000'}';
    final metode = payment['metode_bayar']?.toString().toUpperCase() ?? 'QRIS';
    
    // AMBIL NAMA KANTIN DARI DATABASE (Atur fallback jika null)
    final namaKantin = order['kantin']?['nama_kantin'] ?? 'Kantin Sipil';

    // SINKRONISASI STATUS: Jika di tabel "sukses" atau "settlement", paksa jadi "LUNAS"
    String rawStatus = payment['status_bayar']?.toString().toLowerCase() ?? '';
    String status = 'LUNAS'; 
    if (rawStatus == 'sukses' || rawStatus == 'settlement' || rawStatus == 'lunas') {
      status = 'LUNAS';
    } else if (rawStatus.isNotEmpty) {
      status = rawStatus.toUpperCase();
    } else {
      status = 'PENDING';
    }
    
    // Format Waktu Pembayaran (Ambil dari tabel payment, atau fallback ke created_at pesanan)
    String waktuBayar = '-';
    final rawTime = payment['waktu_bayar'] ?? order['created_at'];
    if (rawTime != null) {
      DateTime dt = DateTime.parse(rawTime.toString()).toLocal();
      waktuBayar = '${DateFormat('dd MMM yyyy, HH:mm').format(dt)} WIB';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          'Bukti Pembayaran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              // --- KARTU RESI ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // NAMA KANTIN DINAMIS
                    Text(
                      '$namaKantin\nPolines',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // STATUS BERHASIL (Sekarang akurat membaca variabel status LUNAS)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == 'LUNAS' ? Icons.check_circle : Icons.pending, 
                          color: status == 'LUNAS' ? const Color(0xFF3949AB) : const Color(0xFFF2994A), 
                          size: 30
                        ),
                        const SizedBox(width: 12),
                        Text(
                          status == 'LUNAS' ? 'Pembayaran\nBerhasil' : 'Menunggu\nPembayaran',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                    const SizedBox(height: 32),

                    // DETAIL INFO
                    _buildInfoRow('ID Transaksi', trxId),
                    _buildInfoRow('Metode Pembayaran', metode),
                    _buildInfoRow(
                      'Status Pembayaran', 
                      status, 
                      valueColor: status == 'LUNAS' ? const Color(0xFF3949AB) : const Color(0xFFF2994A)
                    ),
                    _buildInfoRow('Waktu Pembayaran', waktuBayar),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                    const SizedBox(height: 32),

                    // TOTAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Nominal',
                          style: TextStyle(fontSize: 16, color: Color(0xFF4F4F4F)),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Bantuan
  Widget _buildInfoRow(String label, String value, {Color valueColor = const Color(0xFF1A1A1A)}) {
    return SizedBox(
      width: double.infinity, 
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF828282)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}