import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/akun.dart';
import 'alamat_service.dart';
import 'api_client.dart';
import 'sesi_pengguna.dart';

/// Peran pengguna di aplikasi ACare.
enum UserRole {
  pelanggan('Pelanggan'),
  teknisi('Teknisi');

  const UserRole(this.label);

  /// Nilai teks yang dikirim ke API.
  String get nilai => name;

  /// Label untuk ditampilkan di UI.
  final String label;

  /// Konversi dari nilai teks; null bila tidak dikenali.
  static UserRole? dari(String? nilai) {
    for (final role in UserRole.values) {
      if (role.nilai == nilai) return role;
    }
    return null;
  }
}

/// Status hasil percobaan masuk.
enum HasilLogin { berhasil, gagal, belumTerverifikasi, ditolak }

/// Hasil masuk beserta pesan yang siap ditampilkan.
class HasilMasuk {
  final HasilLogin status;
  final String pesan;

  /// Alasan Admin menolak pendaftaran teknisi.
  final String? alasan;

  const HasilMasuk(this.status, {this.pesan = '', this.alasan});

  bool get berhasil => status == HasilLogin.berhasil;
}

/// Satu-satunya pintu untuk autentikasi dan data akun (API Laravel).
/// Halaman cukup memanggil kelas ini, tidak memanggil API langsung.
class AuthService {
  AuthService._();

  static const _kAkun = 'akun';

  /// Akun yang sedang masuk; `null` bila belum masuk.
  static final ValueNotifier<Akun?> akun = ValueNotifier(null);

  /// Peran akun yang tersimpan di perangkat.
  static Future<UserRole?> getSavedRole() async {
    final a = akun.value ?? await _akunTersimpan();
    return UserRole.dari(a?.role);
  }

  /// Memeriksa sesi saat aplikasi dibuka. Data akun diperbarui dari server;
  /// bila server tidak bisa dihubungi, data terakhir di perangkat dipakai
  /// supaya aplikasi tetap bisa dibuka tanpa internet.
  static Future<bool> isLoggedIn() async {
    if (await ApiClient.token() == null) return false;
    try {
      await muatUlangAkun();
      return true;
    } on ApiException catch (e) {
      if (e.tanpaKoneksi || e.status >= 500) {
        final a = await _akunTersimpan();
        akun.value = a;
        return a != null;
      }
      await _bersihkan();
      return false;
    }
  }

  /// Ambil data akun terbaru dari server.
  static Future<Akun> muatUlangAkun() async {
    final res = await ApiClient.get('/saya');
    return _simpanAkun(Akun.dariJson(res['data'] as Map<String, dynamic>));
  }

  /// Masuk dengan email atau nomor telepon.
  static Future<HasilMasuk> login(
    String identitas,
    String password,
    UserRole role,
  ) async {
    try {
      final res = await ApiClient.post('/masuk', {
        'identitas': identitas.trim(),
        'kata_sandi': password,
        'peran': role.nilai,
        'nama_perangkat': 'aplikasi-mobile',
      });
      await ApiClient.simpanToken(res['token'] as String);
      await _simpanAkun(
        Akun.dariJson(res['pengguna'] as Map<String, dynamic>),
      );
      return const HasilMasuk(HasilLogin.berhasil);
    } on ApiException catch (e) {
      return switch (e.kode) {
        'belum_terverifikasi' => HasilMasuk(
          HasilLogin.belumTerverifikasi,
          pesan: e.pesan,
        ),
        'verifikasi_ditolak' => HasilMasuk(
          HasilLogin.ditolak,
          pesan: e.pesan,
          alasan: e.data['alasan'] as String?,
        ),
        _ => HasilMasuk(HasilLogin.gagal, pesan: e.pesan),
      };
    }
  }

  /// Daftar akun pelanggan. Melempar [ApiException] bila ditolak server
  /// (misal email sudah terdaftar); galat per kolom ada di `galatKolom`.
  static Future<void> daftarPelanggan({
    required String nama,
    required String telepon,
    required String email,
    required String kataSandi,
  }) async {
    await ApiClient.post('/daftar', {
      'nama': nama.trim(),
      'no_telepon': telepon.trim(),
      'email': email.trim(),
      'kata_sandi': kataSandi,
    });
    await SesiPengguna.simpanAkun(nama: nama, telepon: telepon, email: email);
  }

  /// Registrasi teknisi beserta dokumen. Akun menunggu verifikasi Admin.
  /// Melempar [ApiException] bila ditolak server.
  static Future<void> registerTeknisi({
    required String nama,
    required String telepon,
    required String email,
    required String kataSandi,
    required String bank,
    required String nomorRekening,
    required String namaPemilik,
    required String jenisKendaraan,
    required String platNomor,
    required Map<String, XFile> dokumen,
  }) async {
    await ApiClient.multipart(
      '/daftar/teknisi',
      kolom: {
        'nama': nama.trim(),
        'no_telepon': telepon.trim(),
        'email': email.trim(),
        'kata_sandi': kataSandi,
        'jenis_kendaraan': jenisKendaraan,
        'plat_nomor': platNomor,
        'nama_bank': bank,
        'no_rekening': nomorRekening.trim(),
        'atas_nama': namaPemilik.trim(),
      },
      berkas: {
        for (final e in dokumen.entries) 'dokumen[${e.key}]': e.value,
      },
    );
    await SesiPengguna.simpanAkun(nama: nama, telepon: telepon, email: email);
  }

  /// Ubah sebagian data profil. Kolom bernilai `null` tidak diubah.
  /// Melempar [ApiException] bila ditolak server.
  static Future<Akun> ubahProfil({
    String? nama,
    String? telepon,
    String? email,
    String? jenisKendaraan,
    String? platNomor,
    String? deskripsi,
  }) async {
    final res = await ApiClient.put('/saya', {
      'nama': ?nama?.trim(),
      'no_telepon': ?telepon?.trim(),
      'email': ?email?.trim(),
      'jenis_kendaraan': ?jenisKendaraan?.trim(),
      'plat_nomor': ?platNomor?.trim(),
      'deskripsi': ?deskripsi?.trim(),
    });
    return _simpanAkun(Akun.dariJson(res['data'] as Map<String, dynamic>));
  }

  /// Unggah foto profil baru. Melempar [ApiException] bila gagal.
  static Future<Akun> ubahFoto(XFile foto) async {
    final res = await ApiClient.multipart('/saya/foto', berkas: {'foto': foto});
    return _simpanAkun(Akun.dariJson(res['data'] as Map<String, dynamic>));
  }

  /// Ubah kata sandi. Mengembalikan pesan galat atau `null` bila berhasil.
  /// Perangkat lain yang masuk dengan akun ini akan dikeluarkan.
  static Future<String?> ubahKataSandi({
    required String lama,
    required String baru,
  }) async {
    try {
      await ApiClient.put('/saya/kata-sandi', {
        'kata_sandi_lama': lama,
        'kata_sandi_baru': baru,
        'kata_sandi_baru_confirmation': baru,
      });
      return null;
    } on ApiException catch (e) {
      return e.pesan;
    }
  }

  /// Keluar dari perangkat ini. Data lokal tetap dihapus walau server
  /// tidak bisa dihubungi.
  static Future<void> logout() async {
    try {
      await ApiClient.post('/keluar');
    } on ApiException {
      // Token akan kedaluwarsa sendiri di server.
    }
    await _bersihkan();
  }

  /// Hapus sesi di perangkat (dipakai juga saat sesi berakhir).
  static Future<void> bersihkanSesi() => _bersihkan();

  static Future<Akun> _simpanAkun(Akun a) async {
    akun.value = a;
    await ApiClient.penyimpanan.tulis(_kAkun, jsonEncode(a.keJson()));
    // Nama, telepon, dan email juga diingat untuk beranda & form masuk.
    await SesiPengguna.simpanAkun(
      nama: a.nama,
      telepon: a.noTelepon,
      email: a.email,
    );
    await SesiPengguna.masuk(a.nama);
    return a;
  }

  static Future<Akun?> _akunTersimpan() async {
    final s = await ApiClient.penyimpanan.baca(_kAkun);
    if (s == null) return null;
    try {
      return Akun.dariJson(jsonDecode(s) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  static Future<void> _bersihkan() async {
    akun.value = null;
    // Data milik akun sebelumnya tidak boleh terlihat akun berikutnya.
    AlamatService.instance.reset();
    await ApiClient.hapusToken();
    await ApiClient.penyimpanan.hapus(_kAkun);
    await SesiPengguna.keluar();
  }
}
