import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acare_mobile/models/status_layanan.dart';
import 'package:acare_mobile/pages/pelanggan/detail_pesanan_page.dart';
import 'package:acare_mobile/pages/umum/main_shell.dart';
import 'package:acare_mobile/pages/pelanggan/masuk_page.dart';
import 'package:acare_mobile/pages/pelanggan/pengaduan_page.dart';
import 'package:acare_mobile/pages/umum/splash_page.dart';
import 'package:acare_mobile/services/perangkat.dart';

// PNG 1x1 piksel
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('Tombol Telepon membuka tel: ke nomor teknisi', (tester) async {
    ukuranHp(tester);
    Uri? dibuka;
    Perangkat.bukaUrl = (uri) async {
      dibuka = uri;
      return true;
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: DetailPesananPage(status: StatusLayanan.pengecekanAwal),
      ),
    );
    await tester.tap(find.text('Telepon'));
    await tester.pump();

    expect(dibuka?.scheme, 'tel');
    expect(dibuka?.path, '081234567890');
  });

  testWidgets('Telepon gagal -> pemberitahuan', (tester) async {
    ukuranHp(tester);
    Perangkat.bukaUrl = (_) async => false;

    await tester.pumpWidget(
      const MaterialApp(
        home: DetailPesananPage(status: StatusLayanan.pengecekanAwal),
      ),
    );
    await tester.tap(find.text('Telepon'));
    await tester.pump();

    expect(
      find.textContaining('Tidak bisa membuka aplikasi telepon'),
      findsOneWidget,
    );
  });

  testWidgets('Beranda: gunakan lokasi saat ini lalu diingat', (tester) async {
    ukuranHp(tester);
    Perangkat.lokasiSaatIni = () async => 'Batu Aji, Batam';

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.tap(find.text('Pilih Lokasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan lokasi saya saat ini'));
    await tester.pumpAndSettle();

    expect(find.text('Batu Aji, Batam'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lokasi'), 'Batu Aji, Batam');
  });

  testWidgets('Beranda: izin lokasi ditolak -> pesan kesalahan', (
    tester,
  ) async {
    ukuranHp(tester);
    Perangkat.lokasiSaatIni = () async =>
        throw const LokasiException('Izin lokasi ditolak');

    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.tap(find.text('Pilih Lokasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan lokasi saya saat ini'));
    await tester.pumpAndSettle();

    expect(find.text('Izin lokasi ditolak'), findsOneWidget);
    expect(find.text('Pilih Lokasi'), findsOneWidget);
  });

  testWidgets('Pengaduan: foto bukti dipilih dari galeri', (tester) async {
    ukuranHp(tester);
    Perangkat.ambilFoto = () async =>
        XFile.fromData(_png, name: 'struk.png', mimeType: 'image/png');

    await tester.pumpWidget(const MaterialApp(home: PengaduanPage()));
    await tester.scrollUntilVisible(
      find.text('Pilih Foto'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pilih Foto'));
    await tester.pumpAndSettle();

    expect(find.textContaining('foto_bukti'), findsOneWidget);
    expect(find.text('Pilih Foto'), findsNWidgets(1));
  });

  testWidgets('Masuk mengingat nama; splash langsung ke beranda', (
    tester,
  ) async {
    ukuranHp(tester);

    await tester.pumpWidget(const MaterialApp(home: MasukPage()));
    await tester.enterText(find.byType(TextFormField).at(0), 'Dina');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang, Dina!'), findsOneWidget);

    // Buka ulang aplikasi: sesi masih tersimpan
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang, Dina!'), findsOneWidget);
  });

  testWidgets('Daftar menyimpan data; Masuk dan Profil terisi otomatis', (
    tester,
  ) async {
    ukuranHp(tester);

    await tester.pumpWidget(const MaterialApp(home: MasukPage()));
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    // email dengan format salah ditolak
    final f = find.byType(TextFormField);
    await tester.enterText(f.at(0), 'Dina Safitri');
    await tester.enterText(f.at(1), '083862865166');
    await tester.enterText(f.at(2), 'bukan-email');
    await tester.enterText(f.at(3), 'rahasia123');
    await tester.enterText(f.at(4), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pump();
    expect(find.text('Format email tidak valid'), findsOneWidget);

    await tester.enterText(f.at(2), 'sdina3066@gmail.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pumpAndSettle();

    // kembali ke Masuk, nama sudah terisi dari pendaftaran
    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(find.text('Dina Safitri'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    expect(find.text('Dina Safitri'), findsWidgets);
    expect(find.text('083862865166'), findsOneWidget);
    expect(find.text('sdina3066@gmail.com'), findsOneWidget);
  });
}
