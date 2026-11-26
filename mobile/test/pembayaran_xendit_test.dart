import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/models/metode_bayar.dart';
import 'package:acare_mobile/pages/pelanggan/menunggu_pembayaran_page.dart';
import 'package:acare_mobile/services/order_service.dart';
import 'package:acare_mobile/services/perangkat.dart';

import 'support/server_palsu.dart';

/// Halaman bayar terhadap tiruan Xendit di server palsu.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });
  tearDown(Perangkat.reset);

  ServerPalsu server() => ServerPalsu.aktif;

  /// Buka halaman bayar pelunasan lewat tombol, supaya hasil pop terbaca.
  Future<List<PesananPelanggan?>> buka(
    WidgetTester tester,
    MetodeBayar metode,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final p = await server().buatPesananUji(
      status: 'menunggu_pembayaran',
      biaya: {'Filter': 20000},
    );
    final hasil = <PesananPelanggan?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  hasil.add(
                    await Navigator.of(context).push<PesananPelanggan>(
                      MaterialPageRoute(
                        builder: (_) => MenungguPembayaranPage(
                          idPesanan: p.id!,
                          idPembayaran: p.idPembayaranPelunasan!,
                          metode: metode,
                          nominal: p.jumlahPelunasan,
                          keterangan: 'Pelunasan biaya perbaikan',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    // Jangan pumpAndSettle: spinner + pemeriksaan berkala memajukan waktu.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return hasil;
  }

  testWidgets('Gagal membuat tagihan: pesan + coba lagi', (tester) async {
    server().gagalBuatTagihan = true;
    await buka(tester, MetodeBayar.qris);
    expect(find.textContaining('Tagihan belum bisa dibuat'), findsOneWidget);

    server().gagalBuatTagihan = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('kode-qris')), findsOneWidget);
    expect(find.textContaining('Bayar sebelum 29:'), findsOneWidget);

    // Tutup halaman supaya pemeriksaan berkala berhenti.
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('E-wallet: tombol membuka tautan dari Xendit', (tester) async {
    Uri? dibuka;
    Perangkat.bukaUrl = (uri) async {
      dibuka = uri;
      return true;
    };
    server().bayarLunasSetelahPeriksa = 99;
    await buka(tester, MetodeBayar.eWallet);
    expect(find.text('ShopeePay'), findsOneWidget);

    await tester.tap(find.text('ShopeePay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Buka SHOPEEPAY'));
    await tester.pump();
    expect(dibuka, Uri.parse('https://ewallet.contoh/bayar'));

    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('Tombol simulasi (mode uji) melunasi dan menutup halaman', (
    tester,
  ) async {
    server().bayarLunasSetelahPeriksa = 99;
    final hasil = await buka(tester, MetodeBayar.qris);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Simulasikan Pembayaran (mode uji)'));
    await tester.tap(find.text('Simulasikan Pembayaran (mode uji)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pembayaran Berhasil'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Buka'), findsOneWidget);
    expect(hasil.single?.status, StatusPesananPelanggan.selesai);
  });
}
