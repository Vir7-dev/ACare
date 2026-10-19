import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acare_mobile/models/status_layanan.dart';
import 'package:acare_mobile/pages/pelanggan/chat_teknisi_page.dart';
import 'package:acare_mobile/pages/pelanggan/detail_pesanan_page.dart';
import 'package:acare_mobile/pages/pelanggan/pembayaran_page.dart';
import 'package:acare_mobile/pages/pelanggan/tracking_teknisi_page.dart';
import 'package:acare_mobile/models/teknisi.dart';

void main() {
  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> buka(WidgetTester tester, Widget halaman) async {
    ukuranHp(tester);
    await tester.pumpWidget(MaterialApp(home: halaman));
  }

  testWidgets('Detail pesanan: pengecekan awal hanya bisa dibatalkan',
      (tester) async {
    await buka(
      tester,
      const DetailPesananPage(status: StatusLayanan.pengecekanAwal),
    );

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Rp 100.000'), findsOneWidget);

    final bayar = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Bayar Pesanan'),
    );
    final batal = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Batalkan Pesanan'),
    );
    expect(bayar.onPressed, isNull);
    expect(batal.onPressed, isNotNull);
  });

  testWidgets('Detail pesanan: menunggu pembayaran -> halaman pembayaran',
      (tester) async {
    await buka(
      tester,
      const DetailPesananPage(status: StatusLayanan.menungguPembayaran),
    );

    final batal = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Batalkan Pesanan'),
    );
    expect(batal.onPressed, isNull);

    await tester.ensureVisible(find.text('Bayar Pesanan'));
    await tester.tap(find.text('Bayar Pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Pesanan'), findsOneWidget);
    expect(find.text('TOTAL PEMBAYARAN'), findsOneWidget);
  });

  testWidgets('Pembayaran menampilkan rincian dan metode', (tester) async {
    await buka(tester, const PembayaranPage());

    expect(find.text('Rincian Pembayaran'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Blower'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await tester.pump();
    await tester.tap(find.text('BAYAR'));
    await tester.pumpAndSettle();
  });

  testWidgets('Tracking teknisi tampil dan bisa buka chat', (tester) async {
    await buka(tester, const TrackingTeknisiPage(teknisi: teknisiDummy));

    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);
    expect(find.text('20 Menit lagi'), findsOneWidget);

    await tester.tap(find.text('Pesan'));
    await tester.pumpAndSettle();
    expect(find.text('Halo Mas'), findsOneWidget);
  });

  testWidgets('Chat bisa mengirim pesan', (tester) async {
    await buka(tester, const ChatTeknisiPage(teknisi: teknisiDummy));

    await tester.enterText(find.byType(TextField), 'Sudah di depan ya');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Sudah di depan ya'), findsOneWidget);
  });
}
