import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/pelanggan/riwayat_pesanan_page.dart';
import 'package:acare_mobile/services/refund_service.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));
  setUp(RefundService.instance.reset);
  tearDown(RefundService.instance.reset);

  Future<void> bukaDibatalkan(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RiwayatPesananPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dibatalkan').first);
    await tester.pumpAndSettle();
  }

  testWidgets('Pesanan batal: dana tertahan -> ajukan refund -> menunggu', (
    tester,
  ) async {
    await bukaDibatalkan(tester);

    // Satu pesanan masih tertahan, satu lagi refund-nya sudah ditransfer.
    expect(find.textContaining('Dana tertahan'), findsOneWidget);
    expect(find.text('Refund: Dana sudah ditransfer'), findsOneWidget);
    expect(find.text('Ajukan Refund'), findsOneWidget);

    await tester.tap(find.text('Ajukan Refund'));
    await tester.pumpAndSettle();
    expect(find.text('Dana yang dikembalikan'), findsOneWidget);

    await tester.tap(find.text('Kirim Pengajuan'));
    await tester.pump();
    expect(find.text('Kolom ini wajib diisi.'), findsNWidgets(3));

    await tester.tap(find.text('E-Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nama e-wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DANA').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nomor e-wallet'),
      '081234567890',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama pemilik'),
      'Pelanggan Contoh',
    );
    await tester.tap(find.text('Kirim Pengajuan'));
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan refund berhasil dikirim'), findsOneWidget);
    expect(find.text('Refund: Menunggu diproses Admin'), findsOneWidget);
    expect(find.text('Ajukan Refund'), findsNothing);
    expect(RefundService.instance.untuk('#AC-7188')?.namaBank, 'DANA');
  });

  testWidgets('Detail pembatalan menampilkan tujuan dan status refund', (
    tester,
  ) async {
    await bukaDibatalkan(tester);

    await tester.tap(find.text('Detail Pembatalan').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('DANA •••• 7890'), findsOneWidget);
    expect(find.textContaining('Dana sudah ditransfer'), findsWidgets);
  });
}
