import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/teknisi/teknisi_shell.dart';
import 'package:acare_mobile/services/perangkat.dart';
import 'package:acare_mobile/services/teknisi_service.dart';
import 'package:acare_mobile/widgets/peta_lokasi.dart';

void main() {
  final layanan = TeknisiService.instance;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    PetaLokasi.aktif = false;
  });

  setUp(() {
    layanan.reset();
    layanan.jedaTawaran = const Duration(seconds: 1);
    layanan.jedaPersetujuan = const Duration(seconds: 1);
    Perangkat.ambilFoto = () async =>
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'foto.jpg');
  });
  tearDown(layanan.reset);

  Future<void> buka(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TeknisiShell()));
    await tester.pump();
  }

  Future<void> online(WidgetTester tester) async {
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('Offline: tidak ada tawaran; online: tawaran masuk', (
    tester,
  ) async {
    await buka(tester);
    expect(find.textContaining('Kamu sedang offline'), findsOneWidget);

    await online(tester);
    expect(find.text('Pesanan Masuk!'), findsOneWidget);
    expect(find.text('Service AC'), findsOneWidget);
    expect(find.text('30s'), findsOneWidget);
  });

  testWidgets('Tolak tawaran bisa dibatalkan, sisa waktu tetap berjalan', (
    tester,
  ) async {
    await buka(tester);
    await online(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('20s'), findsOneWidget);

    await tester.tap(find.text('Tolak'));
    await tester.pump();
    // Tunggu animasi snackbar muncul.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pesanan Masuk!'), findsNothing);
    expect(find.text('Tawaran ditolak'), findsOneWidget);

    await tester.tap(find.text('Batalkan'));
    await tester.pump();
    expect(find.text('Pesanan Masuk!'), findsOneWidget);
    expect(find.text('20s'), findsOneWidget);

    // Selesaikan sisa waktu & snackbar agar tidak ada timer tertinggal.
    await tester.pump(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Tawaran lewat batas waktu diteruskan ke teknisi lain', (
    tester,
  ) async {
    await buka(tester);
    await online(tester);
    expect(find.text('Pesanan Masuk!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(find.text('Pesanan Masuk!'), findsNothing);
    expect(find.textContaining('tawaran diteruskan'), findsOneWidget);

    // Tawaran berikutnya datang lagi.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Pesanan Masuk!'), findsOneWidget);
  });

  testWidgets('Alur kerja lengkap: terima, cek, ajukan biaya, perbaiki, '
      'upload bukti, komisi masuk', (tester) async {
    await buka(tester);
    await online(tester);
    final pendapatanAwal = layanan.pendapatanHariIni;

    await tester.tap(find.text('Terima Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengerjaan Servis'), findsOneWidget);
    expect(find.text('#AC-000124'), findsOneWidget);

    // Tidak bisa offline selama ada pesanan berjalan.
    expect(layanan.aturOnline(false), isFalse);

    await tester.tap(find.text('Saya Sudah Tiba'));
    await tester.pump();
    await tester.tap(find.text('Mulai Pengecekan'));
    await tester.pump();
    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Input Biaya Perbaikan'));
    await tester.pumpAndSettle();
    expect(find.text('Input Biaya Perbaikan'), findsOneWidget);

    // Kirim kosong -> validasi.
    await tester.tap(find.text('Kirim Rincian Biaya'));
    await tester.pump();
    expect(find.text('Wajib diisi'), findsWidgets);

    final nama = find.byType(TextFormField);
    await tester.enterText(nama.at(0), 'Las pipa');
    await tester.enterText(nama.at(1), '120000');
    await tester.enterText(nama.at(2), 'Freon R32');
    await tester.enterText(nama.at(3), '150000');
    await tester.pump();
    // Total = 100.000 (awal) + 270.000; komisi 90% = 333.000.
    expect(find.textContaining('370.000'), findsOneWidget);
    expect(find.textContaining('333.000'), findsOneWidget);

    await tester.tap(find.text('Kirim Rincian Biaya'));
    // Jangan pumpAndSettle: persetujuan tiruan datang setelah 1 detik.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Menunggu persetujuan pelanggan'), findsOneWidget);

    // Pelanggan (tiruan) menyetujui -> tahap perbaikan.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Disetujui pelanggan'), findsOneWidget);
    await tester.tap(find.text('Selesai & Upload Bukti Kerja'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Konfirmasi & Selesaikan Order'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('wajib diunggah'), findsOneWidget);

    await tester.tap(find.text('Sebelum'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesudah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pipa dilas, freon diisi.');
    await tester.tap(find.text('Konfirmasi & Selesaikan Order'));
    await tester.pumpAndSettle();

    expect(find.textContaining('masuk ke dompet'), findsOneWidget);
    expect(layanan.pekerjaan.value, isNull);
    expect(layanan.pendapatanHariIni, pendapatanAwal + 333000);
    // Biarkan jadwal tawaran berikutnya berjalan sebelum test selesai.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Dompet: minimal Rp50.000, pengajuan menunggu Admin', (
    tester,
  ) async {
    await buka(tester);
    await tester.tap(find.text('Dompet').last);
    await tester.pumpAndSettle();

    // Saldo awal tiruan: 180.000 + 67.500.
    expect(find.textContaining('247.500'), findsOneWidget);
    FilledButton tombol() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ajukan Pencairan'),
    );
    expect(tombol().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '30000');
    await tester.pump();
    expect(tombol().onPressed, isNull);

    await tester.tap(find.text('Rp 100.000'));
    await tester.pump();
    expect(tombol().onPressed, isNotNull);

    await tester.tap(find.text('Ajukan Pencairan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajukan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengajuan terkirim'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(layanan.saldo, 147500);
    expect(find.text('Riwayat Pencairan'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
  });
}
