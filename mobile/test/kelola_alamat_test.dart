import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:acare_mobile/pages/pelanggan/form_alamat_page.dart';
import 'package:acare_mobile/pages/pelanggan/kelola_alamat_page.dart';
import 'package:acare_mobile/services/alamat_service.dart';
import 'package:acare_mobile/services/perangkat.dart';
import 'package:acare_mobile/widgets/peta_lokasi.dart';

import 'support/server_palsu.dart';

void main() {
  final alamat = AlamatService.instance;

  setUpAll(() => PetaLokasi.aktif = false);

  Future<void> buka(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ServerPalsu.masukPelanggan();
    await tester.pumpWidget(const MaterialApp(home: KelolaAlamatPage()));
    await tester.pumpAndSettle();
  }

  List<Map<String, dynamic>> diServer() => ServerPalsu.aktif.alamat[1]!;

  testWidgets('Daftar alamat dimuat dari server', (tester) async {
    await buka(tester);

    expect(find.text('Rumah'), findsOneWidget);
    expect(
      find.text('Perumahan Batu Aji Blok C No. 12, Batam'),
      findsOneWidget,
    );
    expect(ServerPalsu.aktif.log, contains('GET /alamat'));
  });

  testWidgets('Tambah alamat: validasi, cari di peta, lalu simpan ke server', (
    tester,
  ) async {
    Perangkat.cariAlamat = (_) async => const LatLng(1.14, 104.01);
    await buka(tester);

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
    expect(diServer().last['label'], 'Kantor');
  });

  testWidgets('Ubah alamat yang sudah dipakai pesanan: tersimpan dengan id '
      'baru', (tester) async {
    ServerPalsu.aktif.alamatDipakai.add(1);
    await buka(tester);

    await tester.tap(find.text('Rumah'));
    await tester.pumpAndSettle();
    expect(find.byType(FormAlamatPage), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Perumahan Batu Aji Blok C No. 12, Batam'),
      'Perumahan Batu Aji Blok D No. 1, Batam',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(alamat.daftar.value.single.id, isNot(1));
    expect(
      find.text('Perumahan Batu Aji Blok D No. 1, Batam'),
      findsOneWidget,
    );
  });

  testWidgets('Hapus alamat dengan konfirmasi', (tester) async {
    await buka(tester);

    await tester.tap(find.byTooltip('Hapus alamat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(alamat.daftar.value, isEmpty);
    expect(diServer(), isEmpty);
    expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);
  });

  testWidgets('Alamat pesanan aktif tidak bisa dihapus: pesan dari server', (
    tester,
  ) async {
    ServerPalsu.aktif.alamatDipakai.add(1);
    await buka(tester);

    await tester.tap(find.byTooltip('Hapus alamat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Alamat tidak dapat dihapus karena sedang digunakan pada pesanan aktif.',
      ),
      findsOneWidget,
    );
    expect(alamat.daftar.value, hasLength(1));
  });

  testWidgets('Mode pilih mengembalikan alamat yang diketuk', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ServerPalsu.masukPelanggan();
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
