import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/pelanggan/riwayat_pesanan_page.dart';
import 'package:acare_mobile/services/refund_service.dart';

import 'support/server_palsu.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));
  setUp(RefundService.instance.reset);
  tearDown(RefundService.instance.reset);

  /// Riwayat Dina dari server: satu batal dengan dana tertahan, satu batal
  /// yang refund-nya sudah ditransfer, satu batal yang belum dibayar.
  Future<void> bukaDibatalkan(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = ServerPalsu.aktif;
    s.tambahRiwayat(
      layanan: 'Isi Freon',
      status: 'dibatalkan',
      statusBayar: 'tertahan',
      total: 150000,
      alasan: 'Dibatalkan oleh pelanggan saat mencari teknisi',
    ); // #AC-000100
    s.tambahRiwayat(
      layanan: 'Service AC',
      status: 'dibatalkan',
      statusBayar: 'tertahan',
      alasan: 'Tidak ada teknisi yang menerima dalam batas waktu',
    ); // #AC-000101
    s.tambahRiwayat(
      layanan: 'Cuci AC',
      status: 'dibatalkan',
      statusBayar: 'kedaluwarsa',
      alasan: 'Pembayaran tidak diselesaikan',
    ); // #AC-000102
    RefundService.instance.pengajuan.value = {
      '#AC-000101': PengajuanRefund(
        kodePesanan: '#AC-000101',
        nominal: 100000,
        tujuan: TujuanRefund.eWallet,
        namaBank: 'DANA',
        nomor: '081234567890',
        atasNama: 'Pelanggan Contoh',
        diajukanPada: DateTime(2026, 10, 1, 18),
        status: StatusRefund.selesai,
      ),
    };
    await ServerPalsu.masukPelanggan();
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

    expect(find.textContaining('Dana tertahan'), findsOneWidget);
    expect(find.text('Refund: Dana sudah ditransfer'), findsOneWidget);
    // Batal sebelum dibayar: tidak ada dana untuk dikembalikan.
    expect(find.text('Belum ada pembayaran'), findsOneWidget);
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
    expect(RefundService.instance.untuk('#AC-000100')?.namaBank, 'DANA');
  });

  testWidgets('Detail pembatalan menampilkan tujuan dan status refund', (
    tester,
  ) async {
    await bukaDibatalkan(tester);

    await tester.tap(find.text('Detail Pembatalan').at(1));
    await tester.pumpAndSettle();
    expect(find.textContaining('DANA •••• 7890'), findsOneWidget);
    expect(find.textContaining('Dana sudah ditransfer'), findsWidgets);
  });
}
