import 'package:flutter/material.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import '../widgets/profile_header_curve.dart';
import '../services/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _showCurrentPassword = true; // Default to true as per user hint "masih belum keliatan"
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _fotoProfile;
  String _userRole = 'pegawai';

  Color get _primaryColor => _userRole == 'pegawai'
      ? const Color(0xFF5E7AC4)
      : const Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadRole();
    _loadProfile();
  }

  Future<void> _loadRole() async {
    final prefs = EncryptedSharedPreferences();
    final role = await prefs.getString('user_role');
    if (!mounted) return;
    setState(() {
      _userRole = role.isNotEmpty ? role : 'pegawai';
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) {
        setState(() {
          _fotoProfile = profile.fotoProfil;
        });
      }
    } catch (e) {
      // Silently fail, just don't show the image
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // ... rest of the method remains the same ...
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru dan konfirmasi tidak sesuai')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 8 karakter')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await ProfileService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeaderCurve(
              title: 'Ubah Password',
              primaryColor: _primaryColor,
              profileImage: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: _fotoProfile != null
                      ? NetworkImage("$_fotoProfile?v=${DateTime.now().millisecondsSinceEpoch}")
                      : null,
                  child: _fotoProfile == null
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white70,
                        )
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Password Saat Ini'),
                    _buildPasswordField(
                      _currentPasswordController,
                      'Masukkan password saat ini',
                      _showCurrentPassword,
                      (value) {
                        setState(() => _showCurrentPassword = !_showCurrentPassword);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputLabel('Password Baru'),
                    _buildPasswordField(
                      _newPasswordController,
                      'Masukkan password baru',
                      _showNewPassword,
                      (value) {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        'Minimal 8 karakter dengan kombinasi huruf dan angka.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ),
                    _buildInputLabel('Konfirmasi Password Baru'),
                    _buildPasswordField(
                      _confirmPasswordController,
                      'Ulangi password baru',
                      _showConfirmPassword,
                      (value) {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool isVisible,
    Function(bool) onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () => onToggle(!isVisible),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}