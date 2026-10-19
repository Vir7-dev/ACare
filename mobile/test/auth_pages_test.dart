import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:acare_mobile/pages/daftar_page.dart';
import 'package:acare_mobile/pages/masuk_page.dart';
import 'package:acare_mobile/pages/splash_page.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('Splash pindah ke halaman Masuk', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));
    expect(find.text('Layanan AC'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang!'), findsOneWidget);
  });

  testWidgets('Masuk menolak form kosong', (tester) async {
    ukuranHp(tester);
    await tester.pumpWidget(const MaterialApp(home: MasukPage()));

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
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
