import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/menu_service.dart';

// ──────────────────────────────────────────────
// Warna utama
// ──────────────────────────────────────────────
const Color _kPrimaryBlue = Color(0xFF3949AB);
const Color _kAccentOrange = Color(0xFFF57C00);

class AddMenuScreen extends StatefulWidget {
  const AddMenuScreen({super.key});

  @override
  State<AddMenuScreen> createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  // ─── Controllers ───
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _estimasiController = TextEditingController();

  // ─── State ───
  File? _selectedImage;
  String? _selectedKategori;
  bool _isSubmitting = false;

  // Pilihan layanan
  bool _makanDiTempat = false;
  bool _dibungkus = false;
  bool _pengantaran = false;

  // Variasi
  final List<_VariasiItem> _variasiList = [_VariasiItem()];
  final _pilihanNamaController = TextEditingController();
  final _pilihanHargaController = TextEditingController();

  final List<String> _kategoriList = ['Makanan', 'Minuman', 'Snack', 'Lainnya'];

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _estimasiController.dispose();
    for (var v in _variasiList) {
      v.dispose();
    }
    _pilihanNamaController.dispose();
    _pilihanHargaController.dispose();
    super.dispose();
  }

  // ─── Image Picker ───
  Future<void> _pickImage() async {
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
                leading: const Icon(Icons.camera_alt, color: _kPrimaryBlue),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _kPrimaryBlue),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  // ─── Submit ───
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori menu'), backgroundColor: Colors.red),
      );
      return;
    }

    final pilihanLayanan = <String>[];
    if (_makanDiTempat) pilihanLayanan.add('makan_di_tempat');
    if (_dibungkus) pilihanLayanan.add('dibungkus');
    if (_pengantaran) pilihanLayanan.add('pengantaran');

    if (pilihanLayanan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu pilihan layanan'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build varian data
      List<Map<String, dynamic>>? varianData;
      final validVarians = _variasiList.where((v) => v.namaController.text.isNotEmpty && v.pilihanList.isNotEmpty).toList();
      if (validVarians.isNotEmpty) {
        varianData = validVarians.map((v) => {
          'nama': v.namaController.text,
          'tipe': v.tipe,
          'pilihan': v.pilihanList.map((p) => {'nama': p.nama, 'harga': p.harga}).toList(),
        }).toList();
      }

      final hargaText = _hargaController.text.replaceAll(RegExp(r'[^0-9]'), '');

      final data = MenuFormData(
        namaItem: _namaController.text.trim(),
        harga: int.parse(hargaText),
        kategori: _selectedKategori!,
        pilihanLayanan: pilihanLayanan,
        deskripsi: _deskripsiController.text.isNotEmpty ? _deskripsiController.text.trim() : null,
        estimasiWaktu: _estimasiController.text.isNotEmpty ? int.tryParse(_estimasiController.text) : null,
        fotoMenu: _selectedImage,
        varian: varianData,
      );

      await _menuService.addMenu(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu berhasil ditambahkan'),
          backgroundColor: _kAccentOrange,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gagal'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  // ─── Tambah pilihan variasi ───
  void _addVariasiPilihan(int index) {
    final nama = _pilihanNamaController.text.trim();
    if (nama.isEmpty) return;

    final hargaText = _pilihanHargaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final harga = int.tryParse(hargaText) ?? 0;

    setState(() {
      _variasiList[index].pilihanList.add(_VariasiPilihan(nama: nama, harga: harga));
      _pilihanNamaController.clear();
      _pilihanHargaController.clear();
    });
  }

  // ──────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: _kPrimaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Tambah Menu Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Foto ───
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // ─── Nama Menu ───
              _buildSectionLabel('Nama Menu'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _namaController,
                hint: 'Contoh: Nasi Gudeg Komplit',
                validator: (v) => (v == null || v.isEmpty) ? 'Nama menu wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ─── Harga ───
              _buildSectionLabel('Harga'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _hargaController,
                hint: '25.000',
                prefix: 'Rp  ',
                prefixColor: _kPrimaryBlue,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga wajib diisi';
                  final num = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (num == null || num <= 0) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Deskripsi ───
              _buildSectionLabel('Deskripsi Menu'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _deskripsiController,
                hint: 'Tulis deskripsi menu...',
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // ─── Estimasi Waktu ───
              _buildSectionLabel('Estimasi Waktu Penyiapan'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _estimasiController,
                hint: '15 Menit',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixIcon: Icon(Icons.access_time, color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),

              // ─── Kategori ───
              _buildSectionLabel('Kategori Menu'),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 20),

              // ─── Pilihan Layanan ───
              _buildSectionLabel('Pilihan Layanan'),
              const SizedBox(height: 4),
              _buildLayananCheckboxes(),
              const SizedBox(height: 20),

              // ─── Variasi ───
              _buildSectionLabel('Variasi Menu'),
              const SizedBox(height: 8),
              _buildVariasiSection(),
              const SizedBox(height: 32),

              // ─── Tombol Simpan ───
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Widgets
  // ──────────────────────────────────────────

  Widget _buildPhotoSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _selectedImage == null
                      ? Icon(Icons.restaurant, size: 48, color: Colors.grey[400])
                      : null,
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kAccentOrange,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan Foto Menu',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    Color? prefixColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixText: prefix,
        prefixStyle: TextStyle(
          color: prefixColor ?? Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedKategori,
      decoration: InputDecoration(
        hintText: 'Pilih Kategori',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimaryBlue, width: 1.5),
        ),
      ),
      items: _kategoriList.map((k) {
        return DropdownMenuItem(value: k, child: Text(k));
      }).toList(),
      onChanged: (val) => setState(() => _selectedKategori = val),
    );
  }

  Widget _buildLayananCheckboxes() {
    return Column(
      children: [
        CheckboxListTile(
          value: _makanDiTempat,
          onChanged: (v) => setState(() => _makanDiTempat = v ?? false),
          title: const Text('Makan di tempat', style: TextStyle(fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: _kPrimaryBlue,
        ),
        CheckboxListTile(
          value: _dibungkus,
          onChanged: (v) => setState(() => _dibungkus = v ?? false),
          title: const Text('Dibungkus', style: TextStyle(fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: _kPrimaryBlue,
        ),
        CheckboxListTile(
          value: _pengantaran,
          onChanged: (v) => setState(() => _pengantaran = v ?? false),
          title: const Text('Pengantaran', style: TextStyle(fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: _kPrimaryBlue,
        ),
      ],
    );
  }

  Widget _buildVariasiSection() {
    return Column(
      children: [
        ..._variasiList.asMap().entries.map((entry) {
          final index = entry.key;
          final variasi = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NAMA VARIASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
                    if (_variasiList.length > 1)
                      GestureDetector(
                        onTap: () => setState(() => _variasiList.removeAt(index)),
                        child: const Icon(Icons.close, size: 20, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildTextField(controller: variasi.namaController, hint: 'Contoh: Topping Tambahan'),
                const SizedBox(height: 16),

                const Text('TIPE VARIASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _tipeButton(variasi, 'Wajib', 'wajib'),
                    const SizedBox(width: 8),
                    _tipeButton(variasi, 'Opsional', 'opsional'),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('PILIHAN VARIASI & HARGA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                ...variasi.pilihanList.asMap().entries.map((pilihanEntry) {
                  final i = pilihanEntry.key;
                  final p = pilihanEntry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.nama, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => variasi.pilihanList.removeAt(i)),
                          child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.harga > 0 ? '+ Rp ${_currencyFormat.format(p.harga)}' : 'Rp 0',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),

                GestureDetector(
                  onTap: () => _showAddPilihanDialog(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Tambah pilihan...', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ),
                        const Icon(Icons.add, color: _kPrimaryBlue, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: () => setState(() => _variasiList.add(_VariasiItem())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _kPrimaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimaryBlue.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: _kPrimaryBlue, size: 20),
                const SizedBox(width: 8),
                const Text('Tambah Variasi Menu', style: TextStyle(color: _kPrimaryBlue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddPilihanDialog(int index) {
    _pilihanNamaController.clear();
    _pilihanHargaController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Pilihan Variasi', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pilihanNamaController,
              decoration: const InputDecoration(labelText: 'Nama pilihan', hintText: 'Contoh: Keju Mozzarella'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pilihanHargaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Harga tambahan', hintText: '0', prefixText: 'Rp '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              _addVariasiPilihan(index);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimaryBlue),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _tipeButton(_VariasiItem variasi, String label, String value) {
    final isSelected = variasi.tipe == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => variasi.tipe = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimaryBlue.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _kPrimaryBlue : Colors.grey[300]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? _kPrimaryBlue : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccentOrange,
          disabledBackgroundColor: _kAccentOrange.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Helper models
// ──────────────────────────────────────────────

class _VariasiItem {
  TextEditingController namaController = TextEditingController();
  String tipe = 'opsional';
  List<_VariasiPilihan> pilihanList = [];
  
  void dispose() {
    namaController.dispose();
  }
}

class _VariasiPilihan {
  final String nama;
  final int harga;
  _VariasiPilihan({required this.nama, required this.harga});
}

// ──────────────────────────────────────────────
// Thousand separator formatter
// ──────────────────────────────────────────────

class _ThousandFormatter extends TextInputFormatter {
  final _format = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    final number = int.parse(digits);
    final formatted = _format.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
