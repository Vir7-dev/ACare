import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:acare_mobile/pages/pelanggan/kelola_alamat_page.dart';
import 'package:acare_mobile/services/alamat_service.dart';
import 'package:acare_mobile/services/perangkat.dart';
import 'package:acare_mobile/widgets/peta_lokasi.dart';

void main() {
  final alamat = AlamatService.instance;

  setUpAll(() => PetaLokasi.aktif = false);
  setUp(alamat.reset);
  tearDown(alamat.reset);

  Future<void> buka(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: KelolaAlamatPage()));
  }

  testWidgets('Tambah alamat: validasi, cari di peta, lalu simpan', (
    tester,
  ) async {
    Perangkat.cariAlamat = (_) async => const LatLng(1.14, 104.01);
    await buka(tester);
    expect(find.text('Rumah'), findsOneWidget);

    await tester.tap(find.text('Tambah Alamat'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Alamat'), findsWidgets);

    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Kolom ini wajib diisi.'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'Nagoya Hill');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kantor'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(alamat.daftar.value, hasLength(2));
    final baru = alamat.daftar.value.last;
    expect(baru.label, 'Kantor');
    expect(baru.alamatLengkap, 'Nagoya Hill');
    expect(baru.latitude, 1.14);
    expect(find.text('Kantor'), findsOneWidget);
  });

  testWidgets('Hapus alamat dengan konfirmasi', (tester) async {
    await buka(tester);

    await tester.tap(find.byTooltip('Hapus alamat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(alamat.daftar.value, isEmpty);
    expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);
  });

  testWidgets('Mode pilih mengembalikan alamat yang diketuk', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AlamatTersimpan? dipilih;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                dipilih = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KelolaAlamatPage(modePilih: true),
                  ),
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
    expect(find.text('Pilih Alamat'), findsOneWidget);

    await tester.tap(find.text('Rumah'));
    await tester.pumpAndSettle();
    expect(dipilih?.label, 'Rumah');
  });
}
