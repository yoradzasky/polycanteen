class KantinProfile {
  final int id;
  final String namaKantin;
  final String? fotoKantin;
  final double rating;

  KantinProfile({
    required this.id,
    required this.namaKantin,
    this.fotoKantin,
    required this.rating,
  });

  factory KantinProfile.fromJson(Map<String, dynamic> json) {
    return KantinProfile(
      id: json['id'] ?? 0,
      namaKantin: json['nama_kantin'] ?? '',
      fotoKantin: json['foto_kantin_path'] ?? json['foto_kantin'],
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_kantin': namaKantin,
      'foto_kantin': fotoKantin,
    };
  }
}
