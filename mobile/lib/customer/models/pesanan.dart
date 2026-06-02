/// Model untuk pesanan yang telah checkout
class Pesanan {
  final int id;
  final int mahasiswaId;
  final int kantinId;
  final String tipePesanan; // dine_in, takeaway, delivery
  final String statusPesanan; // pending, dibayar, diproses, siap, selesai
  final double totalHarga;
  final double biayaLayanan;
  final String? catatanPesanan;
  final String? alamatPengiriman;
  final double? latitude;
  final double? longitude;
  final String? nomorAntrian;
  final List<PesananDetail> details;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pesanan({
    required this.id,
    required this.mahasiswaId,
    required this.kantinId,
    required this.tipePesanan,
    required this.statusPesanan,
    required this.totalHarga,
    required this.biayaLayanan,
    this.catatanPesanan,
    this.alamatPengiriman,
    this.latitude,
    this.longitude,
    this.nomorAntrian,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get readable status pesanan
  String get statusLabel {
    switch (statusPesanan) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'dibayar':
        return 'Dibayar - Diproses';
      case 'diproses':
        return 'Sedang Diproses';
      case 'siap':
        return 'Siap Diambil';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return statusPesanan;
    }
  }

  /// Get readable tipe pesanan
  String get tipePesananLabel {
    switch (tipePesanan) {
      case 'dine_in':
        return 'Makan di Tempat';
      case 'takeaway':
        return 'Bungkus';
      case 'delivery':
        return 'Pengantaran';
      default:
        return tipePesanan;
    }
  }

  factory Pesanan.fromJson(Map<String, dynamic> json) {
    return Pesanan(
      id: json['id'] ?? 0,
      mahasiswaId: json['mahasiswa_id'] ?? 0,
      kantinId: json['kantin_id'] ?? 0,
      tipePesanan: json['tipe_pesanan'] ?? 'dine_in',
      statusPesanan: json['status_pesanan'] ?? 'pending',
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      biayaLayanan: (json['biaya_layanan'] ?? 0).toDouble(),
      catatanPesanan: json['catatan_pesanan'],
      alamatPengiriman: json['alamat_pengiriman'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      nomorAntrian: json['nomor_antrian'],
      details: json['details'] != null
          ? List<PesananDetail>.from(
              (json['details'] as List).map((x) => PesananDetail.fromJson(x)))
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mahasiswa_id': mahasiswaId,
        'kantin_id': kantinId,
        'tipe_pesanan': tipePesanan,
        'status_pesanan': statusPesanan,
        'total_harga': totalHarga,
        'biaya_layanan': biayaLayanan,
        'catatan_pesanan': catatanPesanan,
        'alamat_pengiriman': alamatPengiriman,
        'latitude': latitude,
        'longitude': longitude,
        'nomor_antrian': nomorAntrian,
        'details': details.map((d) => d.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Model untuk detail item dalam pesanan
/// SNAPSHOT HARGA: Menyimpan harga dan varian saat pembelian
class PesananDetail {
  final int id;
  final int pesananId;
  final int menuId;
  final double hargaSaatBeli;
  final int jumlahPesanan;
  final double subtotal;
  final List<VarianSnapshot>? varianSnapshot;
  final List<ToppingSnapshot>? toppingSnapshot;

  PesananDetail({
    required this.id,
    required this.pesananId,
    required this.menuId,
    required this.hargaSaatBeli,
    required this.jumlahPesanan,
    required this.subtotal,
    this.varianSnapshot,
    this.toppingSnapshot,
  });

  factory PesananDetail.fromJson(Map<String, dynamic> json) {
    return PesananDetail(
      id: json['id'] ?? 0,
      pesananId: json['pesanan_id'] ?? 0,
      menuId: json['menu_id'] ?? 0,
      hargaSaatBeli: (json['harga_saat_beli'] ?? 0).toDouble(),
      jumlahPesanan: json['jumlah_pesanan'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      varianSnapshot: json['varian_snapshot'] != null
          ? List<VarianSnapshot>.from(
              (json['varian_snapshot'] as List)
                  .map((x) => VarianSnapshot.fromJson(x)))
          : null,
      toppingSnapshot: json['topping_snapshot'] != null
          ? List<ToppingSnapshot>.from(
              (json['topping_snapshot'] as List)
                  .map((x) => ToppingSnapshot.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pesanan_id': pesananId,
        'menu_id': menuId,
        'harga_saat_beli': hargaSaatBeli,
        'jumlah_pesanan': jumlahPesanan,
        'subtotal': subtotal,
        'varian_snapshot': varianSnapshot?.map((v) => v.toJson()).toList(),
        'topping_snapshot': toppingSnapshot?.map((t) => t.toJson()).toList(),
      };
}

class VarianSnapshot {
  final int id;
  final String nama;
  final double harga;

  VarianSnapshot({
    required this.id,
    required this.nama,
    required this.harga,
  });

  factory VarianSnapshot.fromJson(Map<String, dynamic> json) {
    return VarianSnapshot(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: (json['harga'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
      };
}

class ToppingSnapshot {
  final int id;
  final String nama;
  final double harga;

  ToppingSnapshot({
    required this.id,
    required this.nama,
    required this.harga,
  });

  factory ToppingSnapshot.fromJson(Map<String, dynamic> json) {
    return ToppingSnapshot(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: (json['harga'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'harga': harga,
      };
}
