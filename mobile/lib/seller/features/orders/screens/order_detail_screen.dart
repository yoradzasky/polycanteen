import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_proof_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryColor;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.primaryColor,
  });

  Color get _bgColor => const Color(0xFFF4F6FB);
  Color get _borderColor => const Color(0xFFE5E7EB);
  Color get _shadowColor => Colors.black.withValues(alpha: 0.05);
  Color get _iconColor => primaryColor;
  Color get _iconBgColor => primaryColor.withValues(alpha: 0.1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildOrderHeader(),
            _buildPaymentMethod(),
            _buildOrderItems(),
            if (order['catatan_pesanan'] != null &&
                order['catatan_pesanan'].toString().isNotEmpty)
              _buildNotes(),
            _buildPriceSummary(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: _bgColor,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentProofScreen(
                  order: order,
                  primaryColor: primaryColor,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Lihat Bukti Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: _shadowColor,
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildOrderHeader() {
    String waktuPesan = '-';
    if (order['created_at'] != null) {
      DateTime dt = DateTime.parse(order['created_at']).toLocal();
      waktuPesan = '${DateFormat('HH:mm').format(dt)} WIB';
    }

    final String status = order['status_pesanan'] ?? 'pending';
    String statusText = 'Pesanan Masuk';
    Color statusColor = const Color(0xFF2196F3);

    switch (status) {
      case 'pending':
      case 'menunggu_persetujuan':
      case 'menunggu_pembayaran':
      case 'diproses':
      case 'dimasak':
        statusColor = const Color(0xFFF2994A);
        statusText = status.replaceAll('_', ' ').toUpperCase();
        break;
      case 'dibayar':
      case 'dikonfirmasi':
      case 'menunggu_dikirim':
      case 'dalam_perjalanan':
        statusColor = const Color(0xFF2196F3);
        statusText = status.replaceAll('_', ' ').toUpperCase();
        break;
      case 'siap_diambil':
      case 'selesai':
        statusColor = const Color(0xFF4CAF50);
        statusText = status.replaceAll('_', ' ').toUpperCase();
        break;
      case 'ditolak':
      case 'gagal':
        statusColor = const Color(0xFFE53935);
        statusText = status.replaceAll('_', ' ').toUpperCase();
        break;
      case 'dibatalkan':
        statusColor = const Color(0xFF9E9E9E);
        statusText = status.replaceAll('_', ' ').toUpperCase();
        break;
      default:
        statusColor = Colors.grey;
        statusText = status.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Waktu Pesan',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    waktuPesan,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nomor Antrian',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['nomor_antrian'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Tipe Pesanan',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (order['tipe_pesanan'] ?? '-')
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final payment = order['payment'] ?? {};
    final metodeBayar =
        payment['metode_bayar']?.toString().toUpperCase() ?? '-';
    String rawStatus = payment['status_bayar']?.toString().toLowerCase() ?? '';
    String statusBayar = 'LUNAS';

    if (rawStatus == 'sukses' || rawStatus == 'berhasil') {
      statusBayar = 'LUNAS';
    } else if (rawStatus.isNotEmpty) {
      statusBayar = rawStatus.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.qr_code_2, color: _iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  metodeBayar,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusBayar,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    List<dynamic> details = order['details'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Item',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(details.length, (index) {
            final item = details[index];
            final namaMenu = item['menu']?['nama_item'] ?? 'Item';
            final qty = int.tryParse(item['jumlah_pesanan'].toString()) ?? 1;
            final hargaSatuan =
                (double.tryParse(item['harga_saat_beli'].toString()) ?? 0)
                    .toInt();

            final dynamic rawVarian = item['varian_snapshot'];
            final List<Map<String, String>> parsedVariants = [];

            if (rawVarian != null) {
              if (rawVarian is Map) {
                rawVarian.forEach((key, value) {
                  final category = key.toString();
                  if (value is Map) {
                    final nama = value['nama'] ?? value['name'] ?? '-';
                    parsedVariants.add({
                      'category': category,
                      'name': nama.toString(),
                    });
                  } else if (value is List) {
                    for (var v in value) {
                      if (v is Map) {
                        final nama = v['nama'] ?? v['name'] ?? '-';
                        parsedVariants.add({
                          'category': category,
                          'name': nama.toString(),
                        });
                      } else {
                        parsedVariants.add({
                          'category': category,
                          'name': v.toString(),
                        });
                      }
                    }
                  } else {
                    parsedVariants.add({
                      'category': category,
                      'name': value.toString(),
                    });
                  }
                });
              } else if (rawVarian is List) {
                for (var v in rawVarian) {
                  if (v is Map) {
                    final nama = v['nama'] ?? v['name'] ?? v.toString();
                    parsedVariants.add({
                      'category': 'Varian',
                      'name': nama.toString(),
                    });
                  } else {
                    parsedVariants.add({
                      'category': 'Varian',
                      'name': v.toString(),
                    });
                  }
                }
              }
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: _iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  namaMenu,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'x$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (parsedVariants.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...parsedVariants.map(
                              (v) => Text(
                                '• ${v['category']}: ${v['name']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(hargaSatuan)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < details.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Colors.grey.shade100,
                      thickness: 1,
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    String cleanNote = order['catatan_pesanan'].toString();
    final noteRegExp = RegExp(r'^catatan:\s*', caseSensitive: false);
    if (noteRegExp.hasMatch(cleanNote)) {
      cleanNote = cleanNote.replaceAll(noteRegExp, '');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined, color: _iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cleanNote,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final int totalHarga =
        (double.tryParse(order['total_harga'].toString()) ?? 0).toInt();
    List<dynamic> details = order['details'] ?? [];
    int subtotal = 0;
    for (var item in details) {
      subtotal += (double.tryParse(item['subtotal'].toString()) ?? 0).toInt();
    }
    int biayaTambahan = totalHarga - subtotal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Subtotal Menu', subtotal),
          if (biayaTambahan > 0) ...[
            const SizedBox(height: 12),
            _summaryRow('Ongkos / Layanan', biayaTambahan),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Rp ${NumberFormat('#,###', 'id_ID').format(price)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
