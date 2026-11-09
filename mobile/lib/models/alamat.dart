/// Alamat layanan milik pelanggan, lengkap dengan titik koordinat di peta.
/// Padanan tabel `lokasi` (T009) di SKPPL.
class AlamatTersimpan {
  final String id;

  /// Maksimal 10 karakter, mengikuti `label_alamat VARCHAR(10)`.
  final String label;
  final String alamatLengkap;
  final double latitude;
  final double longitude;

  const AlamatTersimpan({
    required this.id,
    required this.label,
    required this.alamatLengkap,
    required this.latitude,
    required this.longitude,
  });

  static const int maksLabel = 10;

  AlamatTersimpan salin({
    String? label,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
  }) => AlamatTersimpan(
    id: id,
    label: label ?? this.label,
    alamatLengkap: alamatLengkap ?? this.alamatLengkap,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'alamat_lengkap': alamatLengkap,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory AlamatTersimpan.fromJson(Map<String, dynamic> j) => AlamatTersimpan(
    id: j['id'] as String,
    label: j['label'] as String,
    alamatLengkap: j['alamat_lengkap'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
  );
}

/// Satu hasil pencarian tempat di OpenStreetMap (Nominatim).
class HasilTempat {
  final String nama;
  final double latitude;
  final double longitude;

  const HasilTempat({
    required this.nama,
    required this.latitude,
    required this.longitude,
  });
}
