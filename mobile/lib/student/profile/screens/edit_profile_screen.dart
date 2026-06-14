import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/mahasiswa_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final MahasiswaService _service = MahasiswaService();
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();
  final _telpController = TextEditingController();

  String _currentEmail = "";
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _currentPhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final data = await _service.getProfileData();
      setState(() {
        _namaController.text = data['nama_mahasiswa'] ?? '';
        _nimController.text = data['nim'] ?? '';
        _telpController.text = data['no_telp'] ?? '';
        _currentEmail = data['email'] ?? '';

        if (data['foto_profil_path'] != null) {
          _currentPhotoUrl =
              '${_service.baseUrlForStorage}/storage/${data['foto_profil_path']}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memuat: $e")));
    }
  }

  // Fungsi untuk memproses pemilihan foto dari source manapun
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // Fungsi untuk menampilkan pilihan kamera atau galeri
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      await _service.updateProfile(
        nama: _namaController.text,
        nim: _nimController.text,
        telp: _telpController.text,
        email: _currentEmail,
        fotoFile: _selectedImage,
      );
      if (mounted) {
        Navigator.pop(context, true);

        // --- UBAH BAGIAN INI ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Profil berhasil diperbarui",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ), // Bikin teks jadi putih tebal
            ),
            backgroundColor: Color(
              0xFF4CAF50,
            ), // Warna Hijau ala Material Design
            behavior: SnackBarBehavior
                .floating, // (Opsional) Bikin snackbar ngambang, gak nempel bawah banget
            margin: EdgeInsets.all(
              16,
            ), // (Opsional) Kasih jarak kalau pake floating
            duration: Duration(seconds: 3), // (Opsional) Tampil 3 detik
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Hilangkan kata "Exception: " bawaan Flutter
        String pesanGagal = e.toString().replaceAll('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pesanGagal, // Sekarang menampilkan alasan spesifik dari Laravel
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFFE53935), // Warna Merah
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9), // Background agak keabuan
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Custom Header: Tombol Back & Title
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Bio-data",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ), // Spacer untuk menyeimbangkan layout
                ],
              ),
              const SizedBox(height: 30),

              // Ganti bagian GestureDetector ini
              GestureDetector(
                onTap: _showImagePickerOptions, // Panggil modal pilihan
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (_currentPhotoUrl != null
                                  ? NetworkImage(_currentPhotoUrl!)
                                  : const NetworkImage(
                                      "https://via.placeholder.com/150",
                                    )),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFF2994A),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _namaController.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                _currentEmail,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildTextField("Nama Lengkap", _namaController),
              _buildTextField("Nomor Induk Mahasiswa", _nimController),
              _buildTextField("Nomor Telepon", _telpController),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? Colors.grey
                        : const Color(0xFF3B5BDB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleUpdate,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B5BDB),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
