import 'package:flutter/material.dart';
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

      // Hanya ambil profil kantin jika role adalah pemilik
      if (profile.role == 'pemilik') {
        try {
          kantinData = await ProfileService.getKantinProfile();
        } catch (e) {
          developer.log('Error loading kantin data: $e');
        }
      }

      return {
        'user': profile,
        'kantin': kantinData,
        'success': true,
      };
    } catch (e) {
      developer.log('Error loading profile: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
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
                } catch (e) {
                  // Lanjutkan paksa logout meskipun gagal di servis
                }
                
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoadingAnimation());
          }

          if (snapshot.hasError || snapshot.data?['success'] != true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.data?['error'] ?? 'Tidak diketahui'}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    child: const Text('Coba Lagi'),
                  ),
                  if ((snapshot.data?['error'] ?? '').toString().contains('Unauthenticated')) ...[
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
            );
          }

          final UserProfile userData = snapshot.data!['user'];
          final KantinProfile? kantinData = snapshot.data!['kantin'];
          final bool isPemilik = userData.role == 'pemilik';

          return SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // Custom Screen Title
                  const Text(
                    "Profil Saya",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E232C),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- HEADER CARD PROFIL ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFE0C2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFE0C2),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: userData.fotoProfil != null ? NetworkImage(userData.fotoProfil!) : null,
                            backgroundColor: Colors.grey.shade200,
                            onBackgroundImageError: (_, __) {},
                            child: userData.fotoProfil == null ? Icon(Icons.person, size: 48, color: Colors.grey[600]) : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama
                        Text(
                          userData.namaPemilik ?? userData.username,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E232C),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Role & Kantin
                        Text(
                          "${isPemilik ? 'Pemilik' : 'Pegawai'} - ${kantinData?.namaKantin ?? 'Kantin'}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8391A1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isPemilik) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  (kantinData?.rating ?? 0.0).toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFFF08D39),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- SECTION AKUN ---
                  const Text(
                    "Pengaturan Akun",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8391A1),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- MENU EDIT PROFIL USER ---
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: "Edit Profil User",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileUserScreen()),
                      ).then((_) => _loadProfileData());
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- MENU KEAMANAN / UBAH PASSWORD ---
                  _buildMenuItem(
                    icon: Icons.security_outlined,
                    label: "Keamanan Akun / Ubah Password",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      ).then((_) => _loadProfileData());
                    },
                  ),
                  
                  if (isPemilik) ...[
                    const SizedBox(height: 30),
                    // --- SECTION KANTIN ---
                    const Text(
                      "Pengaturan Kantin",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8391A1),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- MENU EDIT PROFIL KANTIN ---
                    _buildMenuItem(
                      icon: Icons.storefront_outlined,
                      label: "Ubah Profil Kantin",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileKantinScreen()),
                        ).then((_) => _loadProfileData());
                      },
                    ),
                  ],

                  const SizedBox(height: 48),

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
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0C2), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF08D39).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFF08D39),
                size: 20,
              ),
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
