import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;
import '../../../../core/widgets/seller_navbar.dart';
import '../../../../core/auth/services/auth_service.dart';
import '../../../../core/auth/screens/login_screen.dart';
import '../../menu/screens/menu_list_screen.dart';
import 'edit_profile_user_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_kantin_screen.dart';
import '../services/profile_service.dart';
import '../models/kantin_profile.dart';
import '../models/user_profile.dart';

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
          // Bisa ditangani lebih lanjut jika perlu, tapi biarkan null jika gagal
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

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                ],
              ),
            );
          }

          final UserProfile userData = snapshot.data!['user'];
          final KantinProfile? kantinData = snapshot.data!['kantin'];
          final bool isPemilik = userData.role == 'pemilik';

          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeaderAndInfo(
                  userName: userData.namaPemilik ?? userData.username,
                  kantinName: kantinData?.namaKantin ?? 'Pegawai',
                  rating: kantinData?.rating ?? 0.0,
                  fotoProfile: userData.fotoProfil,
                  isPemilik: isPemilik,
                  onRefresh: _loadProfileData,
                ),
                const SizedBox(height: 32),
                _MenuSection(
                  onRefresh: _loadProfileData,
                  onLogout: _handleLogout,
                  isPemilik: isPemilik,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeaderAndInfo extends StatelessWidget {
  final String userName;
  final String kantinName;
  final double rating;
  final String? fotoProfile;
  final bool isPemilik;
  final VoidCallback onRefresh;

  const _ProfileHeaderAndInfo({
    required this.userName,
    required this.kantinName,
    required this.rating,
    this.fotoProfile,
    required this.isPemilik,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: statusBarHeight + 24,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3852B4), Color(0xFF2A3D87)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: fotoProfile != null
                  ? Image.network(
                      fotoProfile!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/images/profile.jpg",
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      "assets/images/profile.jpg",
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kantinName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (isPemilik)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (isPemilik) const SizedBox(height: 24) else const SizedBox(height: 12),
          SizedBox(
            width: 160,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileUserScreen()),
                ).then((_) => onRefresh());
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Edit Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final bool isPemilik;

  const _MenuSection({
    required this.onRefresh, 
    required this.onLogout,
    required this.isPemilik,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Akun',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _CustomListTile(
            icon: Icons.security_outlined,
            iconBgColor: const Color(0xFFF3F4F6),
            iconColor: const Color(0xFF4B5563),
            title: 'Keamanan Akun / Ubah Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ).then((_) => onRefresh());
            },
          ),
          if (isPemilik) ...[
            const SizedBox(height: 24),
            const Text(
              'Kantin',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _CustomListTile(
              icon: Icons.edit_note_outlined,
              iconBgColor: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              title: 'Ubah Profil Kantin',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileKantinScreen()),
                ).then((_) => onRefresh());
              },
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDC2626), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Keluar',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _CustomListTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
