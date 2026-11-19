import 'package:flutter/foundation.dart';

import 'order_service.dart';

/// Alamat layanan tersimpan milik pelanggan (UC-08).
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

  AlamatTersimpan copyWith({
    String? label,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
  }) {
    return AlamatTersimpan(
      id: id,
      label: label ?? this.label,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Sumber tunggal alamat tersimpan pelanggan (data tiruan).
// TODO(backend): ganti dengan API alamat (tabel `lokasi`).
class AlamatService {
  AlamatService._();

  static final AlamatService instance = AlamatService._();

  final ValueNotifier<List<AlamatTersimpan>> daftar = ValueNotifier(
    _daftarAwal,
  );

  int _idBerikutnya = 2;

  void simpan(AlamatTersimpan alamat) {
    final ada = daftar.value.any((a) => a.id == alamat.id);
    daftar.value = ada
        ? [for (final a in daftar.value) a.id == alamat.id ? alamat : a]
        : [...daftar.value, alamat];
  }

  /// Buat alamat baru dengan id berikutnya.
  AlamatTersimpan tambah({
    required String label,
    required String alamatLengkap,
    required double latitude,
    required double longitude,
  }) {
    final baru = AlamatTersimpan(
      id: _idBerikutnya++,
      label: label,
      alamatLengkap: alamatLengkap,
      latitude: latitude,
      longitude: longitude,
    );
    simpan(baru);
    return baru;
  }

  /// Alamat yang sedang dipakai pesanan aktif tidak boleh diubah/dihapus.
  bool dipakaiPesananAktif(AlamatTersimpan alamat) {
    final aktif = OrderService.instance.pesananAktif.value;
    return aktif != null && aktif.alamat == alamat.alamatLengkap;
  }

  /// Hapus alamat; mengembalikan pesan galat atau `null` bila berhasil.
  String? hapus(AlamatTersimpan alamat) {
    if (dipakaiPesananAktif(alamat)) {
      return 'Alamat tidak dapat dihapus karena sedang digunakan pada '
          'pesanan aktif';
    }
    daftar.value = daftar.value.where((a) => a.id != alamat.id).toList();
    return null;
  }

  void reset() {
    daftar.value = _daftarAwal;
    _idBerikutnya = 2;
  }

  static const _daftarAwal = [
    AlamatTersimpan(
      id: 1,
      label: 'Rumah',
      alamatLengkap: 'Perumahan Batu Aji Blok C No. 12, Batam',
      latitude: 1.0436,
      longitude: 103.9806,
    ),
  ];
}
