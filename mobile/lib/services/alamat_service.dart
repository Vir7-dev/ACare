import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Alamat layanan tersimpan milik pelanggan (UC-08, tabel `lokasi`).
class AlamatTersimpan {
  final int id;
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

  factory AlamatTersimpan.dariJson(Map<String, dynamic> j) => AlamatTersimpan(
    id: j['id'] as int,
    label: j['label'] as String? ?? '',
    alamatLengkap: j['alamat_lengkap'] as String? ?? '',
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
  );
}

/// Sumber tunggal alamat tersimpan pelanggan, lewat API `/api/alamat`.
///
/// Aturan "alamat yang dipakai pesanan" dijaga server: alamat yang sudah
/// pernah dipakai tetap bisa diubah (server menyimpannya sebagai alamat baru
/// dengan id baru), dan alamat pesanan aktif tidak bisa dihapus.
class AlamatService {
  AlamatService._();

  static final AlamatService instance = AlamatService._();

  final ValueNotifier<List<AlamatTersimpan>> daftar = ValueNotifier(const []);

  /// Muat ulang daftar dari server. Diam bila belum masuk atau gagal,
  /// supaya daftar terakhir tetap tampil.
  Future<void> muat() async {
    if (await ApiClient.token() == null) return;
    try {
      final res = await ApiClient.get('/alamat');
      daftar.value = [
        for (final j in (res['data'] as List? ?? const []))
          AlamatTersimpan.dariJson(j as Map<String, dynamic>),
      ];
    } on ApiException {
      // Tetap tampilkan daftar terakhir.
    }
  }

  /// Simpan alamat baru. Melempar [ApiException] bila ditolak server.
  Future<AlamatTersimpan> tambah({
    required String label,
    required String alamatLengkap,
    required double latitude,
    required double longitude,
  }) async {
    final res = await ApiClient.post(
      '/alamat',
      _isi(label, alamatLengkap, latitude, longitude),
    );
    final baru = AlamatTersimpan.dariJson(res['data'] as Map<String, dynamic>);
    daftar.value = [...daftar.value, baru];
    return baru;
  }

  /// Ubah alamat; hasilnya bisa ber-id baru bila alamat lama sudah pernah
  /// dipakai pesanan. Melempar [ApiException] bila ditolak server.
  Future<AlamatTersimpan> ubah(
    AlamatTersimpan lama, {
    required String label,
    required String alamatLengkap,
    required double latitude,
    required double longitude,
  }) async {
    final res = await ApiClient.put(
      '/alamat/${lama.id}',
      _isi(label, alamatLengkap, latitude, longitude),
    );
    final baru = AlamatTersimpan.dariJson(res['data'] as Map<String, dynamic>);
    daftar.value = [
      for (final a in daftar.value) a.id == lama.id ? baru : a,
    ];
    return baru;
  }

  /// Hapus alamat; mengembalikan pesan galat atau `null` bila berhasil.
  Future<String?> hapus(AlamatTersimpan alamat) async {
    try {
      await ApiClient.delete('/alamat/${alamat.id}');
    } on ApiException catch (e) {
      return e.pesan;
    }
    daftar.value = daftar.value.where((a) => a.id != alamat.id).toList();
    return null;
  }

  /// Kosongkan daftar (saat keluar akun).
  void reset() => daftar.value = const [];

  Map<String, dynamic> _isi(
    String label,
    String alamatLengkap,
    double latitude,
    double longitude,
  ) => {
    'label': label.trim(),
    'alamat_lengkap': alamatLengkap.trim(),
    'latitude': latitude,
    'longitude': longitude,
  };
}
