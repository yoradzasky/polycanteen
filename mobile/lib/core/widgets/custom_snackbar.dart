import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color indicatorColor = const Color(0xFF3B82F6); // Info (Blue)
    IconData icon = Icons.info_outline;

    if (isError) {
      indicatorColor = const Color(0xFFEF4444); // Premium Red
      icon = Icons.error_outline;
    } else if (isSuccess) {
      indicatorColor = const Color(0xFF10B981); // Premium Green
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: indicatorColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B), // Premium Slate 800
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
      ),
    );
  }
}
