import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import '../../../../core/auth/services/auth_service.dart';
import '../../../../core/auth/screens/login_screen.dart';
import 'edit_profile_user_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_kantin_screen.dart';
import '../services/profile_service.dart';
import '../models/kantin_profile.dart';
import '../models/user_profile.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';

class ProfileTokoScreen extends StatefulWidget {
  const ProfileTokoScreen({super.key});

  @override
  State<ProfileTokoScreen> createState() => _ProfileTokoScreenState();
}

class _ProfileTokoScreenState extends State<ProfileTokoScreen> {
  late Future<Map<String, dynamic>> _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    setState(() {
      _profileData = _fetchProfileData();
    });
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      final profile = await ProfileService.getProfile();
      KantinProfile? kantinData;

      try {
        kantinData = await ProfileService.getKantinProfile();
      } catch (e) {
        developer.log('Error loading kantin data: $e');
      }

      return {'user': profile, 'kantin': kantinData, 'success': true};
    } catch (e) {
      developer.log('Error loading profile: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  String _getBaseUrl() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8000/api';
    return baseUrl
        .replaceAll(RegExp(r'/api$'), '')
        .replaceAll(RegExp(r'/mobile$'), '');
  }

  String? _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${_getBaseUrl()}/storage/$path';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            "Konfirmasi Keluar",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E232C),
            ),
          ),
          content: const Text(
            "Apakah Anda yakin ingin keluar dari akun ini?",
            style: TextStyle(color: Color(0xFF5A6675)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Batal",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB4335),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await AuthService.logout();
                } catch (e) {}

                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                "Keluar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6FB),
            body: Center(child: AppLoadingAnimation()),
          );
        }

        if (snapshot.hasError || snapshot.data?['success'] != true) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.data?['error'] ?? 'Tidak diketahui'}',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    child: const Text('Coba Lagi'),
                  ),
                  if ((snapshot.data?['error'] ?? '').toString().contains(
                    'Unauthenticated',
                  )) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                      label: const Text(
                        'Login Ulang',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final UserProfile userData = snapshot.data!['user'];
        final KantinProfile? kantinData = snapshot.data!['kantin'];
        final bool isPemilik = userData.role == 'pemilik';

        final Color primaryColor = isPemilik ? const Color(0xFF3949AB) : const Color(0xFF5E7AC4);
        final Color bgColor = const Color(0xFFF4F6FB);
        final Color borderColor = const Color(0xFFE5E7EB);
        final Color shadowColor = Colors.black.withValues(alpha: 0.05);

        final String? imageUrl = _getFullImageUrl(userData.fotoProfil);

        return Scaffold(
          backgroundColor: bgColor,
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CURVED HEADER (consistent with order list & finance) ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 32,
                    top: MediaQuery.of(context).padding.top + 16,
                  ),
                  child: Column(
                    children: [
                      // Title row
                      const Text(
                        'Profil Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          onBackgroundImageError: imageUrl != null ? (_, __) {} : null,
                          child: imageUrl == null
                              ? const Icon(Icons.person, size: 48, color: Colors.white70)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama
                      Text(
                        userData.nama,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Role & Kantin
                      Text(
                        "${isPemilik ? 'Pemilik' : 'Pegawai'} - ${kantinData?.namaKantin ?? 'Kantin'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (kantinData != null &&
                          kantinData.rating != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                kantinData.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // --- MENU ITEMS SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SECTION AKUN ---
                      Text(
                        "Pengaturan Akun",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- MENU EDIT PROFIL USER ---
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        label: "Edit Profil User",
                        primaryColor: primaryColor,
                        bgColor: bgColor,
                        borderColor: borderColor,
                        shadowColor: shadowColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileUserScreen(),
                            ),
                          ).then((_) => _loadProfileData());
                        },
                      ),
                      const SizedBox(height: 12),

                      // --- MENU KEAMANAN / UBAH PASSWORD ---
                      _buildMenuItem(
                        icon: Icons.security_outlined,
                        label: "Keamanan Akun / Ubah Password",
                        primaryColor: primaryColor,
                        bgColor: bgColor,
                        borderColor: borderColor,
                        shadowColor: shadowColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ).then((_) => _loadProfileData());
                        },
                      ),

                      if (isPemilik) ...[
                        const SizedBox(height: 24),
                        // --- SECTION KANTIN ---
                        Text(
                          "Pengaturan Kantin",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- MENU EDIT PROFIL KANTIN ---
                        _buildMenuItem(
                          icon: Icons.storefront_outlined,
                          label: "Ubah Profil Kantin",
                          primaryColor: primaryColor,
                          bgColor: bgColor,
                          borderColor: borderColor,
                          shadowColor: shadowColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileKantinScreen(),
                              ),
                            ).then((_) => _loadProfileData());
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // --- TOMBOL KELUAR ---
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFEB4335),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: const Color(0xFFFFF5F5),
                          ),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEB4335),
                          ),
                          label: const Text(
                            "Keluar Akun",
                            style: TextStyle(
                              color: Color(0xFFEB4335),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E232C),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
