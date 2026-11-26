import 'dart:async';

import 'package:acare_mobile/services/push_service.dart';

/// Tiruan FCM untuk test: token tetap, pesan dikirim lewat [kirim].
class PushPalsu implements PlatformPush {
  /// Tiruan yang sedang terpasang di [PushService.platform].
  static late PushPalsu aktif;

  static PushPalsu pasang() => aktif = PushPalsu();

  bool izin = true;
  String tokenSaatIni = 'token-fcm-uji';

  final _tokenBaru = StreamController<String>.broadcast();
  final _pesan = StreamController<PesanPush>.broadcast();

  @override
  Future<bool> siapkan() async => izin;

  @override
  Future<String?> token() async => tokenSaatIni;

  @override
  Stream<String> get tokenBaru => _tokenBaru.stream;

  @override
  Stream<PesanPush> get pesanDepan => _pesan.stream;

  /// Firebase memberi token baru (misal setelah aplikasi dipasang ulang).
  void gantiToken(String token) {
    tokenSaatIni = token;
    _tokenBaru.add(token);
  }

  /// Notifikasi datang saat aplikasi dibuka.
  void kirim(PesanPush pesan) => _pesan.add(pesan);
}
