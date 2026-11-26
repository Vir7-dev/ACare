import 'package:flutter_test/flutter_test.dart';

import 'package:acare_mobile/services/auth_service.dart';
import 'package:acare_mobile/services/notifikasi_service.dart';
import 'package:acare_mobile/services/push_service.dart';

import 'support/push_palsu.dart';
import 'support/server_palsu.dart';

/// Pendaftaran perangkat untuk notifikasi push (FCM tiruan).
void main() {
  ServerPalsu server() => ServerPalsu.aktif;

  /// Pendaftaran berjalan di latar belakang setelah masuk.
  Future<void> tunggu() => Future<void>.delayed(Duration.zero);

  /// Tunggu sampai [syarat] terpenuhi (maks. 1 detik).
  Future<void> tungguSampai(bool Function() syarat) async {
    for (var i = 0; i < 100 && !syarat(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  tearDown(() => NotifikasiService.instance.reset());

  test('Masuk mendaftarkan perangkat; keluar melepasnya', () async {
    await ServerPalsu.masukPelanggan();
    await tungguSampai(() => PushService.tokenTerdaftar != null);

    expect(server().perangkat['token-fcm-uji'], isNotNull);
    expect(PushService.tokenTerdaftar, 'token-fcm-uji');

    await AuthService.logout();
    expect(server().perangkat, isEmpty);
    expect(PushService.tokenTerdaftar, isNull);
  });

  test('Token baru dari Firebase ikut didaftarkan', () async {
    await ServerPalsu.masukPelanggan();
    await PushService.mulai();

    PushPalsu.aktif.gantiToken('token-fcm-baru');
    await tungguSampai(() => PushService.tokenTerdaftar == 'token-fcm-baru');
    expect(server().perangkat.keys, contains('token-fcm-baru'));
    expect(PushService.tokenTerdaftar, 'token-fcm-baru');
  });

  test(
    'Izin notifikasi ditolak: tidak mendaftar, aplikasi tetap jalan',
    () async {
      PushPalsu.aktif.izin = false;
      await ServerPalsu.masukPelanggan();
      await PushService.mulai();

      expect(server().perangkat, isEmpty);
      expect(PushService.tokenTerdaftar, isNull);
    },
  );

  test('Notifikasi saat aplikasi dibuka diteruskan ke tampilan', () async {
    final diterima = <PesanPush>[];
    PushService.saatDiterima = diterima.add;
    addTearDown(() => PushService.saatDiterima = null);
    await ServerPalsu.masukPelanggan();
    await PushService.mulai();

    PushPalsu.aktif.kirim(
      const PesanPush(
        judul: 'Teknisi sudah tiba',
        isi: 'Andi sudah sampai di lokasi.',
        tipe: 'teknisi_tiba',
        idPesanan: 101,
      ),
    );
    await tunggu();

    expect(diterima.single.judul, 'Teknisi sudah tiba');
    expect(diterima.single.idPesanan, 101);
  });

  test('Notifikasi baru masuk paling atas di daftar notifikasi', () {
    final awal = NotifikasiService.instance.belumDibaca;
    NotifikasiService.instance.tambah(
      'Pesanan selesai',
      'Beri ulasan untuk teknisimu.',
      TipeNotifikasi.pesanan,
    );

    final daftar = NotifikasiService.instance.daftar.value;
    expect(daftar.first.judul, 'Pesanan selesai');
    expect(daftar.first.id, greaterThan(daftar[1].id));
    expect(NotifikasiService.instance.belumDibaca, awal + 1);
  });
}
