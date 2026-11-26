import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Alamat API Laravel. Atur saat menjalankan aplikasi, misalnya:
/// `flutter run --dart-define=API_URL=http://192.168.1.10:8000/api`
///
/// Bawaan `10.0.2.2` adalah alamat komputer (localhost) dilihat dari
/// emulator Android.
const String alamatApiBawaan = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);

/// Galat dari API atau koneksi, dengan pesan yang siap ditampilkan.
class ApiException implements Exception {
  /// Kode HTTP; 0 bila server tidak bisa dihubungi.
  final int status;
  final String pesan;

  /// Kode galat dari server, misal `belum_terverifikasi`.
  final String? kode;

  /// Galat per kolom form (validasi Laravel), misal `email`.
  final Map<String, String> galatKolom;

  /// Isi respons lengkap, untuk data tambahan seperti `alasan`.
  final Map<String, dynamic> data;

  const ApiException({
    required this.status,
    required this.pesan,
    this.kode,
    this.galatKolom = const {},
    this.data = const {},
  });

  bool get tanpaKoneksi => status == 0;

  @override
  String toString() => pesan;
}

/// Penyimpanan kecil yang terenkripsi (token & data akun).
abstract class PenyimpananAman {
  Future<String?> baca(String kunci);
  Future<void> tulis(String kunci, String nilai);
  Future<void> hapus(String kunci);
}

/// Keychain (iOS) / Keystore (Android).
class PenyimpananPerangkat implements PenyimpananAman {
  static const _s = FlutterSecureStorage();

  @override
  Future<String?> baca(String kunci) => _s.read(key: kunci);

  @override
  Future<void> tulis(String kunci, String nilai) =>
      _s.write(key: kunci, value: nilai);

  @override
  Future<void> hapus(String kunci) => _s.delete(key: kunci);
}

/// Penyimpanan di memori, dipakai unit test.
class PenyimpananMemori implements PenyimpananAman {
  final Map<String, String> isi = {};

  @override
  Future<String?> baca(String kunci) async => isi[kunci];

  @override
  Future<void> tulis(String kunci, String nilai) async => isi[kunci] = nilai;

  @override
  Future<void> hapus(String kunci) async => isi.remove(kunci);
}

/// Satu-satunya pintu ke API Laravel: menambah token, mengubah respons
/// JSON, dan menyeragamkan galat menjadi [ApiException].
class ApiClient {
  ApiClient._();

  static const kunciToken = 'token_api';

  static String alamat = alamatApiBawaan;
  static http.Client klien = http.Client();
  static PenyimpananAman penyimpanan = PenyimpananPerangkat();
  static Duration batasWaktu = const Duration(seconds: 20);

  /// Bertambah setiap kali server menolak token (sesi kedaluwarsa atau
  /// akun diblokir), supaya aplikasi bisa membawa pengguna ke halaman masuk.
  static final ValueNotifier<int> sesiBerakhir = ValueNotifier(0);

  static Future<String?> token() => penyimpanan.baca(kunciToken);
  static Future<void> simpanToken(String t) => penyimpanan.tulis(kunciToken, t);
  static Future<void> hapusToken() => penyimpanan.hapus(kunciToken);

  static Future<Map<String, dynamic>> get(String path) => _kirim('GET', path);

  static Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? isi,
  ]) => _kirim('POST', path, isi);

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> isi,
  ) => _kirim('PUT', path, isi);

  static Future<Map<String, dynamic>> delete(
    String path, [
    Map<String, dynamic>? isi,
  ]) => _kirim('DELETE', path, isi);

  /// Kirim form dengan berkas (multipart). [berkas]: nama kolom -> file,
  /// misal `dokumen[ktp]`.
  static Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, String> kolom = const {},
    Map<String, XFile> berkas = const {},
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    await _header(req.headers, json: false);
    req.fields.addAll(kolom);
    for (final e in berkas.entries) {
      final nama = e.value.name.isEmpty ? 'berkas.jpg' : e.value.name;
      req.files.add(
        http.MultipartFile.fromBytes(
          e.key,
          await e.value.readAsBytes(),
          filename: nama,
        ),
      );
    }
    return _jalankan(() async {
      final res = await klien.send(req).timeout(batasWaktu);
      return http.Response.fromStream(res);
    }, req.headers.containsKey('Authorization'));
  }

  static Uri _uri(String path) => Uri.parse('$alamat$path');

  static Future<void> _header(Map<String, String> h, {bool json = true}) async {
    h['Accept'] = 'application/json';
    if (json) h['Content-Type'] = 'application/json';
    final t = await token();
    if (t != null) h['Authorization'] = 'Bearer $t';
  }

  static Future<Map<String, dynamic>> _kirim(
    String metode,
    String path, [
    Map<String, dynamic>? isi,
  ]) async {
    final h = <String, String>{};
    await _header(h);
    final body = isi == null ? null : jsonEncode(isi);
    return _jalankan(() {
      final uri = _uri(path);
      final f = switch (metode) {
        'GET' => klien.get(uri, headers: h),
        'PUT' => klien.put(uri, headers: h, body: body),
        'DELETE' => klien.delete(uri, headers: h, body: body),
        _ => klien.post(uri, headers: h, body: body),
      };
      return f.timeout(batasWaktu);
    }, h.containsKey('Authorization'));
  }

  static Future<Map<String, dynamic>> _jalankan(
    Future<http.Response> Function() kirim,
    bool pakaiToken,
  ) async {
    final http.Response res;
    try {
      res = await kirim();
    } on TimeoutException {
      throw const ApiException(
        status: 0,
        pesan: 'Server terlalu lama merespons. Coba lagi sebentar lagi.',
      );
    } catch (_) {
      throw const ApiException(
        status: 0,
        pesan: 'Tidak bisa terhubung ke server. Periksa koneksi internet kamu.',
      );
    }

    Map<String, dynamic> data = {};
    if (res.body.isNotEmpty) {
      try {
        final d = jsonDecode(res.body);
        if (d is Map<String, dynamic>) data = d;
      } on FormatException {
        // Bukan JSON (mis. halaman galat server); pakai pesan umum.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final kode = data['kode'] as String?;
    if (pakaiToken && (res.statusCode == 401 || kode == 'akun_diblokir')) {
      await hapusToken();
      sesiBerakhir.value++;
    }

    final galat = <String, String>{};
    final errors = data['errors'];
    if (errors is Map) {
      errors.forEach((k, v) {
        if (v is List && v.isNotEmpty) galat['$k'] = '${v.first}';
      });
    }

    throw ApiException(
      status: res.statusCode,
      pesan:
          (galat.isNotEmpty
              ? galat.values.first
              : data['message'] as String?) ??
          _pesanUmum(res.statusCode),
      kode: kode,
      galatKolom: galat,
      data: data,
    );
  }

  static String _pesanUmum(int status) => switch (status) {
    401 => 'Sesi kamu sudah berakhir. Silakan masuk lagi.',
    403 => 'Kamu tidak punya akses untuk tindakan ini.',
    404 => 'Data tidak ditemukan.',
    429 => 'Terlalu banyak permintaan. Coba lagi sebentar lagi.',
    _ => 'Terjadi kesalahan di server. Coba lagi nanti.',
  };
}
