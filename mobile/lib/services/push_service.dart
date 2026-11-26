import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Notifikasi push yang diterima dari server (lewat FCM).
class PesanPush {
  final String judul;
  final String isi;

  /// Jenis kejadian dari server, misal `tawaran` atau `teknisi_tiba`.
  final String? tipe;
  final int? idPesanan;

  const PesanPush({
    required this.judul,
    required this.isi,
    this.tipe,
    this.idPesanan,
  });
}

/// Sumber notifikasi push. Diganti tiruan di test (tanpa Firebase).
abstract class PlatformPush {
  /// Siapkan Firebase dan minta izin notifikasi. `false` bila tidak
  /// tersedia (misal Firebase belum dikonfigurasi) atau izin ditolak.
  Future<bool> siapkan();

  Future<String?> token();

  Stream<String> get tokenBaru;

  /// Pesan yang datang saat aplikasi sedang dibuka.
  Stream<PesanPush> get pesanDepan;
}

/// Firebase Cloud Messaging (Android, memakai google-services.json).
///
/// Memakai token FCM biasa (`getToken`/`onTokenRefresh`) yang pasti
/// diterima `message.token` di FCM HTTP v1. API baru `register()` /
/// `onRegistered` memberi Firebase Installation ID; pindah ke sana setelah
/// diuji di perangkat sungguhan.
// ignore_for_file: deprecated_member_use
class PlatformFirebase implements PlatformPush {
  bool _siap = false;

  @override
  Future<bool> siapkan() async {
    try {
      if (!_siap) {
        if (Firebase.apps.isEmpty) await Firebase.initializeApp();
        _siap = true;
      }
      final izin = await FirebaseMessaging.instance.requestPermission();
      return izin.authorizationStatus != AuthorizationStatus.denied;
    } on Object catch (e) {
      debugPrint('Notifikasi tidak tersedia: $e');
      return false;
    }
  }

  @override
  Future<String?> token() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } on Object catch (e) {
      debugPrint('Token notifikasi gagal diambil: $e');
      return null;
    }
  }

  @override
  Stream<String> get tokenBaru => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PesanPush> get pesanDepan => FirebaseMessaging.onMessage.map(
    (m) => PesanPush(
      judul: m.notification?.title ?? 'ACare',
      isi: m.notification?.body ?? '',
      tipe: m.data['tipe'] as String?,
      idPesanan: int.tryParse('${m.data['id_pesanan']}'),
    ),
  );
}

/// Mendaftarkan perangkat ke server supaya menerima notifikasi pesanan,
/// dan meneruskan notifikasi yang datang saat aplikasi dibuka.
///
/// Saat aplikasi di latar belakang atau tertutup, notifikasi ditampilkan
/// oleh Android sendiri; status pesanan tetap diperbarui lewat
/// pemeriksaan berkala begitu aplikasi dibuka.
class PushService {
  PushService._();

  static PlatformPush platform = PlatformFirebase();

  /// Dipanggil saat notifikasi datang ketika aplikasi sedang dibuka
  /// (Android tidak menampilkannya sendiri). Diatur di main.dart.
  static void Function(PesanPush pesan)? saatDiterima;

  static String? _token;
  static StreamSubscription<String>? _langgananToken;
  static StreamSubscription<PesanPush>? _langgananPesan;

  /// Token perangkat yang terdaftar di server; `null` bila belum.
  static String? get tokenTerdaftar => _token;

  /// Daftarkan perangkat untuk akun yang sedang masuk. Aman dipanggil
  /// berulang kali; kegagalan tidak mengganggu aplikasi.
  static Future<void> mulai() async {
    if (!await platform.siapkan()) return;
    final token = await platform.token();
    if (token != null) await _daftar(token);

    _langgananToken ??= platform.tokenBaru.listen(_daftar);
    _langgananPesan ??= platform.pesanDepan.listen(
      (p) => saatDiterima?.call(p),
    );
  }

  /// Berhenti menerima notifikasi untuk akun ini (sebelum keluar).
  static Future<void> berhenti() async {
    final token = _token;
    // Tidak perlu ditunggu; langganan berhenti menerima seketika.
    unawaited(_langgananToken?.cancel());
    unawaited(_langgananPesan?.cancel());
    _langgananToken = null;
    _langgananPesan = null;
    _token = null;
    if (token == null) return;
    try {
      await ApiClient.delete('/saya/perangkat', {'token': token});
    } on ApiException {
      // Token akan berpindah saat akun lain masuk di perangkat ini.
    }
  }

  static Future<void> _daftar(String token) async {
    try {
      await ApiClient.put('/saya/perangkat', {'token': token});
      _token = token;
    } on ApiException catch (e) {
      debugPrint('Perangkat gagal didaftarkan: ${e.pesan}');
    }
  }

  /// Lupakan pendaftaran tanpa menghubungi server (sesi sudah berakhir).
  static Future<void> lupakan() async {
    // Tidak perlu ditunggu; langganan berhenti menerima seketika.
    unawaited(_langgananToken?.cancel());
    unawaited(_langgananPesan?.cancel());
    _langgananToken = null;
    _langgananPesan = null;
    _token = null;
  }
}
