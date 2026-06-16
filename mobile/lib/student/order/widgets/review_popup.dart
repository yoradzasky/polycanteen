import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

/// Review popup widget that displays a star rating and comment form.
/// Matches the design: chat icon, title, subtitle, 5-star rating,
/// text area for message, and a "SEND FEEDBACK" button.
class ReviewPopup extends StatefulWidget {
  final int pesananId;
  final VoidCallback? onReviewSubmitted;

  const ReviewPopup({
    super.key,
    required this.pesananId,
    this.onReviewSubmitted,
  });

  /// Show the review popup as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int pesananId,
    VoidCallback? onReviewSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewPopup(
        pesananId: pesananId,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<ReviewPopup> createState() => _ReviewPopupState();
}

class _ReviewPopupState extends State<ReviewPopup>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rating terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = EncryptedSharedPreferences();
      final token = await prefs.getString('auth_token');
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
      final cleanBase = baseUrl.replaceAll(RegExp(r'/mobile$'), '');

      final dio = Dio(
        BaseOptions(
          baseUrl: cleanBase,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.post(
        '/mahasiswa/reviews',
        data: {
          'pesanan_id': widget.pesananId,
          'rating': _rating,
          'komentar': _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ulasan berhasil dikirim. Terima kasih!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          widget.onReviewSubmitted?.call();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final message = e.response?.data?['message'] ?? 'Gagal mengirim ulasan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Close Button ──
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Chat Icon ──
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFFF08D39),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ──
                  const Text(
                    'Berikan ulasan anda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3A8C),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ──
                  Text(
                    'Bagaimana pengalaman Anda dengan pesanan ini? Ulasan Anda sangat berarti bagi kami.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Star Rating ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _rating = starIndex);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedScale(
                            scale: _rating >= starIndex ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _rating >= starIndex
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: _rating >= starIndex
                                  ? const Color(0xFFF08D39)
                                  : Colors.grey.shade400,
                              size: 44,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ── Comment Text Area ──
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Your Message...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        counterText: '',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Send Feedback Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF08D39),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFF08D39,
                        ).withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Kirim Ulasan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
