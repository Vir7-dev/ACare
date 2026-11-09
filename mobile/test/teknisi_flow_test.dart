import 'package:acare_mobile/models/pesanan_teknisi.dart';
import 'package:acare_mobile/pages/teknisi/teknisi_shell.dart';
import 'package:acare_mobile/services/perangkat.dart';
import 'package:acare_mobile/services/teknisi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> _buka(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: TeknisiShell()));
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() => TeknisiService.instance.reset());

  test('komisi platform 15% dihitung dari total tagihan', () {
    final p = TeknisiService.instance;
    p.periksaPesananMasuk();
    p.terimaPesanan();
    p.kirimRincianBiaya(const [
      ItemBiaya(jenis: JenisItemBiaya.jasa, nama: 'Las pipa', harga: 120000),
      ItemBiaya(jenis: JenisItemBiaya.sparepart, nama: 'Freon', harga: 150000),
    ], '');
    final a = p.pesananAktif!;
    expect(a.totalTagihan, 320000);
    expect(a.potonganPlatform, 48000);
    expect(a.pendapatanBersih, 272000);
  });

  testWidgets('pesanan masuk bisa ditolak lalu halaman menunggu', (t) async {
    await _buka(t);
    expect(find.text('Pesanan masuk'), findsOneWidget);
    await t.tap(find.text('Tolak'));
    await t.pump();
    expect(find.textContaining('Menunggu pesanan masuk'), findsOneWidget);
  });

  testWidgets('dari terima pesanan sampai saldo dompet bertambah', (t) async {
    Perangkat.ambilFoto = () async => XFile('bukti.jpg');
    await _buka(t);

    await t.tap(find.text('Terima pesanan'));
    await t.pumpAndSettle();
    expect(find.text('Pengerjaan servis'), findsOneWidget);

    await t.tap(find.text('Saya sudah tiba'));
    await t.pump();
    await t.tap(find.text('Mulai diagnosis'));
    await t.pump();
    await t.tap(find.text('Selesai cek & input estimasi biaya'));
    await t.pumpAndSettle();

    // Kirim kosong ditolak
    await t.tap(find.text('Kirim rincian biaya & lanjut perbaikan'));
    await t.pump();
    expect(find.text('Isi minimal satu biaya perbaikan.'), findsOneWidget);

    final isian = find.byType(TextField);
    await t.enterText(isian.at(0), 'Las pipa');
    await t.enterText(isian.at(1), '120000');
    await t.enterText(isian.at(2), 'Freon R32');
    await t.enterText(isian.at(3), '150000');
    await t.pump();
    await t.drag(find.byType(ListView).last, const Offset(0, -700));
    await t.pump();
    expect(find.text('Rp 320.000'), findsOneWidget);

    await t.tap(find.text('Kirim rincian biaya & lanjut perbaikan'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pelanggan menyetujui (simulasi)'));
    await t.pump();
    await t.tap(find.text('Unggah bukti kerja'));
    await t.pumpAndSettle();

    // Tanpa foto dan catatan ditolak
    await t.tap(find.text('Konfirmasi & selesaikan order'));
    await t.pump();
    expect(find.text('Foto sebelum dan sesudah wajib diunggah.'), findsOneWidget);

    await t.tap(find.text('Sebelum'));
    await t.pump();
    await t.tap(find.text('Sesudah'));
    await t.pump();
    await t.enterText(find.byType(TextField), 'Pipa dilas, freon diisi.');
    await t.tap(find.text('Konfirmasi & selesaikan order'));
    await t.pumpAndSettle();

    expect(TeknisiService.instance.pesananAktif, isNull);
    // 850.000 + (320.000 - 15%) = 1.122.000
    expect(TeknisiService.instance.saldo, 1122000);

    await t.tap(find.text('Dompet'));
    await t.pumpAndSettle();
    expect(find.text('Rp 1.122.000'), findsOneWidget);
  });

  testWidgets('tarik dana mengurangi saldo dan menampilkan bukti', (t) async {
    await _buka(t);
    await t.tap(find.text('Dompet'));
    await t.pumpAndSettle();

    await t.tap(find.text('Tarik dana'));
    await t.pumpAndSettle();

    await t.tap(find.text('Ajukan pencairan'));
    await t.pump();
    expect(find.textContaining('Minimal'), findsWidgets);

    await t.enterText(find.byType(TextField), '100000');
    await t.tap(find.text('Ajukan pencairan'));
    await t.pumpAndSettle();
    expect(find.text('Konfirmasi PIN keamanan'), findsOneWidget);
    for (final d in ['1', '2', '3', '4', '5', '6']) {
      await t.tap(find.text(d));
    }
    await t.pump();
    await t.tap(find.text('Konfirmasi & cairkan sekarang'));
    await t.pumpAndSettle();
    expect(find.text('Pencairan berhasil!'), findsOneWidget);
    expect(TeknisiService.instance.saldo, 750000);

    await t.tap(find.widgetWithText(ElevatedButton, 'Selesai'));
    await t.pumpAndSettle();
    expect(find.text('Rp 750.000'), findsOneWidget);
  });

  testWidgets('profil tidak lagi punya bottom nav sendiri', (t) async {
    await _buka(t);
    await t.tap(find.text('Profil'));
    await t.pumpAndSettle();
    expect(find.text('Dampat'), findsNothing);
    expect(find.text('Beranda'), findsOneWidget);
  });
}
