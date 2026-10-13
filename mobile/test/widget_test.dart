import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/riwayat_pesanan_page.dart';
import 'package:acare_mobile/widgets/pesanan_card.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Halaman riwayat pesanan tampil', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RiwayatPesananPage()),
    );

    expect(find.text('Riwayat Pesanan'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Selesai'), findsWidgets);
    expect(find.text('Dibatalkan'), findsWidgets);
    expect(find.byType(PesananCard), findsWidgets);
  });
}
