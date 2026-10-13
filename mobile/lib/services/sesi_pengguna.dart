import 'package:shared_preferences/shared_preferences.dart';

/// Data kecil yang diingat di perangkat: status login, nama, dan lokasi.
class SesiPengguna {
  static const _kMasuk = 'sudah_masuk';
  static const _kNama = 'nama';
  static const _kLokasi = 'lokasi';

  static Future<bool> sudahMasuk() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kMasuk) ?? false;
  }

  static Future<void> masuk(String nama) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMasuk, true);
    await p.setString(_kNama, nama.trim());
  }

  static Future<void> keluar() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kMasuk);
    await p.remove(_kNama);
  }

  static Future<String?> nama() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getString(_kNama);
    return (n == null || n.isEmpty) ? null : n;
  }

  static Future<String?> lokasi() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLokasi);
  }

  static Future<void> simpanLokasi(String lokasi) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLokasi, lokasi);
  }
}
