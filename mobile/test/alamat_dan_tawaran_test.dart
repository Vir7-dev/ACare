import 'package:acare_mobile/models/alamat.dart';
import 'package:acare_mobile/models/tawaran_biaya.dart';
import 'package:acare_mobile/pages/pelanggan/detail_pesanan_page.dart';
import 'package:acare_mobile/pages/pelanggan/kelola_alamat_page.dart';
import 'package:acare_mobile/pages/umum/main_shell.dart';
import 'package:acare_mobile/services/alamat_service.dart';
import 'package:acare_mobile/services/order_service.dart';
import 'package:acare_mobile/services/perangkat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  setUp(() {
    AlamatService.instance.reset();
    OrderService.instance.reset();
  });

  void ukuranHp(WidgetTester t) {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  Future<void> isiAlamat(WidgetTester t, String label, String alamat) async {
    await t.runAsync(
      () => AlamatService.instance.tambah(
        label: label,
        alamatLengkap: alamat,
        latitude: 1.13,
        longitude: 104.05,
      ),
    );
  }

  group('Kelola alamat', () {
    testWidgets('Pilih Lokasi kosong menawarkan tambah alamat', (t) async {
      ukuranHp(t);
      await t.pumpWidget(const MaterialApp(home: MainShell()));
      await t.tap(find.text('Pilih Lokasi'));
      await t.pumpAndSettle();

      expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);
      expect(find.text('Tambah alamat baru'), findsOneWidget);
      expect(find.text('Kelola'), findsOneWidget);
    });

    testWidgets('Alamat tersimpan dipilih dan dipakai di tombol lokasi', (
      t,
    ) async {
      ukuranHp(t);
      await isiAlamat(t, 'Rumah', 'Nagoya, Batam');
      await t.pumpWidget(const MaterialApp(home: MainShell()));
      await t.pumpAndSettle();

      // Alamat pertama langsung dipakai.
      expect(find.text('Rumah'), findsOneWidget);

      await t.runAsync(
        () => AlamatService.instance.tambah(
          label: 'Kantor',
          alamatLengkap: 'Batam Centre',
          latitude: 1.13,
          longitude: 104.05,
        ),
      );
      await t.tap(find.text('Rumah'));
      await t.pumpAndSettle();
      await t.tap(find.text('Kantor'));
      await t.pumpAndSettle();

      expect(find.text('Kantor'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lokasi'), 'Batam Centre');
    });

    testWidgets('Tambah alamat dari menu lokasi lewat form peta', (t) async {
      ukuranHp(t);
      Perangkat.alamatDariKoordinat = (_) async => null;
      await t.pumpWidget(const MaterialApp(home: MainShell()));
      await t.tap(find.text('Pilih Lokasi'));
      await t.pumpAndSettle();
      await t.tap(find.text('Tambah alamat baru'));
      await t.pumpAndSettle();

      expect(find.text('Tambah Alamat'), findsOneWidget);
      expect(find.text('Cari alamat atau tempat'), findsOneWidget);

      // Kosong ditolak
      await t.ensureVisible(find.text('Simpan'));
      await t.tap(find.text('Simpan'));
      await t.pump();
      expect(find.text('Kolom ini wajib diisi.'), findsNWidgets(2));

      await t.tap(find.text('Rumah').first);
      await t.pump();
      await t.enterText(
        find.widgetWithText(TextFormField, 'Jalan, nomor, kelurahan, kota'),
        'Jl. Engku Putri No. 12, Batam Centre',
      );
      await t.tap(find.text('Simpan'));
      await t.pumpAndSettle();

      expect(find.text('Alamat berhasil disimpan'), findsOneWidget);
      expect(find.text('Rumah'), findsOneWidget);
      expect(AlamatService.instance.daftar.single.label, 'Rumah');
    });

    testWidgets('Cari tempat di OpenStreetMap mengisi alamat', (t) async {
      ukuranHp(t);
      Perangkat.cariTempat = (kata) async => const [
        HasilTempat(
          nama: 'Nagoya Hill, Batam',
          latitude: 1.1458,
          longitude: 104.0102,
        ),
      ];
      await t.pumpWidget(
        const MaterialApp(home: KelolaAlamatPage()),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Tambah Alamat').last);
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField).first, 'nagoya');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(find.text('Nagoya Hill, Batam'), findsOneWidget);

      await t.tap(find.text('Nagoya Hill, Batam'));
      await t.pumpAndSettle();
      expect(find.text('Nagoya Hill, Batam'), findsOneWidget);
    });

    testWidgets('Pencarian gagal menampilkan pesan', (t) async {
      ukuranHp(t);
      Perangkat.cariTempat = (_) async => throw Exception('offline');
      await t.pumpWidget(
        const MaterialApp(home: KelolaAlamatPage()),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Tambah Alamat').last);
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField).first, 'nagoya');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();

      expect(
        find.text('Pencarian gagal, periksa koneksi internet'),
        findsOneWidget,
      );
    });

    testWidgets('Daftar kosong, ubah, dan hapus alamat', (t) async {
      ukuranHp(t);
      await t.pumpWidget(const MaterialApp(home: KelolaAlamatPage()));
      await t.pumpAndSettle();
      expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);

      await isiAlamat(t, 'Rumah', 'Jl. Melati No. 3');
      await t.pumpAndSettle();
      expect(find.text('Jl. Melati No. 3'), findsOneWidget);
      expect(find.text('Dipakai'), findsOneWidget);

      await t.tap(find.byTooltip('Ubah alamat'));
      await t.pumpAndSettle();
      expect(find.text('Ubah Alamat'), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextFormField, 'Jalan, nomor, kelurahan, kota'),
        'Jl. Mawar No. 9',
      );
      await t.ensureVisible(find.text('Simpan'));
      await t.tap(find.text('Simpan'));
      await t.pumpAndSettle();
      expect(find.text('Jl. Mawar No. 9'), findsOneWidget);

      await t.tap(find.byTooltip('Hapus alamat'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ya, Hapus'));
      await t.pumpAndSettle();
      expect(find.text('Belum ada alamat tersimpan'), findsOneWidget);
      expect(AlamatService.instance.daftar, isEmpty);
    });

    testWidgets('Alamat pesanan aktif tidak bisa dihapus', (t) async {
      ukuranHp(t);
      await isiAlamat(t, 'Rumah', 'Jl. Melati No. 3');
      OrderService.instance.pesananAktif.value = _pesananAktif('Cuci AC');
      await t.pumpWidget(const MaterialApp(home: KelolaAlamatPage()));
      await t.pumpAndSettle();

      await t.tap(find.byTooltip('Hapus alamat'));
      await t.pumpAndSettle();

      expect(
        find.text(
          'Alamat tidak dapat dihapus karena sedang digunakan pada pesanan '
          'aktif',
        ),
        findsOneWidget,
      );
      expect(AlamatService.instance.daftar, hasLength(1));
    });
  });

  group('Tanggapi biaya perbaikan', () {
    Future<void> bukaDetail(WidgetTester t, [DateTime? sejak]) async {
      ukuranHp(t);
      t.view.physicalSize = const Size(390, 1800);
      OrderService.instance.pesananAktif.value = _pesananAktif('Service AC');
      OrderService.instance.ajukanTawaranContoh(sejak);
      await t.pumpWidget(
        MaterialApp(
          home: DetailPesananPage(
            teknisi: OrderService.instance.pesananAktif.value!.teknisi!,
            otomatis: false,
          ),
        ),
      );
      await t.pump();
    }

    testWidgets('Rincian biaya dan hitung mundur tampil', (t) async {
      await bukaDetail(t);

      expect(find.text('Biaya Perbaikan'), findsOneWidget);
      expect(find.text('Menunggu persetujuan'), findsOneWidget);
      expect(find.text('Jasa las pipa dan perbaikan saluran bocor'),
          findsOneWidget);
      // 100.000 (Service AC) + 120.000 + 150.000
      expect(find.text('Rp 370.000'), findsOneWidget);
      expect(find.byKey(const Key('sisa-tanggapan')), findsOneWidget);
      expect(find.text('Setuju'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });

    testWidgets('Setuju melanjutkan pekerjaan', (t) async {
      await bukaDetail(t);

      await t.tap(find.text('Setuju'));
      await t.pump();

      expect(
        OrderService.instance.tawaranBiaya.value!.status,
        StatusTawaran.disetujui,
      );
      expect(find.text('Melakukan Perbaikan'), findsWidgets);
      expect(find.text('Setuju'), findsNothing);
      expect(
        find.textContaining('Anda menyetujui biaya perbaikan'),
        findsOneWidget,
      );
    });

    testWidgets('Tolak meminta konfirmasi lalu menyelesaikan pesanan', (
      t,
    ) async {
      await bukaDetail(t);

      await t.tap(find.text('Tolak'));
      await t.pumpAndSettle();
      expect(find.text('Tolak biaya perbaikan?'), findsOneWidget);

      // Batal: tetap menunggu
      await t.tap(find.text('Kembali'));
      await t.pumpAndSettle();
      expect(OrderService.instance.tawaranBiaya.value!.menunggu, isTrue);

      await t.tap(find.text('Tolak'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ya, Tolak'));
      await t.pumpAndSettle();

      expect(
        OrderService.instance.tawaranBiaya.value!.status,
        StatusTawaran.ditolak,
      );
      expect(find.text('Selesai (hanya biaya awal)'), findsOneWidget);
      expect(find.textContaining('Anda menolak biaya perbaikan'), findsOneWidget);
    });

    testWidgets('Batas waktu terlewat dianggap menolak', (t) async {
      // Tawaran diajukan lebih dari 10 menit lalu.
      await bukaDetail(
        t,
        DateTime.now().subtract(
          OrderService.batasTanggapan + const Duration(minutes: 1),
        ),
      );

      await t.pump(const Duration(seconds: 2));

      expect(
        OrderService.instance.tawaranBiaya.value!.status,
        StatusTawaran.kedaluwarsa,
      );
      expect(find.text('Selesai (hanya biaya awal)'), findsOneWidget);
    });

    testWidgets('Layanan tanpa biaya tambahan tidak mengajukan tawaran', (
      t,
    ) async {
      ukuranHp(t);
      OrderService.instance.pesananAktif.value = _pesananAktif('Cuci AC');
      await t.pumpWidget(
        MaterialApp(
          home: DetailPesananPage(
            teknisi: OrderService.instance.pesananAktif.value!.teknisi!,
            durasiStatus: const Duration(milliseconds: 100),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 150));

      expect(OrderService.instance.tawaranBiaya.value, isNull);
      expect(find.text('Biaya Perbaikan'), findsNothing);
      await t.pumpAndSettle(const Duration(milliseconds: 200));
    });

    testWidgets('Notifikasi beranda membuka tanggapan biaya', (t) async {
      ukuranHp(t);
      OrderService.instance.pesananAktif.value = _pesananAktif('Service AC');
      OrderService.instance.ajukanTawaranContoh();
      await t.pumpWidget(const MaterialApp(home: MainShell()));
      await t.pump();

      await t.tap(find.byIcon(Icons.notifications_none));
      await t.pumpAndSettle();
      expect(find.text('Biaya perbaikan menunggu persetujuan'), findsOneWidget);

      await t.tap(find.text('Biaya perbaikan menunggu persetujuan'));
      await t.pumpAndSettle();
      expect(find.text('Detail Pesanan'), findsOneWidget);
      expect(find.text('Setuju'), findsOneWidget);
    });
  });
}

PesananPelanggan _pesananAktif(String layanan) => PesananPelanggan(
  layanan: OrderService.layananDenganNama(layanan),
  jumlahUnit: 1,
  jenisAc: JenisAc.split,
  pk: 1,
  alamat: 'Jl. Melati No. 3',
  detailAlamat: '',
  jadwal: DateTime(2026, 11, 9, 10),
  metodeBayar: 'Tunai',
  totalEstimasi: 105000,
  status: StatusPesananPelanggan.teknisiDitemukan,
  namaTeknisi: 'GanAnWo',
  plat: 'BP 4892 QL',
  rating: '4.9',
  jumlahUlasan: 67,
);
