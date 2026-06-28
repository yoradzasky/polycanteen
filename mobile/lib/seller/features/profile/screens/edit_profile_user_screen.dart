import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../widgets/profile_header_curve.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'package:mobile/core/widgets/app_loading_animation.dart';


class EditProfileUserScreen extends StatefulWidget {
  const EditProfileUserScreen({super.key});

  @override
  State<EditProfileUserScreen> createState() => _EditProfileUserScreenState();
}

class _EditProfileUserScreenState extends State<EditProfileUserScreen> {
  late TextEditingController _namaController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  UserProfile? _profile;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    // Delay sedikit untuk memastikan context siap
    Future.delayed(const Duration(milliseconds: 500), _loadProfile);
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile = await ProfileService.getProfile();
      setState(() {
        _profile = profile;
        _namaController.text = profile.namaPemilik ?? profile.username;
        _phoneController.text = profile.noTelp ?? '';
        _emailController.text = profile.email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error ?? 'Gagal memuat profil')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Email tidak boleh kosong')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      await ProfileService.updateProfile(
        username: _profile?.username ?? '', // Keep existing username
        email: _emailController.text,
        namaPemilik: _namaController.text,
        noTelp: _phoneController.text.isEmpty ? null : _phoneController.text,
        fotoProfil: _selectedImage,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    final targetPath = "$path/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Kompres ke kualitas 70%
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF3852B4)),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF3852B4)),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final compressedFile = await _compressImage(File(pickedFile.path));
        if (compressedFile != null) {
          setState(() {
            _selectedImage = compressedFile;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }
  

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const Center(child: AppLoadingAnimation()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Memanggil Header Biru
            ProfileHeaderCurve(
              title: 'Edit Profil Pengguna',
              userName: _namaController.text,
              profileImage: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : (_profile?.fotoProfil != null
                              ? Image.network(
                                  _profile!.fotoProfil!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, url, error) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 44,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 44,
                                    color: Colors.grey[600],
                                  ),
                                )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Color(0xFF3852B4), size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Form Input ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Nama'),
                  _buildTextField(_namaController, hint: 'Masukkan nama Anda'),
                  const SizedBox(height: 16),

                  _buildInputLabel('Nomor Telepon'),
                  _buildTextField(_phoneController, isNumber: true),
                  const SizedBox(height: 16),

                  _buildInputLabel('Email'),
                  _buildTextField(_emailController),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        disabledBackgroundColor: const Color(0xFFD4A574),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Update Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Widget Helper Form
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool isNumber = false, String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.emailAddress,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
    );
  }
}