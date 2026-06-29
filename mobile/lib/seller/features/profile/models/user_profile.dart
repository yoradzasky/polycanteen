class UserProfile {
  final int id;
  final String username;
  final String email;
  final String role;
  final String nama;
  final String? namaPemilik;
  final String? noTelp;
  final String? fotoProfil;

  UserProfile({
    required this.id,
    required this.username,
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
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      nama: json['nama'] ?? json['nama_pemilik'] ?? json['username'] ?? '',
      namaPemilik: json['nama_pemilik'],
      noTelp: json['no_telp'],
      fotoProfil: json['foto_profil_path'] ?? json['foto_profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'nama': nama,
      'nama_pemilik': namaPemilik,
      'no_telp': noTelp,
    };
  }
}
