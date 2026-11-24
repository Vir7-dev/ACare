import 'package:shared_preferences/shared_preferences.dart';

/// Peran pengguna di aplikasi ACare.
enum UserRole {
  pelanggan('Pelanggan'),
  teknisi('Teknisi');

  const UserRole(this.label);

  /// Nilai teks yang disimpan di SharedPreferences / dikirim ke API.
  String get nilai => name;

  /// Label untuk ditampilkan di UI.
  final String label;

  /// Konversi dari nilai tersimpan; null bila tidak dikenali.
  static UserRole? dari(String? nilai) {
    for (final role in UserRole.values) {
      if (role.nilai == nilai) return role;
    }
    return null;
  }
}

/// Hasil percobaan masuk.
enum HasilLogin { berhasil, gagal, belumTerverifikasi }

/// Satu-satunya pintu untuk autentikasi.
///
/// Saat ini masih mock lokal (SharedPreferences) karena backend belum ada.
/// Halaman cukup memanggil kelas ini; jangan mengakses SharedPreferences
/// langsung, supaya nanti cukup mengganti isi method di sini ke panggilan API.
class AuthService {
  static const _kRole = 'role';
  static const _kMasuk = 'is_logged_in';
  static const _kTeknisiMenunggu = 'teknisi_menunggu_verifikasi';

  /// Mock: email apa pun yang tidak kosong dianggap ada.
  static const _placeholderEmail = 'pengguna@acare.id';

  AuthService._();

  /// Membaca peran yang tersimpan di perangkat.
  static Future<UserRole?> getSavedRole() async {
    // TODO(backend): ambil peran dari respons API / token, bukan penyimpanan lokal.
    final p = await SharedPreferences.getInstance();
    return UserRole.dari(p.getString(_kRole));
  }

  /// Validasi sesi: sudah login dan perannya dikenal.
  static Future<bool> isLoggedIn() async {
    // TODO(backend): panggil endpoint validasi sesi/refresh token.
    // Sesi dianggap tidak valid bila peran hilang, agar tidak macet di splash.
    final p = await SharedPreferences.getInstance();
    final masuk = p.getBool(_kMasuk) ?? false;
    if (!masuk) return false;
    return UserRole.dari(p.getString(_kRole)) != null;
  }

  /// Login mock: sukses bila email/nomor telepon dan password tidak kosong.
  /// Teknisi yang baru mendaftar ditolak sampai diverifikasi Admin (UC-02).
  static Future<HasilLogin> login(
    String email,
    String password,
    UserRole role,
  ) async {
    // TODO(backend): ganti dengan POST /api/login (email atau no. telepon,
    // password) dan simpan token hasil respons ke secure storage.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return HasilLogin.gagal;
    }

    final p = await SharedPreferences.getInstance();
    final menunggu = p.getStringList(_kTeknisiMenunggu) ?? const [];
    if (role == UserRole.teknisi &&
        menunggu.contains(email.trim().toLowerCase())) {
      return HasilLogin.belumTerverifikasi;
    }

    await p.setBool(_kMasuk, true);
    await p.setString(_kRole, role.nilai);
    return HasilLogin.berhasil;
  }

  /// Ubah kata sandi (mock). Mengembalikan pesan galat atau `null`.
  static Future<String?> ubahKataSandi({
    required String lama,
    required String baru,
  }) async {
    // TODO(backend): PUT /api/profil/kata-sandi; server memeriksa kata
    // sandi lama dan mengembalikan "Kata sandi lama tidak sesuai".
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (lama.isEmpty) return 'Kata sandi lama tidak sesuai';
    if (lama == baru) return 'Kata sandi baru harus berbeda dari yang lama';
    return null;
  }

  /// Registrasi teknisi mock. Akun baru berstatus menunggu verifikasi Admin.
  ///
  /// Data sensitif (password, dokumen, rekening) sengaja TIDAK disimpan di
  /// SharedPreferences; nanti dikirim langsung ke backend. Yang diingat
  /// hanya email, untuk meniru status "menunggu verifikasi" saat login.
  static Future<bool> registerTeknisi({
    required String nama,
    required String telepon,
    required String email,
    required String bank,
    required String nomorRekening,
    required String namaPemilik,
    required String jenisKendaraan,
    required String platNomor,
    required Map<String, String> dokumen,
  }) async {
    // TODO(backend): kirim payload beserta file dokumen (multipart) ke
    // POST /api/registrasi-teknisi; status verifikasi dikelola Admin.
    await Future<void>.delayed(const Duration(seconds: 1));
    final p = await SharedPreferences.getInstance();
    final menunggu = p.getStringList(_kTeknisiMenunggu) ?? <String>[];
    final kunci = email.trim().toLowerCase();
    if (!menunggu.contains(kunci)) {
      await p.setStringList(_kTeknisiMenunggu, [...menunggu, kunci]);
    }
    return true;
  }

  /// Menghapus sesi di perangkat.
  static Future<void> logout() async {
    // TODO(backend): panggil POST /api/logout dan hapus token.
    final p = await SharedPreferences.getInstance();
    await p.remove(_kMasuk);
    await p.remove(_kRole);
  }

  /// Email mock untuk pratinjauan di UI (bukan kredensial).
  static String get placeholderEmail => _placeholderEmail;
}
