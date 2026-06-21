import 'package:flutter/material.dart';

class ProfileHeaderCurve extends StatelessWidget {
  final String title;
  final Widget? profileImage;
  final String? userName;

  const ProfileHeaderCurve({
    super.key,
    required this.title,
    this.profileImage,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,
        bottom: 32,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF3852B4),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // AppBar Custom (Tombol Back & Judul)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Spacer agar judul tetap di tengah
            ],
          ),
          const SizedBox(height: 24),
          
          // Bagian Foto Profil (Jika ada)
          ?profileImage,
          
          const SizedBox(height: 16),
          
          // Bagian Nama User (Jika ada)
          if (userName != null)
            Text(
              userName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}