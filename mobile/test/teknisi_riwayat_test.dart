import 'package:acare_mobile/models/pesanan_teknisi.dart';
import 'package:acare_mobile/pages/teknisi/teknisi_shell.dart';
import 'package:acare_mobile/services/teknisi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() => TeknisiService.instance.reset());

  Future<void> bukaRiwayat(WidgetTester t) async {
    t.view.physicalSize = const Size(780, 1800);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: TeknisiShell()));
    await t.pump();
    await t.tap(find.text('Pesanan'));
    await t.pumpAndSettle();
    await t.tap(find.text('Riwayat'));
    await t.pumpAndSettle();
  }

  testWidgets('Ringkasan dan daftar riwayat layanan tampil', (t) async {
    await bukaRiwayat(t);

    expect(find.text('4'), findsOneWidget);
    expect(find.text('Order selesai'), findsOneWidget);
    // (5 + 4 + 3) / 3
    expect(find.text('4.0'), findsOneWidget);
    // 170.000 + 85.000 + 127.500 + 42.500
    expect(find.text('Rp 425.000'), findsOneWidget);

    expect(find.text('Service AC'), findsOneWidget);
    expect(find.text('Ibu Sari Wulandari  •  Batam Centre'), findsOneWidget);
    expect(find.text('Rp 170.000'), findsOneWidget);
    // Pesanan tanpa rating
    expect(find.text('Belum dinilai'), findsWidgets);
  });

  testWidgets('Filter belum dinilai menyaring daftar', (t) async {
    await bukaRiwayat(t);

    await t.tap(find.widgetWithText(ChoiceChip, 'Belum dinilai'));
    await t.pumpAndSettle();
    expect(find.text('Isi Freon'), findsOneWidget);
    expect(find.text('Service AC'), findsNothing);

    await t.tap(find.widgetWithText(ChoiceChip, 'Sudah dinilai'));
    await t.pumpAndSettle();
    expect(find.text('Isi Freon'), findsNothing);
    expect(find.text('Service AC'), findsOneWidget);
  });

  testWidgets('Detail memuat rincian biaya dan rating Pelanggan', (t) async {
    await bukaRiwayat(t);

    await t.tap(find.text('Service AC'));
    await t.pumpAndSettle();

    expect(find.text('Detail riwayat'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsOneWidget);
    expect(find.text('- Rp 30.000'), findsOneWidget);
    expect(find.text('Rp 170.000'), findsOneWidget);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.textContaining('Teknisinya ramah'), findsOneWidget);
    expect(find.text('3 foto bukti'), findsOneWidget);
  });

  testWidgets('Detail pesanan tanpa perbaikan dan tanpa rating', (t) async {
    await bukaRiwayat(t);

    await t.tap(find.text('Cek AC (Diagnosis Kerusakan)'));
    await t.pumpAndSettle();
    expect(find.text('Selesai tanpa perbaikan'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);

    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('Isi Freon'));
    await t.pumpAndSettle();
    expect(find.text('Pelanggan belum memberi penilaian.'), findsOneWidget);
  });

  testWidgets('Tanpa riwayat tampil pesan kosong', (t) async {
    TeknisiService.instance.kosongkanRiwayat();
    await bukaRiwayat(t);

    expect(find.text('Belum ada riwayat layanan'), findsOneWidget);
    expect(find.text('Order selesai'), findsNothing);
  });

  testWidgets('Order yang baru selesai masuk paling atas', (t) async {
    final s = TeknisiService.instance;
    s.periksaPesananMasuk();
    s.terimaPesanan();
    s.kirimRincianBiaya(const [
      ItemBiaya(jenis: JenisItemBiaya.jasa, nama: 'Las pipa', harga: 50000),
    ], '');
    s.biayaDisetujui();
    s.selesaikanOrder(ringkasan: 'Selesai dikerjakan', jumlahFoto: 2);
    expect(s.riwayat.first.selesaiPada, isNotNull);
    expect(s.riwayat.first.ratingDiterima, isNull);

    await bukaRiwayat(t);

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Bpk. Hendra Gunawan  •  Batam Centre, Kota Batam'), findsOneWidget);
  });
}
