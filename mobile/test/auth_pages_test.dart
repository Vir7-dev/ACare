import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:acare_mobile/pages/pelanggan/daftar_page.dart';
import 'package:acare_mobile/pages/pelanggan/masuk_page.dart';
import 'package:acare_mobile/pages/role_select_page.dart';
import 'package:acare_mobile/pages/umum/splash_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('Splash membuka pemilihan peran saat belum masuk', (
    tester,
  ) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));
    expect(find.text('Layanan AC'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Masuk sebagai'), findsOneWidget);
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Teknisi'), findsOneWidget);
  });

  testWidgets('Pemilihan peran lanjut ke Masuk sesuai peran', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: RoleSelectPage()));

    await tester.tap(find.text('Teknisi'));
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang!'), findsOneWidget);
    // Halaman peran diganti, bukan ditumpuk: kembali tidak balik ke pemilihan.
    expect(find.byType(RoleSelectPage), findsNothing);
  });

  testWidgets('Masuk menolak form kosong', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: MasukPage()));

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('Masuk membuka halaman Daftar', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: MasukPage()));

    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Akun'), findsOneWidget);
  });

  testWidgets('Daftar memvalidasi kata sandi tidak sama', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: DaftarPage()));

    final field = find.byType(TextFormField);
    await tester.enterText(field.at(0), 'Nadya');
    await tester.enterText(field.at(1), '081234567890');
    await tester.enterText(field.at(2), 'dina@gmail.com');
    await tester.enterText(field.at(3), 'rahasia123');
    await tester.enterText(field.at(4), 'beda12345');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pump();

    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
  });
}
