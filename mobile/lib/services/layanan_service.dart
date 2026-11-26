import 'package:flutter/foundation.dart';

import '../models/layanan.dart';
import 'api_client.dart';

/// Katalog layanan dan harga awal dari server (`GET /api/layanan`).
class LayananService {
  LayananService._();

  static final LayananService instance = LayananService._();

  /// Mulai dari katalog bawaan supaya halaman langsung terisi; diganti
  /// data server setelah [muat] berhasil.
  final ValueNotifier<List<Layanan>> katalog = ValueNotifier(katalogBawaan);

  /// Ambil katalog terbaru. Bila gagal (belum masuk atau tanpa internet),
  /// katalog yang ada tetap dipakai.
  Future<void> muat() async {
    if (await ApiClient.token() == null) return;
    try {
      final res = await ApiClient.get('/layanan');
      final data = (res['data'] as List?) ?? const [];
      if (data.isEmpty) return;
      katalog.value = [
        for (final j in data) Layanan.dariJson(j as Map<String, dynamic>),
      ];
    } on ApiException {
      // Tetap pakai katalog sebelumnya.
    }
  }

  void reset() => katalog.value = katalogBawaan;
}
