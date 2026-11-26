import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acare_mobile/pages/umum/ubah_kata_sandi_page.dart';
import 'package:acare_mobile/services/auth_service.dart';

import 'support/server_palsu.dart';

void main() {
  testWidgets('Ubah kata sandi: validasi aturan, kata sandi lama salah, '
      'lalu berhasil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await AuthService.login(
      'dina@gmail.com',
      ServerPalsu.sandiContoh,
      UserRole.pelanggan,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UbahKataSandiPage()),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    final kolom = find.byType(TextFormField);
    await tester.enterText(kolom.at(0), 'lama1234');
    await tester.enterText(kolom.at(1), 'pendek');
    await tester.enterText(kolom.at(2), 'beda');
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pump();
    expect(
      find.textContaining('minimal 8 karakter dan mengandung huruf'),
      findsOneWidget,
    );
    expect(find.text('Kata sandi tidak sama'), findsOneWidget);

    // Kata sandi lama salah: pesan dari server, halaman tetap terbuka.
    await tester.enterText(kolom.at(1), 'baru12345');
    await tester.enterText(kolom.at(2), 'baru12345');
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi lama tidak sesuai.'), findsOneWidget);
    expect(find.text('Buka'), findsNothing);

    await tester.enterText(kolom.at(0), ServerPalsu.sandiContoh);
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi berhasil diubah'), findsOneWidget);
    expect(find.text('Buka'), findsOneWidget);
    expect(ServerPalsu.aktif.akun.first['kata_sandi'], 'baru12345');
  });
}
