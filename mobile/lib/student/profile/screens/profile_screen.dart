import 'package:flutter/material.dart';
import '../services/mahasiswa_service.dart';

// PASTIKAN PATH IMPORT INI SESUAI DENGAN FOLDER KAMU:
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

        // --- TAMBAHKAN BARIS INI ---
        String? pathFoto = data['foto_profil_path'];

        // Sekarang pathFoto sudah didefinisikan, jadi kode di bawah ini akan jalan
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

  // --- FUNGSI UNTUK MENAMPILKAN DIALOG LOGOUT ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Konfirmasi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext), // Tutup dialog jika batal
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB4335), // Warna Merah
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup dialog

                setState(() => isLoading = true); // Tampilkan efek loading

                // Eksekusi fungsi logout dari AuthService
                await AuthService.logout();

                // Arahkan ke LoginScreen dan hapus semua history halaman
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
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
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF2994A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- HEADER PROFIL ---
              Center(
                child: Column(
                  // Pastikan kolom ini benar-benar di tengah
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: NetworkImage(fotoProfil),
                        backgroundColor: Colors.grey.shade200,
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Mahasiswa
                    Text(
                      namaMahasiswa,
                      textAlign: TextAlign.center, // Wajib ditambah
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E232C),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Jurusan & NIM
                    Text(
                      "$jurusan - $nim",
                      textAlign: TextAlign.center, // Wajib ditambah
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8391A1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- SECTION AKUN ---
              const Text(
                "Akun",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8391A1),
                ),
              ),
              const SizedBox(height: 16),

              // --- MENU EDIT PROFIL ---
              InkWell(
                onTap: () async {
                  // 1. Pindah ke EditProfileScreen dan TUNGGU sampai user kembali
                  final isUpdated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );

                  // 2. Jika EditProfileScreen mengembalikan nilai true (berarti update sukses),
                  // maka kita refresh data profil dengan memanggil kembali fungsi fetchProfileData()
                  if (isUpdated == true) {
                    fetchProfileData();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Ikon Person
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF5A6675),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Teks "Edit Profil"
                      const Expanded(
                        child: Text(
                          "Edit Profil",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E232C),
                          ),
                        ),
                      ),
                      // Ikon Panah Kanan
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // --- TOMBOL KELUAR ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showLogoutDialog(context), // PANGGIL DIALOG DI SINI
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFEB4335),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEB4335),
                  ),
                  label: const Text(
                    "Keluar",
                    style: TextStyle(
                      color: Color(0xFFEB4335),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
