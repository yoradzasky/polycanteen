import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import '../../layouts/student_main_layout.dart';
import '../../layouts/seller_main_layout.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../student/payment/screens/payment_screen.dart';
import '../../../student/orders/services/order_service.dart';
import '../../../student/home/screens/home_screen.dart';
import '../../services/notification_service.dart';
import '../../../student/home/widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk menangkap inputan user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Fungsi untuk memanggil API Login
  // Fungsi untuk memanggil API Login
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // Validasi kosong di sisi Flutter
    if (email.isEmpty || password.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'Email dan Kata Sandi tidak boleh kosong',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. AMBIL IP DARI FILE .env
      // Jika gagal terbaca, baru dia pakai localhost sebagai cadangan
      final String baseUrl =
          dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';

      // 2. GABUNGKAN BASE_URL dengan endpoint '/login'
      final Uri url = Uri.parse('$baseUrl/login');

      // Tambahkan .timeout agar loading otomatis berhenti jika server mati/tidak nyambung
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10)); // Batas waktu tunggu 10 detik

      final responseData = jsonDecode(response.body);

      // Cek apakah response sukses dari Laravel
      if (response.statusCode == 200 && responseData['success'] == true) {
        final String token = responseData['data']['token'];
        final String userRole =
            responseData['data']['user']['role'] ?? 'pegawai';

        // Cek apakah role adalah admin - jika iya, tolak login
        if (userRole == 'admin') {
          if (!mounted) return;
          CustomSnackBar.show(
            context,
            message: 'Admin tidak dapat login melalui aplikasi mobile',
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final prefs = EncryptedSharedPreferences();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_role', userRole);

        await NotificationService.sendTokenToServer();

        if (!mounted) return;
        // Redirect ke halaman utama sesuai role
        if (userRole == 'mahasiswa') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentMainLayout(userRole: userRole),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SellerMainLayout()),
          );
        }
      } else {
        // --- PENANGANAN JIKA ERROR (AKUN SALAH ATAU EMAIL NGACOK) ---
        if (!mounted) return;

        String errorMessage = responseData['message'] ?? 'Login gagal.';

        if (responseData['errors'] != null) {
          errorMessage = responseData['errors'].values.first[0];
        }

        CustomSnackBar.show(
          context,
          message: errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      // --- PENANGANAN JIKA SERVER MATI / KONEKSI GAGAL ---
      if (!mounted) return;

      debugPrint('ERROR LOGIN: $e');

      CustomSnackBar.show(
        context,
        message: 'Gagal terhubung ke server. Pastikan API menyala!',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Poly',
                              style: TextStyle(color: Color(0xFF1E232C)),
                            ),
                            TextSpan(
                              text: 'Canteen',
                              style: TextStyle(color: Color(0xFFF2994A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masuk untuk melanjutkan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Input Email
                      _EmailField(controller: _emailController),
                      const SizedBox(height: 16),

                      // Input Password
                      _PasswordField(controller: _passwordController),
                      const SizedBox(height: 24),

                      // Tombol Login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D50EE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          const Text(
                            'Belum punya akun?',
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar sekarang',
                              style: TextStyle(
                                color: Color(0xFF2D50EE),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET REGISTER SCREEN & HELPER COMPONENTS
// =========================================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isFormValid = false;
  bool _isRegistering = false;
  XFile? _ktmImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedJurusan;
  final List<String> _jurusanList = [
    'Teknologi Informasi',
    'Produksi Pertanian',
    'Teknologi Pertanian',
    'Peternakan',
    'Manajemen Agribisnis',
    'Kesehatan',
    'Teknik',
    'Bahasa, Komunikasi dan Pariwisata',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_updateFormValid);
    _nimController.addListener(_updateFormValid);
    _emailController.addListener(_updateFormValid);
    _phoneController.addListener(_updateFormValid);
    _passwordController.addListener(_updateFormValid);
    _confirmPasswordController.addListener(_updateFormValid);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateFormValid() {
    final isValid =
        _fullNameController.text.trim().isNotEmpty &&
        _nimController.text.trim().isNotEmpty &&
        _selectedJurusan != null &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _ktmImage != null;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _register() async {
    final String name = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String nim = _nimController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;

    setState(() {
      _isRegistering = true;
    });

    try {
      final String baseUrl =
          dotenv.env['BASE_URL'] ?? 'http://192.168.1.14:8000/api';
      final Uri url = Uri.parse('$baseUrl/register');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Accept': 'application/json',
      });
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['nim'] = nim;
      if (_selectedJurusan != null) {
        request.fields['jurusan'] = _selectedJurusan!;
      }
      request.fields['phone'] = phone;
      request.fields['password'] = password;

      if (_ktmImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_ktm',
            _ktmImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        if (!mounted) return;
        _showSuccessDialog(context);
      } else {
        if (!mounted) return;
        String errorMessage = responseData['message'] ?? 'Pendaftaran gagal.';
        if (responseData['errors'] != null) {
          errorMessage = responseData['errors'].values.first[0];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('ERROR REGISTER: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal terhubung ke server. Pastikan API menyala!'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _pickKtmImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _ktmImage = pickedFile;
        });
        _updateFormValid();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2D50EE)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickKtmImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2D50EE)),
                title: const Text('Ambil Foto Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickKtmImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKtmUploadBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto KTM (Kartu Tanda Mahasiswa)',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: _ktmImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_ktmImage!.path),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'KTM Terpilih',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.sync, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ubah',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D50EE).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF2D50EE),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unggah Foto KTM',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Format JPG/PNG, Maks. 2MB',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Daftar Sebagai Pembeli'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Akun',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lengkapi data dirimu untuk mulai jajan di kantin.',
                        style: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _RegisterField(
                        controller: _fullNameController,
                        label: 'Nama Lengkap',
                        hint: 'Masukkan nama lengkapmu',
                      ),
                      const SizedBox(height: 16),
                      _RegisterField(
                        controller: _nimController,
                        label: 'NIM (Nomor Induk Mahasiswa)',
                        hint: 'Masukkan NIM Anda',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jurusan',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedJurusan,
                            hint: const Text(
                              'Pilih Jurusan',
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            items: _jurusanList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedJurusan = newValue;
                              });
                              _updateFormValid();
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2D50EE), width: 1.5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _RegisterField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Masukkan emailmu',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _PhoneField(controller: _phoneController),
                      const SizedBox(height: 16),
                      _buildKtmUploadBox(),
                      const SizedBox(height: 16),
                      _RegisterField(
                        controller: _passwordController,
                        label: 'Kata Sandi',
                        hint: 'Buat kata sandi',
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      _RegisterField(
                        controller: _confirmPasswordController,
                        label: 'Konfirmasi Kata Sandi',
                        hint: 'Ulangi kata sandi',
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isFormValid && !_isRegistering)
                              ? _register
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D50EE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isRegistering
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF757575),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Masuk',
                                style: TextStyle(
                                  color: Color(0xFF2D50EE),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pendaftaran Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Silahkan tunggu sampai admin menyetujui pembuatan akun anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D50EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget Input Email Khusus Halaman Login
class _EmailField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Masukkan email',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2D50EE),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget Input Kata Sandi Khusus Halaman Login (Bisa lihat/sembunyikan password)
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const _PasswordField({required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kata Sandi',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            hintText: 'Masukkan kata sandi',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF757575),
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2D50EE),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget Input Nomor HP (Tetap dibiarkan untuk halaman Register)
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nomor Handphone',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '81234567890',
            hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+62',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2D50EE),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget Input Generic untuk Register
class _RegisterField extends StatefulWidget {
  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;

  @override
  State<_RegisterField> createState() => _RegisterFieldState();
}

class _RegisterFieldState extends State<_RegisterField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _isObscure,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF757575),
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2D50EE),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
