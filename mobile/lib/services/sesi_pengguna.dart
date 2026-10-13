import 'package:shared_preferences/shared_preferences.dart';

/// Data kecil yang diingat di perangkat: status login, nama, dan lokasi.
class SesiPengguna {
  static const _kMasuk = 'sudah_masuk';
  static const _kNama = 'nama';
  static const _kLokasi = 'lokasi';
  static const _kAkunNama = 'akun_nama';
  static const _kTelepon = 'telepon';
  static const _kEmail = 'email';

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

  /// Data akun yang didaftarkan; tetap tersimpan walau pengguna keluar,
  /// supaya Kelola Profil dan layar Masuk terisi otomatis.
  static Future<void> simpanAkun({
    required String nama,
    required String telepon,
    required String email,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAkunNama, nama.trim());
    await p.setString(_kTelepon, telepon.trim());
    await p.setString(_kEmail, email.trim());
    await p.setString(_kNama, nama.trim());
  }

  static Future<String?> akunNama() => _baca(_kAkunNama);
  static Future<String?> telepon() => _baca(_kTelepon);
  static Future<String?> email() => _baca(_kEmail);

  static Future<String?> _baca(String kunci) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(kunci);
    return (v == null || v.isEmpty) ? null : v;
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
