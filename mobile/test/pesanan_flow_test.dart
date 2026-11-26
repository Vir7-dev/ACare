import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/models/teknisi.dart';
import 'package:acare_mobile/pages/pelanggan/chat_teknisi_page.dart';
import 'package:acare_mobile/pages/pelanggan/detail_pesanan_page.dart';
import 'package:acare_mobile/pages/pelanggan/pembayaran_page.dart';
import 'package:acare_mobile/pages/pelanggan/tracking_teknisi_page.dart';

import 'support/server_palsu.dart';

/// Detail pesanan, pelunasan, dan tracking: status dari server palsu,
/// langkah teknisi ditiru lewat ServerPalsu.majukan/ajukanBiaya.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> buka(WidgetTester tester, Widget halaman) async {
    ukuranHp(tester);
    await tester.pumpWidget(MaterialApp(home: halaman));
    await tester.pump();
  }

  /// Tunggu satu putaran pemeriksaan status (3 detik).
  Future<void> periksa(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  ServerPalsu server() => ServerPalsu.aktif;

  testWidgets('Detail pesanan: pengecekan awal tanpa tombol batal', (
    tester,
  ) async {
    final p = await server().buatPesananUji();
    await buka(tester, DetailPesananPage(pesanan: p));

    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Pengecekan Awal'), findsWidgets);
    // Garis waktu memuat 4 langkah, termasuk Menunggu Pembayaran.
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.text('Menunggu hasil pengecekan'), findsOneWidget);
    // Jam tahap dari server.
    expect(find.text('14.30'), findsOneWidget);
    expect(find.text('Andi Saputra'), findsOneWidget);
    // Teknisi sudah ditemukan: pesanan tidak bisa dibatalkan.
    expect(find.text('Batalkan Pesanan'), findsNothing);
  });

  testWidgets('Teknisi mengajukan biaya -> pelanggan setuju -> pelunasan', (
    tester,
  ) async {
    final p = await server().buatPesananUji();
    await buka(tester, DetailPesananPage(pesanan: p));
    expect(find.text('Sedang berjalan'), findsOneWidget);

    // Teknisi (di server) mengajukan biaya; halaman memeriksa status.
    server().ajukanBiaya(p.id!, {'Kapasitor': 85000, 'Jasa ganti': 50000});
    await periksa(tester);
    expect(find.text('Menunggu Persetujuan Biaya'), findsOneWidget);
    expect(find.text('Rincian Biaya Perbaikan'), findsOneWidget);
    expect(find.text('Kapasitor'), findsOneWidget);

    await tester.ensureVisible(find.text('Setuju'));
    await tester.pump();
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian Biaya Perbaikan'), findsNothing);
    expect(find.text('Melakukan Perbaikan'), findsWidgets);
    expect(
      (server().pesanan.last['biaya'] as Map)['status_biaya'],
      'disetujui',
    );

    // Teknisi selesai -> pelunasan sisa biaya perbaikan.
    server().selesaiDikerjakan(p.id!);
    await periksa(tester);
    expect(find.text('Sisa tagihan'), findsOneWidget);
    expect(find.text('Bayar Pesanan'), findsOneWidget);
  });

  testWidgets('Detail pesanan: tolak biaya perbaikan -> lanjut biaya awal', (
    tester,
  ) async {
    final p = await server().buatPesananUji(biaya: {'Kompresor': 900000});
    await buka(tester, DetailPesananPage(pesanan: p));

    await tester.ensureVisible(find.text('Tolak'));
    await tester.pump();
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Tolak'));
    await tester.pumpAndSettle();

    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Total dibayar'), findsOneWidget);
    expect(find.text('Bayar Pesanan'), findsNothing);
    // Langkah perbaikan & pembayaran tidak ditampilkan lagi.
    expect(find.text('Melakukan Perbaikan'), findsNothing);
    expect((server().pesanan.last['biaya'] as Map)['status_biaya'], 'ditolak');
  });

  testWidgets('Persetujuan lewat 5 menit: pesan dari server', (tester) async {
    final p = await server().buatPesananUji(biaya: {'Kompresor': 900000});
    await buka(tester, DetailPesananPage(pesanan: p));
    // Di server batas waktu sudah lewat (teknisi lanjut tanpa biaya).
    server().majukan(p.id!, 'dikerjakan');

    await tester.ensureVisible(find.text('Setuju'));
    await tester.pump();
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Waktu persetujuan sudah habis'),
      findsOneWidget,
    );
  });

  testWidgets('Tanpa biaya perbaikan: selesai dengan biaya awal', (
    tester,
  ) async {
    final p = await server().buatPesananUji(layanan: 'Cuci AC');
    await buka(tester, DetailPesananPage(pesanan: p));

    server().majukan(p.id!, 'dikerjakan');
    await periksa(tester);
    expect(find.text('Rincian Biaya Perbaikan'), findsNothing);
    expect(find.text('Melakukan Perbaikan'), findsWidgets);

    server().selesaiDikerjakan(p.id!);
    await periksa(tester);
    expect(find.text('Total dibayar'), findsOneWidget);
    expect(find.text('Bayar Pesanan'), findsNothing);
  });

  testWidgets('Menunggu pembayaran -> pelunasan non-tunai -> selesai', (
    tester,
  ) async {
    final p = await server().buatPesananUji(
      status: 'menunggu_pembayaran',
      biaya: {'Filter': 20000, 'Blower': 30000},
    );
    await buka(tester, DetailPesananPage(pesanan: p));

    await tester.ensureVisible(find.text('Bayar Pesanan'));
    await tester.pump();
    await tester.tap(find.text('Bayar Pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Pesanan'), findsOneWidget);
    expect(find.text('Rincian Pembayaran'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Blower'), findsOneWidget);
    expect(find.text('Biaya awal (sudah dibayar)'), findsOneWidget);
    expect(find.text('Cash'), findsNothing);

    await tester.tap(find.text('Virtual Account'));
    await tester.pump();
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('BNI'), findsOneWidget);
    expect(find.text('Mandiri'), findsOneWidget);
    await tester.tap(find.text('BRI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Nomor BRI_VIRTUAL_ACCOUNT'), findsOneWidget);
    expect(find.text('8808123456789012'), findsOneWidget);
    expect(
      server().log,
      contains(
        'POST /pesanan/${p.id}/pembayaran/${p.idPembayaranPelunasan}/bayar',
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Kembali ke detail: pelunasan tercatat di server, pesanan selesai.
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Total dibayar'), findsOneWidget);
    expect(server().pesanan.last['status'], 'selesai');
  });

  testWidgets('Pelunasan langsung dari halaman pembayaran', (tester) async {
    final p = await server().buatPesananUji(
      status: 'menunggu_pembayaran',
      biaya: {'Filter': 20000},
    );
    bool? hasil;
    await buka(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                hasil = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => PembayaranPage(pesanan: p)),
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
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DANA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Buka'), findsOneWidget);
    expect(hasil, isTrue);
  });

  testWidgets('Tracking teknisi tampil dan bisa buka chat', (tester) async {
    final p = await server().buatPesananUji(status: 'menuju_lokasi');
    await buka(tester, TrackingTeknisiPage(pesanan: p));

    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);
    expect(find.text('Andi Saputra'), findsOneWidget);
    expect(find.textContaining('Honda Beat'), findsOneWidget);

    await tester.tap(find.text('Pesan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Selamat siang, Bapak/Ibu'), findsOneWidget);
  });

  testWidgets('Tracking pindah ke detail saat teknisi mulai pengecekan', (
    tester,
  ) async {
    final p = await server().buatPesananUji(status: 'menuju_lokasi');
    await buka(tester, TrackingTeknisiPage(pesanan: p));

    // Teknisi tiba: masih di peta.
    server().majukan(p.id!, 'tiba');
    await periksa(tester);
    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);

    server().majukan(p.id!, 'pengecekan_awal');
    await periksa(tester);
    expect(find.text('Teknisi Menuju Lokasi'), findsNothing);
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Batalkan Pesanan'), findsNothing);
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
