import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acare_mobile/models/status_layanan.dart';
import 'package:acare_mobile/models/tagihan.dart';
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

  testWidgets('Detail pesanan: pengecekan awal tanpa tombol batal', (
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
    // Garis waktu memuat 4 langkah, termasuk Menunggu Pembayaran.
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.text('Menunggu hasil pengecekan'), findsOneWidget);
    // Teknisi sudah ditemukan: pesanan tidak bisa dibatalkan.
    expect(find.text('Batalkan Pesanan'), findsNothing);
  });

  testWidgets('Detail pesanan: setujui biaya perbaikan lalu menunggu bayar', (
    tester,
  ) async {
    await buka(tester, const DetailPesananPage());
    expect(find.text('Sedang berjalan'), findsOneWidget);

    // Pengecekan selesai -> menunggu persetujuan, timer berhenti di sini.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Menunggu Persetujuan Biaya'), findsOneWidget);
    expect(find.text('Rincian Biaya Perbaikan'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Rincian Biaya Perbaikan'), findsOneWidget);

    await tester.ensureVisible(find.text('Setuju'));
    await tester.tap(find.text('Setuju'));
    await tester.pump();
    expect(find.text('Rincian Biaya Perbaikan'), findsNothing);
    expect(find.text('Melakukan Perbaikan'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Sisa tagihan'), findsOneWidget);
    expect(find.text('Bayar Pesanan'), findsOneWidget);
  });

  testWidgets('Detail pesanan: tolak biaya perbaikan -> selesai biaya awal', (
    tester,
  ) async {
    await buka(
      tester,
      const DetailPesananPage(
        status: StatusLayanan.menungguPersetujuanBiaya,
        otomatis: false,
      ),
    );

    await tester.ensureVisible(find.text('Tolak'));
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Tolak'));
    await tester.pumpAndSettle();

    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Total dibayar'), findsOneWidget);
    expect(find.text('Bayar Pesanan'), findsNothing);
    // Langkah perbaikan & pembayaran tidak ditampilkan lagi.
    expect(find.text('Melakukan Perbaikan'), findsNothing);
  });

  testWidgets('Detail pesanan tanpa biaya perbaikan langsung selesai', (
    tester,
  ) async {
    await buka(
      tester,
      const DetailPesananPage(
        tagihan: Tagihan(pemeriksaan: 75000, komponen: []),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Rincian Biaya Perbaikan'), findsNothing);
    expect(find.text('Melakukan Perbaikan'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Total dibayar'), findsOneWidget);
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

  testWidgets('Pelunasan: non-tunai, hanya menagih biaya perbaikan', (
    tester,
  ) async {
    bool? hasil;
    await buka(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                hasil = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PembayaranPage()),
                );
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    expect(find.text('Rincian Pembayaran'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Blower'), findsOneWidget);
    expect(find.text('Biaya awal (sudah dibayar)'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
    expect(find.text('Virtual Account'), findsOneWidget);
    expect(find.text('Cash'), findsNothing);

    await tester.tap(find.text('Virtual Account'));
    await tester.pump();
    await tester.tap(find.text('BAYAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pembayaran Virtual Account'), findsOneWidget);
    expect(find.text('Nomor Virtual Account'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Buka'), findsOneWidget);
    expect(hasil, isTrue);
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
