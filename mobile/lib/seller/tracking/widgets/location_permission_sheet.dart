import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Painter khusus untuk menggambar peta yang estetik
class MapIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Jalur biru muda (Light Blue)
    final pathPaint = Paint()
      ..color = const Color(0xFF8DC0FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Melengkung dari kanan atas ke bawah
    path.moveTo(size.width * 0.9, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.6, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.95, 0, size.height * 0.85);
    canvas.drawPath(path, pathPaint);

    // Jalan Raya (Garis Putih)
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Jalan vertikal kiri
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.2, size.height), roadPaint);
    // Jalan vertikal tengah
    canvas.drawLine(Offset(size.width * 0.55, 0), Offset(size.width * 0.45, size.height), roadPaint);
    // Jalan horizontal atas
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.45), roadPaint);
    // Jalan horizontal bawah
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.75), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pop-up cantik izin lokasi (Bottom Sheet).
/// Mengembalikan `true` jika user menekan "Izinkan Akses Lokasi".
Future<bool?> showLocationPermissionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Header Row: Ilustrasi Peta & Teks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ilustrasi Peta Custom
              Container(
                width: 110,
                height: 110,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: const Color(0xFF619DED), // Warna biru laut solid
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: MapIllustrationPainter(),
                    ),
                    // Pin lokasi abu-abu dan titik putih
                    Positioned(
                      top: 25, // Di atas persimpangan
                      left: 45,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Titik putih di tengah pin
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(bottom: 6), 
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Pin lokasi abu-abu
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF9095A9),
                              size: 34,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Teks Judul & Deskripsi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mau pengantaranmu sampai tepat di depan pelanggan?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bagikan lokasimu sekarang agar pelanggan bisa ditemukan dengan mudah.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Divider(color: Colors.grey.shade100, thickness: 1),
          const SizedBox(height: 20),

          // Privacy note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security, // Ikon tameng
                  color: Color(0xFF3B5BBD),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(text: 'Lokasi kamu '),
                        TextSpan(
                          text: 'hanya digunakan',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                        ),
                        TextSpan(text: ' untuk\nmenemukan dan tidak disimpan.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Izinkan Akses Lokasi
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.near_me, size: 20),
              label: const Text(
                'Izinkan Akses Lokasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5BBD), // Warna biru dari gambar
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Dialog error izin lokasi (ketika ditolak / service mati).
void showPermissionErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool showOpenSettings = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Color(0xFFF2994A),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (showOpenSettings) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Geolocator.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buka Pengaturan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
