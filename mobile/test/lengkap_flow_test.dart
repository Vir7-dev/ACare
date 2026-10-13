import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acare_mobile/models/layanan.dart';
import 'package:acare_mobile/pages/main_shell.dart';
import 'package:acare_mobile/pages/mencari_teknisi_page.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> bukaShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
  }

  testWidgets('Riwayat -> Beri Ulasan -> kirim', (tester) async {
    await bukaShell(tester);
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beri Ulasan').first);
    await tester.pumpAndSettle();
    expect(find.text('Beri Ulasan Servis'), findsOneWidget);
    expect(find.text('Luar Biasa Memuaskan!'), findsOneWidget);

    // star pertama = chip rating teknisi, 5 berikutnya = bintang nilai
    await tester.tap(find.byIcon(Icons.star).at(3));
    await tester.pump();
    expect(find.text('Cukup Baik'), findsOneWidget);

    await tester.tap(find.text('Tepat Waktu'));
    await tester.pump();

    await tester.tap(find.text('Kirim Ulasan'));
    await tester.pumpAndSettle();
    expect(find.text('Beri Ulasan Servis'), findsNothing);
  });

  testWidgets('Pengaduan: validasi lalu kirim', (tester) async {
    await bukaShell(tester);
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Bantuan & Pengaduan'), findsOneWidget);

    await tester.tap(find.text('Kirim Laporan Pengaduan'));
    await tester.pump();
    expect(
      find.text('Pilih jenis masalah dan isi kronologi kendala'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hasil Servis Kurang Dingin'));
    await tester.enterText(find.byType(TextField), 'Teknisi datang terlambat.');
    await tester.pump();
    await tester.tap(find.text('Kirim Laporan Pengaduan'));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Bantuan & Pengaduan'), findsNothing);
  });

  testWidgets('Profil: tampil, simpan, dan keluar ke Masuk', (tester) async {
    SharedPreferences.setMockInitialValues({
      'sudah_masuk': true,
      'nama': 'Dina Safitri',
      'telepon': '083862865166',
      'email': 'sdina3066@gmail.com',
    });
    await bukaShell(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    expect(find.text('Kelola Profil'), findsOneWidget);
    expect(find.text('DS'), findsOneWidget);

    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();
    expect(find.text('Perubahan disimpan'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Keluar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang!'), findsOneWidget);
  });

  testWidgets('Mencari teknisi otomatis pindah ke tracking', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MencariTeknisiPage(
          layanan: daftarLayanan.first,
          lamaCari: const Duration(seconds: 2),
        ),
      ),
    );
    expect(find.text('Mencari Teknisi Terdekat...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);
  });
}
