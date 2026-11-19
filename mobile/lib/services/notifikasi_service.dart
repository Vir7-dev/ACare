import 'package:flutter/foundation.dart';

enum TipeNotifikasi { pesanan, pembayaran, refund, sistem }

class Notifikasi {
  final int id;
  final String judul;
  final String isi;
  final TipeNotifikasi tipe;
  final DateTime waktu;
  final bool dibaca;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.waktu,
    this.dibaca = false,
  });

  Notifikasi tandaiDibaca() => Notifikasi(
    id: id,
    judul: judul,
    isi: isi,
    tipe: tipe,
    waktu: waktu,
    dibaca: true,
  );
}

/// Daftar notifikasi pengguna (UC-05). Data tiruan.
// TODO(backend): ambil dari API notifikasi; notifikasi baru datang lewat FCM.
class NotifikasiService {
  NotifikasiService._();

  static final NotifikasiService instance = NotifikasiService._();

  final ValueNotifier<List<Notifikasi>> daftar = ValueNotifier(_awal);

  int get belumDibaca => daftar.value.where((n) => !n.dibaca).length;

  void tandaiDibaca(int id) {
    daftar.value = [
      for (final n in daftar.value) n.id == id ? n.tandaiDibaca() : n,
    ];
  }

  void tandaiSemuaDibaca() {
    daftar.value = [for (final n in daftar.value) n.tandaiDibaca()];
  }

  void reset() => daftar.value = _awal;

  static final _awal = [
    Notifikasi(
      id: 3,
      judul: 'Waktunya servis berkala',
      isi:
          'Sudah 3 bulan sejak Cuci AC terakhir. Jadwalkan servis agar AC '
          'tetap dingin dan hemat listrik.',
      tipe: TipeNotifikasi.pesanan,
      waktu: DateTime(2026, 11, 17, 8, 0),
    ),
    Notifikasi(
      id: 2,
      judul: 'Refund sudah ditransfer',
      isi: 'Dana Rp100.000 untuk pesanan #AC-6712 sudah ditransfer ke DANA.',
      tipe: TipeNotifikasi.refund,
      waktu: DateTime(2026, 8, 16, 10, 0),
      dibaca: true,
    ),
    Notifikasi(
      id: 1,
      judul: 'Pembayaran berhasil',
      isi: 'Pembayaran pesanan #AC-7710 sebesar Rp310.000 sudah kami terima.',
      tipe: TipeNotifikasi.pembayaran,
      waktu: DateTime(2026, 10, 8, 13, 0),
      dibaca: true,
    ),
  ];
}
