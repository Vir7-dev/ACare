import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:acare_mobile/pages/pelanggan/daftar_page.dart';
import 'package:acare_mobile/pages/pelanggan/masuk_page.dart';
import 'package:acare_mobile/pages/role_select_page.dart';
import 'package:acare_mobile/pages/teknisi/kelola_profil_teknisi_page.dart';
import 'package:acare_mobile/pages/umum/splash_page.dart';
import 'package:acare_mobile/services/api_client.dart';
import 'package:acare_mobile/services/auth_service.dart';

import 'support/server_palsu.dart';

/// Perilaku aplikasi terhadap jawaban API autentikasi.
void main() {
  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('Daftar: email & nomor yang sudah dipakai ditandai di kolomnya', (
    tester,
  ) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: DaftarPage()));

    final f = find.byType(TextFormField);
    await tester.enterText(f.at(0), 'Orang Lain');
    await tester.enterText(f.at(1), '+62 811-1111-1111');
    await tester.enterText(f.at(2), 'DINA@gmail.com');
    await tester.enterText(f.at(3), 'rahasia123');
    await tester.enterText(f.at(4), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Email sudah terdaftar.'), findsOneWidget);
    expect(find.text('Nomor telepon sudah terdaftar.'), findsOneWidget);
    // Tetap di halaman Daftar, tidak ada akun baru.
    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(ServerPalsu.aktif.akun, hasLength(2));
  });

  testWidgets('Masuk: kata sandi salah menampilkan pesan server', (
    tester,
  ) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: MasukPage()));

    await tester.enterText(find.byType(TextFormField).at(0), 'dina@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah12345');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(
      find.text('Email/nomor telepon atau kata sandi salah.'),
      findsOneWidget,
    );
    expect(await ApiClient.token(), isNull);
  });

  testWidgets('Masuk: teknisi yang ditolak melihat alasan dari Admin', (
    tester,
  ) async {
    ukuranHp(tester);
    final t = ServerPalsu.aktif.akun[1]['teknisi'] as Map<String, dynamic>;
    t['status_verifikasi'] = 'ditolak';
    t['alasan_penolakan'] = 'Foto KTP buram.';

    await tester.pumpWidget(
      const MaterialApp(home: MasukPage(role: UserRole.teknisi)),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'teknisi@acare.id',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Pendaftaran ditolak'), findsOneWidget);
    expect(find.textContaining('Foto KTP buram.'), findsOneWidget);
  });

  testWidgets('Splash: token yang sudah tidak berlaku membawa ke pilih peran', (
    tester,
  ) async {
    await AuthService.login(
      'dina@gmail.com',
      ServerPalsu.sandiContoh,
      UserRole.pelanggan,
    );
    // Server melupakan token (kedaluwarsa atau dicabut).
    ServerPalsu.aktif.token.clear();
    AuthService.akun.value = null;

    await tester.pumpWidget(const MaterialApp(home: SplashPage()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPage), findsOneWidget);
    expect(await ApiClient.token(), isNull);
  });

  testWidgets('Splash: tanpa internet tetap masuk dengan data terakhir', (
    tester,
  ) async {
    await AuthService.login(
      'dina@gmail.com',
      ServerPalsu.sandiContoh,
      UserRole.pelanggan,
    );
    expect(
      await tester.runAsync(() async {
        ApiClient.klien = _KlienPutus();
        return AuthService.isLoggedIn();
      }),
      isTrue,
    );
    expect(AuthService.akun.value?.nama, 'Dina Safitri');
  });

  testWidgets('Profil teknisi: data dari akun dan perubahan dikirim ke server', (
    tester,
  ) async {
    ukuranHp(tester);
    await AuthService.login(
      'teknisi@acare.id',
      ServerPalsu.sandiContoh,
      UserRole.teknisi,
    );
    await tester.pumpWidget(
      const MaterialApp(home: KelolaProfilTeknisiPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rizky Pratama'), findsWidgets);
    expect(find.text('Honda Beat'), findsOneWidget);

    await tester.tap(find.text('Edit Profil'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Jenis Kendaraan'),
      'Yamaha NMAX',
    );
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Perubahan disimpan'), findsOneWidget);
    final t = ServerPalsu.aktif.akun[1]['teknisi'] as Map<String, dynamic>;
    expect(t['jenis_kendaraan'], 'Yamaha NMAX');
    expect(AuthService.akun.value?.teknisi?.jenisKendaraan, 'Yamaha NMAX');
  });
}

/// Klien yang selalu gagal terhubung, meniru HP tanpa internet.
class _KlienPutus extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(http.ClientException('Tidak ada koneksi'));
}
