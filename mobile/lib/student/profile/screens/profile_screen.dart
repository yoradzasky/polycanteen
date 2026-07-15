import 'package:flutter/material.dart';
import '../services/mahasiswa_service.dart';
import '../../../core/auth/services/auth_service.dart';
import '../../../core/auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String errorMessage = '';

  String namaMahasiswa = "";
  String jurusan = "";
  String nim = "";
  String fotoProfil = "https://via.placeholder.com/150";
  String email = "";
  String noTelp = "";

  final MahasiswaService _mahasiswaService = MahasiswaService();

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _mahasiswaService.getProfileData();

      setState(() {
        namaMahasiswa = data['nama_mahasiswa'] ?? 'Mahasiswa';
        nim = data['nim'] ?? '-';
        jurusan = data['jurusan'] ?? '-';
        email = data['email'] ?? '-';
        noTelp = data['no_telp'] ?? '-';

        String? pathFoto = data['foto_profil_path'];

        if (pathFoto != null && pathFoto.isNotEmpty) {
          fotoProfil =
              '${_mahasiswaService.baseUrlForStorage}/storage/$pathFoto?t=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          fotoProfil = 'https://via.placeholder.com/150';
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
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
                setState(() => isLoading = true);
                
                try {
                  await AuthService.logout();
                } catch (e) {
                  // Lanjutkan paksa logout meskipun gagal di servis
                }
                
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF6ED),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF2994A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6ED),
      body: SafeArea(
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
                        backgroundImage: NetworkImage(fotoProfil),
                        backgroundColor: Colors.grey.shade200,
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Mahasiswa
                    Text(
                      namaMahasiswa,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E232C),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Jurusan & NIM
                    Builder(
                      builder: (context) {
                        String cleanJurusan = jurusan.trim();
                        if (cleanJurusan == '-' || cleanJurusan.toLowerCase() == 'null' || cleanJurusan.isEmpty) {
                          cleanJurusan = '';
                        }
                        
                        String cleanNim = nim.trim();
                        while (cleanNim.startsWith('-') || cleanNim.startsWith(' ')) {
                          if (cleanNim.startsWith('-')) {
                            cleanNim = cleanNim.substring(1).trim();
                          } else {
                            cleanNim = cleanNim.trim();
                          }
                        }
                        
                        String displayStr = '';
                        if (cleanJurusan.isNotEmpty) {
                          displayStr = "$cleanJurusan - $cleanNim";
                        } else {
                          displayStr = cleanNim;
                        }
                        
                        return Text(
                          displayStr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8391A1),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- SECTION INFORMASI PRIBADI ---
              const Text(
                "Informasi Pribadi",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8391A1),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFE0C2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF08D39).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoItem(
                      icon: Icons.email_outlined,
                      label: "Email",
                      value: email,
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 56),
                    _buildInfoItem(
                      icon: Icons.phone_outlined,
                      label: "Nomor Telepon",
                      value: noTelp,
                    ),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 56),
                    _buildInfoItem(
                      icon: Icons.school_outlined,
                      label: "Jurusan",
                      value: jurusan,
                    ),
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

              // --- MENU EDIT PROFIL ---
              InkWell(
                onTap: () async {
                  final isUpdated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );

                  if (isUpdated == true) {
                    fetchProfileData();
                  }
                },
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
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFFF08D39),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Edit Profil",
                          style: TextStyle(
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
              ),

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
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E232C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
