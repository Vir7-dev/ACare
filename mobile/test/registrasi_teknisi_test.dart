import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:acare_mobile/pages/pelanggan/masuk_page.dart';
import 'package:acare_mobile/pages/teknisi/registrasi_teknisi_page.dart';
import 'package:acare_mobile/services/auth_service.dart';
import 'package:acare_mobile/services/perangkat.dart';

void main() {
  void ukuranHp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> isi(WidgetTester tester, String hint, String teks) async {
    await tester.enterText(find.widgetWithText(TextFormField, hint), teks);
  }

  testWidgets('Masuk sebagai teknisi membuka registrasi teknisi', (
    tester,
  ) async {
    ukuranHp(tester);
    await tester.pumpWidget(
      const MaterialApp(home: MasukPage(role: UserRole.teknisi)),
    );
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrasiTeknisiPage), findsOneWidget);
  });

  testWidgets('Registrasi teknisi: 5 dokumen wajib, lalu menunggu '
      'verifikasi Admin dan belum bisa masuk', (tester) async {
    ukuranHp(tester);
    Perangkat.ambilFoto = () async => XFile.fromData(
      Uint8List.fromList(List.filled(100, 1)),
      name: 'dokumen.jpg',
      mimeType: 'image/jpeg',
    );

    await tester.pumpWidget(
      const MaterialApp(home: MasukPage(role: UserRole.teknisi)),
    );
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    // Tahap 1: data diri.
    await isi(tester, 'Masukkan nama lengkap', 'Budi Teknisi');
    await isi(tester, 'Masukkan nomor telepon', '081234567890');
    await isi(tester, 'Masukkan email', 'budi@acare.id');
    await isi(tester, 'Minimal 8 karakter', 'rahasia123');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    // Tahap 2: semua dokumen wajib diunggah.
    expect(find.text('Unggah Dokumen'), findsOneWidget);
    for (final d in ['CV', 'Lamaran Kerja', 'KTP', 'Ijazah', 'Pas Foto']) {
      expect(find.text(d), findsOneWidget);
    }
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.textContaining('Dokumen wajib diunggah'), findsOneWidget);

    for (final d in ['CV', 'Lamaran Kerja', 'KTP', 'Ijazah', 'Pas Foto']) {
      await tester.tap(find.text('Unggah $d'));
      // Ukuran berkas dibaca secara asinkron sungguhan.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }
    // Data tiruan tanpa path tidak punya nama berkas -> label cadangan.
    expect(find.text('Berkas terpilih'), findsNWidgets(5));
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    // Tahap 3: rekening + persetujuan.
    await isi(tester, 'Masukkan nomor rekening', '1234567890');
    await isi(tester, 'Masukkan nama pemilik rekening', 'Budi Teknisi');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Registrasi'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Pendaftaran berhasil'), findsOneWidget);
    expect(find.textContaining('menunggu verifikasi Admin'), findsOneWidget);
    await tester.tap(find.text('Kembali ke Masuk'));
    await tester.pumpAndSettle();

    // Kembali di halaman Masuk dengan email terisi; login ditolak.
    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(find.text('budi@acare.id'), findsOneWidget);
    // Login memakai jeda sungguhan, jadi dijalankan di luar jam tiruan test.
    final hasil = await tester.runAsync(
      () => AuthService.login('budi@acare.id', 'rahasia123', UserRole.teknisi),
    );
    expect(hasil, HasilLogin.belumTerverifikasi);
  });
}
