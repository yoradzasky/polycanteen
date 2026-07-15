class UserProfile {
  final int id;
  final String namaLengkap;
  final String email;
  final String role;
  final String nama;
  final String? namaPemilik;
  final String? noTelp;
  final String? fotoProfil;

  UserProfile({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.nama,
    this.namaPemilik,
    this.noTelp,
    this.fotoProfil,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      nama: json['nama'] ?? json['nama_pemilik'] ?? json['nama_lengkap'] ?? '',
      namaPemilik: json['nama_pemilik'],
      noTelp: json['no_telp'],
      fotoProfil: json['foto_profil_path'] ?? json['foto_profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_lengkap': namaLengkap,
      'email': email,
      'nama': nama,
      'nama_pemilik': namaPemilik,
      'no_telp': noTelp,
    };
  }
}
