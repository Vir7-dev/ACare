import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';

import 'package:acare_mobile/pages/teknisi/teknisi_shell.dart';
import 'package:acare_mobile/services/perangkat.dart';
import 'package:acare_mobile/services/teknisi_service.dart';
import 'package:acare_mobile/widgets/peta_lokasi.dart';

import 'support/server_palsu.dart';

/// Aplikasi teknisi terhadap server palsu: tawaran, langkah kerja, biaya,
/// bukti, dan dompet.
void main() {
  final layanan = TeknisiService.instance;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    PetaLokasi.aktif = false;
  });

  setUp(() {
    layanan.reset();
    Perangkat.ambilFoto = () async =>
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'foto.jpg');
    Perangkat.koordinatSaatIni = () async => const LatLng(1.135, 104.045);
  });
  tearDown(layanan.reset);

  ServerPalsu server() => ServerPalsu.aktif;

  Future<void> buka(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ServerPalsu.masukTeknisi();
    await tester.pumpWidget(const MaterialApp(home: TeknisiShell()));
    await tester.pump();
  }

  /// Nyalakan online lalu tunggu pemeriksaan tawaran pertama.
  Future<void> online(WidgetTester tester) async {
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
  }

  /// Satu putaran pemeriksaan ke server (3 detik).
  Future<void> periksa(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  }

  testWidgets('Offline: tidak ada tawaran; online: tawaran dari server', (
    tester,
  ) async {
    server().tawarkan();
    await buka(tester);
    expect(find.textContaining('Kamu sedang offline'), findsOneWidget);

    await online(tester);
    expect(server().teknisiOnline, isTrue);
    expect(find.text('Pesanan Masuk!'), findsOneWidget);
    expect(find.text('Service AC'), findsOneWidget);
    expect(find.text('30s'), findsOneWidget);
    expect(find.textContaining('Keluhan: Tidak dingin'), findsOneWidget);

    // Matikan online supaya pemeriksaan berkala berhenti.
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(server().teknisiOnline, isFalse);
  });

  testWidgets('Tolak tawaran: diteruskan ke teknisi lain di server', (
    tester,
  ) async {
    final p = server().tawarkan();
    await buka(tester);
    await online(tester);

    await tester.tap(find.text('Tolak'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pesanan Masuk!'), findsNothing);
    expect(find.textContaining('diteruskan ke teknisi lain'), findsOneWidget);
    expect(p['ditawari'], isNull);

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Online butuh lokasi: pesan bila lokasi gagal', (tester) async {
    Perangkat.koordinatSaatIni = () async =>
        throw const LokasiException('Izin lokasi ditolak');
    await buka(tester);

    await online(tester);
    expect(find.text('Izin lokasi ditolak'), findsOneWidget);
    expect(layanan.online.value, isFalse);
    expect(server().teknisiOnline, isFalse);
  });

  testWidgets('Alur kerja lengkap: terima, cek, ajukan biaya, disetujui, '
      'upload bukti, komisi masuk', (tester) async {
    final p = server().tawarkan();
    final id = p['id'] as int;
    await buka(tester);
    await online(tester);
    final pendapatanAwal = layanan.pendapatanHariIni;

    await tester.tap(find.text('Terima Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengerjaan Servis'), findsOneWidget);
    expect(find.text('#${p['kode']}'), findsOneWidget);
    expect(p['status'], 'menuju_lokasi');

    // Tidak bisa offline selama ada pesanan berjalan.
    expect(await layanan.aturOnline(false), isNotNull);

    await tester.tap(find.text('Saya Sudah Tiba'));
    await tester.pumpAndSettle();
    expect(p['status'], 'tiba');
    await tester.tap(find.text('Mulai Pengecekan'));
    await tester.pumpAndSettle();
    expect(p['status'], 'pengecekan_awal');
    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    expect((p['foto'] as List).length, 1);

    await tester.tap(find.text('Input Biaya Perbaikan'));
    await tester.pumpAndSettle();

    // Kirim kosong -> validasi.
    await tester.tap(find.text('Kirim Rincian Biaya'));
    await tester.pump();
    expect(find.text('Wajib diisi'), findsWidgets);

    final isian = find.byType(TextFormField);
    await tester.enterText(isian.at(0), 'Las pipa');
    await tester.enterText(isian.at(1), '120000');
    await tester.enterText(isian.at(2), 'Freon R32');
    await tester.enterText(isian.at(3), '150000');
    await tester.pump();
    // Total = 100.000 (awal) + 270.000; komisi 90% = 333.000.
    expect(find.textContaining('370.000'), findsOneWidget);
    expect(find.textContaining('333.000'), findsOneWidget);

    server().setujuiSetelahPeriksa = 2;
    await tester.tap(find.text('Kirim Rincian Biaya'));
    // Jangan pumpAndSettle: snackbar 4 detik akan ikut menjalankan
    // pemeriksaan berkala (dan persetujuan tiruan).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Menunggu persetujuan pelanggan'), findsOneWidget);
    expect(p['status'], 'menunggu_persetujuan_biaya');

    // Pelanggan (tiruan di server) menyetujui; teknisi melihatnya lewat
    // pemeriksaan berkala.
    await periksa(tester);
    await periksa(tester);
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
    // Biaya disetujui: pelanggan diminta melunasi sisa tagihan.
    expect(
      server().pesanan.firstWhere((x) => x['id'] == id)['status'],
      'menunggu_pembayaran',
    );

    // Hentikan pemeriksaan berkala & tunggu snackbar hilang.
    layanan.reset();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Pekerjaan berjalan dipulihkan saat aplikasi dibuka', (
    tester,
  ) async {
    final p = server().tawarkan();
    p['id_teknisi'] = 2;
    server().majukan(p['id'] as int, 'tiba');
    await buka(tester);
    await tester.pumpAndSettle();

    expect(layanan.pekerjaan.value?.tahap, TahapPekerjaan.tiba);
    expect(layanan.online.value, isTrue);
    layanan.reset();
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
