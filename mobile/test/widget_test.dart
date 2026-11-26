import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/pelanggan/riwayat_pesanan_page.dart';
import 'package:acare_mobile/widgets/pesanan_card.dart';

import 'support/server_palsu.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Halaman riwayat pesanan memuat data dari server', (
    WidgetTester tester,
  ) async {
    ServerPalsu.aktif.tambahRiwayat(layanan: 'Cuci AC', status: 'selesai');
    ServerPalsu.aktif.tambahRiwayat(
      layanan: 'Service AC',
      status: 'dibatalkan',
      statusBayar: 'tertahan',
    );
    await ServerPalsu.masukPelanggan();
    await tester.pumpWidget(const MaterialApp(home: RiwayatPesananPage()));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Pesanan'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.byType(PesananCard), findsNWidgets(2));
    expect(find.text('#AC-000100'), findsOneWidget);
    expect(find.text('#AC-000101'), findsOneWidget);
  });

  testWidgets('Belum masuk / belum ada pesanan: keadaan kosong', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RiwayatPesananPage()));
    await tester.pumpAndSettle();

    expect(find.byType(PesananCard), findsNothing);
    expect(find.text('Belum ada pesanan'), findsOneWidget);
  });
}
