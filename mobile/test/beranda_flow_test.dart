import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/umum/main_shell.dart';
import 'package:acare_mobile/services/alamat_service.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  Future<void> bukaShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
  }

  testWidgets('Beranda menampilkan seluruh bagian', (tester) async {
    await bukaShell(tester);

    expect(find.text('Selamat Datang, Pengguna!'), findsOneWidget);
    expect(find.text('SERVIS TERAKHIR'), findsOneWidget);
    expect(find.text('Kategori Layanan'), findsOneWidget);
    expect(find.text('Sedang Berlangsung'), findsOneWidget);
  });

  testWidgets('Navigasi bawah pindah ke Riwayat', (tester) async {
    await bukaShell(tester);

    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Pesanan'), findsOneWidget);
  });

  testWidgets('Lihat Detail -> Pilih -> buka form pesanan', (tester) async {
    await bukaShell(tester);

    await tester.tap(find.text('Lihat Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Layanan AC'), findsOneWidget);

    await tester.tap(find.text('Pilih').first);
    await tester.pumpAndSettle();
    // Alur sekarang: pilih layanan -> form detail pesanan.
    expect(find.text('Detail Pesanan'), findsOneWidget);
  });

  testWidgets('Pilih Lokasi membuka daftar dan menyimpan pilihan', (
    tester,
  ) async {
    AlamatService.instance.reset();
    await tester.runAsync(() async {
      final s = AlamatService.instance;
      await s.tambah(
        label: 'Rumah',
        alamatLengkap: 'Batu Aji, Batam',
        latitude: 1.05,
        longitude: 103.97,
      );
      await s.tambah(
        label: 'Kantor',
        alamatLengkap: 'Nagoya, Batam',
        latitude: 1.14,
        longitude: 104.01,
      );
    });
    await bukaShell(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rumah'));
    await tester.pumpAndSettle();
    expect(find.text('Nagoya, Batam'), findsOneWidget);

    await tester.tap(find.text('Kantor'));
    await tester.pumpAndSettle();

    // label tombol berubah ke alamat terpilih
    expect(find.text('Kantor'), findsOneWidget);
    expect(find.text('Pilih Lokasi'), findsNothing);
  });

  testWidgets('Lonceng membuka daftar notifikasi', (tester) async {
    await bukaShell(tester);

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Teknisi menuju lokasimu'), findsOneWidget);
  });
}
