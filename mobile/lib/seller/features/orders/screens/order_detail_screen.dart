import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_proof_screen.dart';
// Note: order_list_screen.dart sudah tidak di-import lagi karena DummyOrder sudah kita buang!

class OrderDetailScreen extends StatelessWidget {
  // Sekarang menerima data asli dari API
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        elevation: 0,
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFF4F6FB),
        child: ElevatedButton(
          onPressed: () {
            // NAVIGASI KE HALAMAN BUKTI PEMBAYARAN
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentProofScreen(order: order),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2994A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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

  // --- 1. HEADER (ANTRIAN & TIPE) ---
  Widget _buildOrderHeader() {
    // Format waktu pesan dari created_at
    String waktuPesan = '-';
    if (order['created_at'] != null) {
      DateTime dt = DateTime.parse(order['created_at']).toLocal();
      waktuPesan = '${DateFormat('HH:mm').format(dt)} WIB';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Color(0xFF3949AB),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pesanan Masuk',
                      style: TextStyle(
                        color: Color(0xFF3949AB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                      color: Color(0xFF1A1A1A),
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
                    order['tipe_pesanan'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
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

  // --- 2. METODE PEMBAYARAN ---
  Widget _buildPaymentMethod() {
    // Ambil relasi payment dari API
    final payment = order['payment'] ?? {};

    // Ambil metode bayar, jika ada ubah jadi huruf kapital (contoh: qris -> QRIS)
    final metodeBayar =
        payment['metode_bayar']?.toString().toUpperCase() ?? '-';

    // Ambil status bayar dari database
    String rawStatus = payment['status_bayar']?.toString().toLowerCase() ?? '';
    String statusBayar = 'LUNAS'; // Fallback default

    // Kondisi: Jika di database "sukses", tampilkan "LUNAS".
    // Jika ada status lain (misal "pending", "gagal"), jadikan huruf kapital.
    if (rawStatus == 'sukses') {
      statusBayar = 'LUNAS';
    } else if (rawStatus.isNotEmpty) {
      statusBayar = rawStatus.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code_2,
              color: Color(0xFF3949AB),
              size: 24,
            ),
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
                Text(
                  metodeBayar,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusBayar,
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. LIST ITEM PESANAN ---
  Widget _buildOrderItems() {
    List<dynamic> details = order['details'] ?? [];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(details.length, (index) {
          final item = details[index];

          // 1. UBAH DI SINI: Sesuaikan dengan nama kolom 'nama_item'
          final namaMenu = item['menu']?['nama_item'] ?? 'Item';

          final qty = int.tryParse(item['jumlah_pesanan'].toString()) ?? 1;

          // 2. UBAH DI SINI: Gunakan double.tryParse untuk membaca desimal harga_saat_beli
          final hargaSatuan =
              (double.tryParse(item['harga_saat_beli'].toString()) ?? 0)
                  .toInt();

          // Cek apakah ada ekstra varian (json array)
          bool hasVarian =
              item['varian_snapshot'] != null ||
              item['topping_snapshot'] != null;

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Color(0xFF3949AB),
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
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
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
                        if (hasVarian) ...[
                          const SizedBox(height: 4),
                          const Text(
                            '• Memiliki Varian / Topping',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(hargaSatuan)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              fontSize: 15,
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
                    color: Colors.grey.shade200,
                    thickness: 1,
                    height: 1,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // --- 4. CATATAN ---
  Widget _buildNotes() {
    String cleanNote = order['catatan_pesanan'].toString();
    final noteRegExp = RegExp(r'^catatan:\s*', caseSensitive: false);
    if (noteRegExp.hasMatch(cleanNote)) {
      cleanNote = cleanNote.replaceAll(noteRegExp, '');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF2994A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error, color: Color(0xFFF2994A), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Catatan: $cleanNote',
              style: const TextStyle(
                color: Color(0xFFF2994A),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. SUMMARY HARGA ---
  Widget _buildPriceSummary() {
    // 3. UBAH DI SINI: Gunakan double.tryParse untuk total_harga
    final int totalHarga =
        (double.tryParse(order['total_harga'].toString()) ?? 0).toInt();

    // Hitung subtotal dinamis dari detail menu
    List<dynamic> details = order['details'] ?? [];
    int subtotal = 0;
    for (var item in details) {
      // 4. UBAH DI SINI: Gunakan double.tryParse untuk kolom subtotal
      subtotal += (double.tryParse(item['subtotal'].toString()) ?? 0).toInt();
    }

    // Jika total harga lebih besar dari subtotal menu, berarti ada biaya tambahan (misal: ongkir/layanan)
    int biayaTambahan = totalHarga - subtotal;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal Menu', subtotal),
          if (biayaTambahan > 0) ...[
            const SizedBox(height: 12),
            _summaryRow('Ongkos / Layanan', biayaTambahan),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(totalHarga)}',
                style: const TextStyle(
                  color: Color(0xFF3949AB),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
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
          style: const TextStyle(color: Color(0xFF4F4F4F), fontSize: 14),
        ),
        Text(
          'Rp ${NumberFormat('#,###', 'id_ID').format(price)}',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
