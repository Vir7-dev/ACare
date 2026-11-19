import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/pelanggan/buat_pesanan_page.dart';
import 'package:acare_mobile/pages/pelanggan/mencari_teknisi_page.dart';
import 'package:acare_mobile/pages/umum/main_shell.dart';
import 'package:acare_mobile/services/order_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() => OrderService.instance.reset());

  Future<void> buka(WidgetTester tester, Widget halaman) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: halaman));
    await tester.pumpAndSettle();
  }

  /// Isi "Detail alamat / patokan", field terakhir sebelum jadwal.
  Future<void> isiAlamat(WidgetTester tester, String teks) async {
    final field = find.widgetWithText(
      TextFormField,
      'Contoh: Blok C No. 12, sebelah warung',
    );
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field, teks);
    await tester.pump();
  }

  /// Scroll ke tombol "Lanjut" (ada di bawah layar) lalu tap.
  Future<void> tapLanjut(WidgetTester tester) async {
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Biaya awal = harga layanan x jumlah unit, tanpa biaya aplikasi',
    (tester) async {
      final cuci = OrderService.layananDenganNama('Cuci AC');

      expect(OrderService.hitungBiayaAwal(cuci, 2), cuci.harga * 2);
    },
  );

  testWidgets('Form detail pesanan: validasi lalu ke ringkasan pembayaran', (
    tester,
  ) async {
    await buka(
      tester,
      BuatPesananPage(layanan: OrderService.layananDenganNama('Cuci AC')),
    );

    // Tanpa jenis AC, PK, dan detail alamat -> tetap di form.
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);

    await tester.tap(find.text('Split'));
    await tester.tap(find.text('1.5 PK'));
    await tester.pump();

    await isiAlamat(tester, 'Blok C No. 12');
    await tapLanjut(tester);

    expect(find.text('Ringkasan Pembayaran'), findsOneWidget);
    expect(find.text('Rincian Harga'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
    expect(find.text('Virtual Account'), findsOneWidget);
    // Non-tunai saja dan tanpa biaya aplikasi.
    expect(find.text('Tunai'), findsNothing);
    expect(find.text('Biaya aplikasi'), findsNothing);
    expect(find.textContaining('Bayar Rp'), findsOneWidget);
  });

  testWidgets('Service AC menampilkan info biaya tambahan', (tester) async {
    await buka(
      tester,
      BuatPesananPage(layanan: OrderService.layananDenganNama('Service AC')),
    );

    // Checklist keluhan hanya untuk Service AC.
    expect(find.text('Keluhan'), findsOneWidget);
    expect(find.text('Tidak dingin'), findsOneWidget);

    await tester.tap(find.text('Split'));
    await tester.tap(find.text('1 PK'));
    await isiAlamat(tester, 'Kamar tidur');
    await tapLanjut(tester);

    expect(
      find.text(
        'Biaya perbaikan bisa bertambah setelah diagnosis dan perlu '
        'persetujuanmu',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cuci AC tidak menampilkan keluhan maupun info biaya tambahan', (
    tester,
  ) async {
    await buka(
      tester,
      BuatPesananPage(layanan: OrderService.layananDenganNama('Cuci AC')),
    );

    expect(find.text('Keluhan'), findsNothing);
    expect(find.text('Jenis Freon'), findsNothing);
    expect(find.text('Jenis Pekerjaan'), findsNothing);
  });

  testWidgets('Cek AC: tanpa keluhan, cukup catatan, Rp50.000, biaya '
      'perbaikan bisa diajukan setelah pengecekan', (tester) async {
    final cek = OrderService.layananDenganNama('Cek AC');
    expect(cek.harga, 50000);
    expect(OrderService.layananBerbiayaTambahan.contains('Cek AC'), isTrue);

    await buka(tester, BuatPesananPage(layanan: cek));
    expect(find.text('Keluhan'), findsNothing);
    expect(find.text('Ceritakan kondisi AC (opsional)'), findsOneWidget);
  });

  testWidgets('Isi Freon wajib memilih jenis freon', (tester) async {
    await buka(
      tester,
      BuatPesananPage(layanan: OrderService.layananDenganNama('Isi Freon')),
    );

    expect(find.text('Jenis Freon'), findsOneWidget);

    await tester.tap(find.text('Split'));
    await tester.tap(find.text('1 PK'));
    await isiAlamat(tester, 'Ruang tamu');
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Jenis freon wajib dipilih'), findsOneWidget);
    expect(find.text('Ringkasan Pembayaran'), findsNothing);

    await tester.tap(find.text('R32'));
    await tester.pump();
    await tapLanjut(tester);
    expect(find.text('Ringkasan Pembayaran'), findsOneWidget);
  });

  testWidgets('Tombol Ganti pada kartu layanan kembali ke halaman sebelumnya', (
    tester,
  ) async {
    await buka(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BuatPesananPage(
                    layanan: OrderService.layananDenganNama('Cuci AC'),
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);

    await tester.tap(find.text('Ganti'));
    await tester.pumpAndSettle();
    expect(find.text('Buka'), findsOneWidget);
  });

  testWidgets('Batalkan pesanan saat mencari: kembali, pesanan aktif null', (
    tester,
  ) async {
    final cuci = OrderService.layananDenganNama('Cuci AC');

    await buka(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MencariTeknisiPage(
                    layanan: cuci,
                    lamaCari: const Duration(seconds: 10),
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Mencari Teknisi Terdekat...'), findsOneWidget);

    await tester.tap(find.text('Batalkan Pesanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Batalkan'));
    await tester.pumpAndSettle();

    // Kembali ke halaman sebelumnya dan pencarian dihentikan.
    expect(find.text('Buka'), findsOneWidget);
    expect(find.text('Mencari Teknisi Terdekat...'), findsNothing);
    expect(OrderService.instance.pesananAktif.value, isNull);
  });

  testWidgets('Dari tracking, kembali ke beranda: pesanan berlangsung tampil', (
    tester,
  ) async {
    await buka(tester, const MainShell());

    await tester.tap(find.text('Lihat Detail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih').first);
    await tester.pumpAndSettle();

    // Lengkapi form minimal lalu lanjut ke ringkasan.
    await tester.tap(find.text('Split'));
    await tester.tap(find.text('1 PK'));
    await isiAlamat(tester, 'Blok C No. 12');
    await tapLanjut(tester);

    // Bayar biaya awal (QRIS default) sebelum mencari teknisi.
    await tester.tap(find.textContaining('Bayar Rp'));
    // Jangan pumpAndSettle: timer 5 detik akan ikut berjalan sampai habis.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pembayaran QRIS'), findsOneWidget);
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);

    // 5 detik dummy: pembayaran berhasil -> mencari teknisi.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Mencari Teknisi Terdekat...'), findsOneWidget);
    expect(OrderService.instance.pesananAktif.value?.metodeBayar, 'QRIS');

    // Pencarian (lamaCari default 5 detik) -> tracking teknisi.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);

    // 5 detik setelah tracking -> detail pesanan, mulai dari pengecekan awal.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Pengecekan Awal'), findsWidgets);
    // Teknisi sudah ditemukan: pesanan tidak bisa dibatalkan.
    expect(find.text('Batalkan Pesanan'), findsNothing);

    // Teknisi mengajukan biaya perbaikan -> pelanggan menyetujui.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(find.text('Rincian Biaya Perbaikan'), findsOneWidget);
    await tester.ensureVisible(find.text('Setuju'));
    await tester.tap(find.text('Setuju'));
    await tester.pump();
    expect(find.text('Melakukan Perbaikan'), findsWidgets);

    // Perbaikan selesai -> pelunasan.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    await tester.ensureVisible(find.text('Bayar Pesanan'));
    await tester.tap(find.text('Bayar Pesanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BAYAR'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Total dibayar'), findsOneWidget);

    // Back dari detail pesanan -> beranda dengan section "Sedang Berlangsung".
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Kategori Layanan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sedang Berlangsung'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sedang Berlangsung'), findsOneWidget);
    expect(find.text('GanAnWo'), findsOneWidget);
  });
}
