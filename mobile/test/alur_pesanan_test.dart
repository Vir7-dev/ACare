import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:acare_mobile/pages/pelanggan/buat_pesanan_page.dart';
import 'package:acare_mobile/pages/pelanggan/mencari_teknisi_page.dart';
import 'package:acare_mobile/pages/umum/main_shell.dart';
import 'package:acare_mobile/services/order_service.dart';

import 'support/server_palsu.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() => OrderService.instance.reset());

  /// Buka halaman sebagai pelanggan yang sudah masuk (punya alamat "Rumah").
  Future<void> buka(WidgetTester tester, Widget halaman) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ServerPalsu.masukPelanggan();
    await tester.pumpWidget(MaterialApp(home: halaman));
    await tester.pumpAndSettle();
  }

  /// Pesanan Cuci AC yang sudah dibuat dan dibayar di server palsu.
  Future<PesananPelanggan> pesananDibayar() async {
    await ServerPalsu.masukPelanggan();
    final dibuat = await OrderService.instance.buat(
      PesananPelanggan(
        idLokasi: 1,
        layanan: OrderService.layananDenganNama('Cuci AC'),
        jumlahUnit: 1,
        jenisAc: JenisAc.split,
        pk: 1,
        alamat: 'Perumahan Batu Aji Blok C No. 12, Batam',
        detailAlamat: 'Pagar hitam',
        jadwal: DateTime.now(),
        metodeBayar: 'QRIS',
        biayaAwal: 75000,
      ),
    );
    final (dibayar, _) = await OrderService.instance.simulasiBayar(
      dibuat.id!,
      dibuat.idPembayaranAwal!,
    );
    return dibayar;
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
    await tester.tap(find.text('Tidak dingin'));
    await isiAlamat(tester, 'Kamar tidur');
    await tapLanjut(tester);

    expect(
      find.text(
        'Biaya perbaikan bisa bertambah setelah diagnosis dan perlu '
        'persetujuanmu',
      ),
      findsOneWidget,
    );
    // Keluhan tersimpan terstruktur, tampil sebagai baris sendiri.
    expect(find.text('Keluhan'), findsOneWidget);
    expect(find.text('Catatan'), findsNothing);
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

  Widget tombolBuka(PesananPelanggan p) => Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MencariTeknisiPage(pesanan: p)),
          ),
          child: const Text('Buka'),
        ),
      ),
    ),
  );

  testWidgets('Batalkan pesanan saat mencari: batal di server, dana tertahan', (
    tester,
  ) async {
    ServerPalsu.aktif.terimaSetelahPeriksa = null;
    final p = await pesananDibayar();
    await buka(tester, tombolBuka(p));

    await tester.tap(find.text('Buka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Mencari Teknisi Terdekat...'), findsOneWidget);

    await tester.tap(find.text('Batalkan Pesanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Batalkan'));
    await tester.pumpAndSettle();

    // Kembali ke halaman sebelumnya dan pencarian dihentikan.
    expect(find.text('Buka'), findsOneWidget);
    expect(find.text('Mencari Teknisi Terdekat...'), findsNothing);
    expect(OrderService.instance.pesananAktif.value, isNull);
    final diServer = ServerPalsu.aktif.pesanan.single;
    expect(diServer['status'], 'dibatalkan');
    expect((diServer['pembayaran'] as List).first['status'], 'tertahan');
  });

  testWidgets('Tidak ada teknisi dalam batas waktu: kembali dengan pesan', (
    tester,
  ) async {
    ServerPalsu.aktif.terimaSetelahPeriksa = null;
    final p = await pesananDibayar();
    await buka(tester, tombolBuka(p));
    await tester.tap(find.text('Buka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    ServerPalsu.aktif.habisWaktuPencarian(p.id!);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Buka'), findsOneWidget);
    expect(
      find.textContaining('Belum ada teknisi yang tersedia'),
      findsOneWidget,
    );
    expect(OrderService.instance.pesananAktif.value, isNull);
  });

  testWidgets('Masih ada pesanan aktif: pesan dari server saat bayar', (
    tester,
  ) async {
    ServerPalsu.aktif.terimaSetelahPeriksa = null;
    await pesananDibayar();
    await buka(
      tester,
      BuatPesananPage(layanan: OrderService.layananDenganNama('Cuci AC')),
    );
    await tester.tap(find.text('Split'));
    await tester.tap(find.text('1 PK'));
    await isiAlamat(tester, 'Blok C No. 12');
    await tapLanjut(tester);

    await tester.tap(find.textContaining('Bayar Rp'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Masih ada pesanan yang sedang berjalan'),
      findsOneWidget,
    );
    expect(find.text('Ringkasan Pembayaran'), findsOneWidget);
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
    // Jangan pumpAndSettle: pemeriksaan status berkala ikut berjalan.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pembayaran QRIS'), findsOneWidget);
    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.byKey(const Key('kode-qris')), findsOneWidget);

    // Pemeriksaan status berikutnya: Xendit (tiruan) melaporkan lunas.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Mencari Teknisi Terdekat...'), findsOneWidget);
    expect(ServerPalsu.aktif.pesanan.single['status'], 'mencari_teknisi');
    expect(OrderService.instance.pesananAktif.value?.sudahDibayar, isTrue);

    // Status diperiksa ke server; teknisi palsu menerima -> tracking.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Teknisi Menuju Lokasi'), findsOneWidget);
    expect(find.text('Andi Saputra'), findsOneWidget);

    final server = ServerPalsu.aktif;
    final id = server.pesanan.single['id'] as int;

    // Teknisi (di server) mulai pengecekan -> detail pesanan.
    server.majukan(id, 'pengecekan_awal');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Pengecekan Awal'), findsWidgets);
    // Teknisi sudah ditemukan: pesanan tidak bisa dibatalkan.
    expect(find.text('Batalkan Pesanan'), findsNothing);

    // Teknisi mengajukan biaya perbaikan -> pelanggan menyetujui.
    server.ajukanBiaya(id, {'Kapasitor': 85000});
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Rincian Biaya Perbaikan'), findsOneWidget);
    await tester.ensureVisible(find.text('Setuju'));
    await tester.pump();
    await tester.tap(find.text('Setuju'));
    await tester.pumpAndSettle();
    expect(find.text('Melakukan Perbaikan'), findsWidgets);

    // Perbaikan selesai -> pelunasan.
    server.selesaiDikerjakan(id);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bayar Pesanan'));
    await tester.pump();
    await tester.tap(find.text('Bayar Pesanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    // E-wallet: pilih DANA, lalu tunggu status lunas.
    await tester.tap(find.text('DANA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('Total dibayar'), findsOneWidget);
    expect(server.pesanan.single['status'], 'selesai');

    // Back ke beranda: pesanan sudah selesai, tidak ada yang berlangsung.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Kategori Layanan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sedang Berlangsung'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Belum ada pesanan berjalan'), findsOneWidget);
    expect(
      OrderService.instance.servisTerakhir.value?.status,
      StatusPesananPelanggan.selesai,
    );
  });
}
