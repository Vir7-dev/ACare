import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acare_mobile/models/layanan.dart';
import 'package:acare_mobile/pages/umum/main_shell.dart';
import 'package:acare_mobile/pages/pelanggan/mencari_teknisi_page.dart';
import 'package:acare_mobile/services/auth_service.dart';
import 'package:acare_mobile/services/order_service.dart';

import 'support/server_palsu.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> bukaShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
  }

  testWidgets('Riwayat -> Beri Ulasan -> kirim', (tester) async {
    ServerPalsu.aktif.tambahRiwayat(layanan: 'Service AC', status: 'selesai');
    await ServerPalsu.masukPelanggan();
    await bukaShell(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beri Ulasan').first);
    await tester.pumpAndSettle();
    expect(find.text('Beri Ulasan Servis'), findsOneWidget);
    expect(find.text('Luar Biasa Memuaskan!'), findsOneWidget);

    // star pertama = chip rating teknisi, 5 berikutnya = bintang nilai
    await tester.tap(find.byIcon(Icons.star).at(3));
    await tester.pump();
    expect(find.text('Cukup Baik'), findsOneWidget);

    await tester.tap(find.text('Tepat Waktu'));
    await tester.pump();

    await tester.tap(find.text('Kirim Ulasan'));
    await tester.pumpAndSettle();
    expect(find.text('Beri Ulasan Servis'), findsNothing);
  });

  testWidgets('Pengaduan: validasi lalu kirim', (tester) async {
    await bukaShell(tester);
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Bantuan & Pengaduan'), findsOneWidget);

    await tester.tap(find.text('Kirim Laporan Pengaduan'));
    await tester.pump();
    expect(
      find.text('Pilih jenis masalah dan isi kronologi kendala'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hasil Servis Kurang Dingin'));
    await tester.enterText(find.byType(TextField), 'Teknisi datang terlambat.');
    await tester.pump();
    await tester.tap(find.text('Kirim Laporan Pengaduan'));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Bantuan & Pengaduan'), findsNothing);
  });

  testWidgets('Profil: tampil, simpan, dan keluar ke pilih peran', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // Masuk lewat server palsu, sama seperti dari halaman Masuk.
    final hasil = await AuthService.login(
      'dina@gmail.com',
      ServerPalsu.sandiContoh,
      UserRole.pelanggan,
    );
    expect(hasil.berhasil, isTrue);
    await bukaShell(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    expect(find.text('Kelola Profil'), findsOneWidget);
    expect(find.text('DS'), findsOneWidget);

    // Data terkunci sampai menekan Edit Profil.
    await tester.tap(find.text('Edit Profil'));
    await tester.pump();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Perubahan disimpan'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Keluar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Gulir sampai menu Keluar utuh terlihat, tidak terpotong tepi layar.
    await tester.ensureVisible(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keluar'));
    await tester.pumpAndSettle();
    // Token dihapus di server dan di perangkat.
    expect(ServerPalsu.aktif.token, isEmpty);
    expect(AuthService.akun.value, isNull);
    expect(find.text('Masuk sebagai'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.text('Selamat Datang!'), findsNothing);
  });

  testWidgets('Mencari teknisi otomatis pindah ke tracking', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await ServerPalsu.masukPelanggan();
    final dibuat = await OrderService.instance.buat(
      PesananPelanggan(
        idLokasi: 1,
        layanan: daftarLayanan.first,
        jumlahUnit: 1,
        jenisAc: JenisAc.split,
        pk: 1,
        alamat: 'Perumahan Batu Aji Blok C No. 12, Batam',
        detailAlamat: '',
        jadwal: DateTime.now(),
        metodeBayar: 'QRIS',
        biayaAwal: 75000,
      ),
    );
    final dibayar = await OrderService.instance.simulasiLunas(dibuat);

    await tester.pumpWidget(
      MaterialApp(home: MencariTeknisiPage(pesanan: dibayar)),
    );
    expect(find.text('Mencari Teknisi Terdekat...'), findsOneWidget);

    // Pemeriksaan kedua (3 detik kemudian): teknisi palsu menerima.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);
  });
}
