import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acare_mobile/models/status_layanan.dart';
import 'package:acare_mobile/models/teknisi.dart';
import 'package:acare_mobile/pages/pelanggan/chat_teknisi_page.dart';
import 'package:acare_mobile/pages/pelanggan/detail_pesanan_page.dart';
import 'package:acare_mobile/pages/pelanggan/pembayaran_page.dart';
import 'package:acare_mobile/pages/pelanggan/tracking_teknisi_page.dart';
import 'package:acare_mobile/services/order_service.dart';

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

  testWidgets('Detail pesanan: mulai pengecekan awal, tombolnya sesuai', (
    tester,
  ) async {
    // Mode manual supaya status tidak berubah sendiri saat test.
    await buka(
      tester,
      const DetailPesananPage(
        status: StatusLayanan.pengecekanAwal,
        otomatis: false,
      ),
    );

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Pengecekan Awal'), findsWidgets);

    final batal = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Batalkan Pesanan'),
    );
    expect(batal.onPressed, isNotNull);
  });

  testWidgets('Detail pesanan: status berjalan otomatis tanpa tahap bayar', (
    tester,
  ) async {
    await buka(tester, const DetailPesananPage());

    // Tahap "Menunggu Pembayaran" disembunyikan dari timeline.
    expect(find.text('Pengecekan Awal'), findsWidgets);
    expect(find.text('Menunggu Pembayaran'), findsNothing);
    expect(find.text('Sedang berjalan'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Melakukan Perbaikan'), findsWidgets);
    expect(find.text('Menunggu Pembayaran'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Selesai'), findsWidgets);
    expect(find.text('Bayar Pesanan'), findsNothing);
  });

  testWidgets('Detail pesanan: menunggu pembayaran -> halaman pembayaran', (
    tester,
  ) async {
    await buka(
      tester,
      const DetailPesananPage(
        status: StatusLayanan.menungguPembayaran,
        otomatis: false,
      ),
    );

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
    await buka(
      tester,
      const TrackingTeknisiPage(
        teknisi: teknisiDummy,
        lamaTampil: Duration(minutes: 10),
      ),
    );

    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);
    expect(find.text('20 Menit lagi'), findsOneWidget);

    await tester.tap(find.text('Pesan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Selamat siang, Bapak/Ibu'), findsOneWidget);
  });

  testWidgets('Tracking teknisi pindah ke detail pesanan setelah 5 detik', (
    tester,
  ) async {
    addTearDown(OrderService.instance.reset);
    await buka(tester, const TrackingTeknisiPage(teknisi: teknisiDummy));

    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Teknisi Menuju Lokasi'), findsNothing);
    expect(find.text('Detail Pesanan'), findsOneWidget);
    // Tombol batal disembunyikan karena status dikerjakan otomatis.
    expect(find.text('Batalkan Pesanan'), findsNothing);

    // Habiskan sisa timer status supaya test tidak menyisakan timer.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
  });

  testWidgets('Chat bisa mengirim pesan dan dibalas teknisi', (tester) async {
    await buka(tester, const ChatTeknisiPage(teknisi: teknisiDummy));

    await tester.enterText(find.byType(TextField), 'Baik Pak, terima kasih.');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Baik Pak, terima kasih.'), findsOneWidget);
    expect(
      find.textContaining('Baik, terima kasih atas informasinya'),
      findsOneWidget,
    );
  });
}
