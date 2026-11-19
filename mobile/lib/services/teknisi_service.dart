import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tahap pekerjaan yang dijalankan teknisi untuk satu pesanan.
enum TahapPekerjaan {
  menuju('Menuju'),
  tiba('Tiba'),
  pengecekan('Pengecekan'),
  perbaikan('Perbaikan'),
  selesai('Selesai');

  final String label;
  const TahapPekerjaan(this.label);
}

/// Status rincian biaya perbaikan yang diajukan ke pelanggan.
enum StatusBiaya { belumDiajukan, menunggu, disetujui, ditolak }

enum JenisItemBiaya {
  jasa('Jasa Perbaikan'),
  sukuCadang('Suku Cadang / Material');

  final String label;
  const JenisItemBiaya(this.label);
}

class ItemBiaya {
  final String nama;
  final JenisItemBiaya jenis;
  final int harga;

  const ItemBiaya({
    required this.nama,
    required this.jenis,
    required this.harga,
  });
}

/// Tawaran pesanan yang dikirim sistem ke teknisi aktif terdekat (UC-20).
class TawaranPesanan {
  final String kode;
  final String layanan;
  final String unitAc;

  /// Biaya awal yang sudah dibayar pelanggan.
  final int ongkosAwal;

  /// Layanan yang bisa bertambah biaya setelah pengecekan.
  final bool bisaBiayaTambahan;
  final String namaPelanggan;
  final String ratingPelanggan;
  final String teleponPelanggan;
  final String alamat;
  final String wilayah;
  final double jarakKm;
  final int menitTempuh;
  final String catatan;

  const TawaranPesanan({
    required this.kode,
    required this.layanan,
    required this.unitAc,
    required this.ongkosAwal,
    required this.bisaBiayaTambahan,
    required this.namaPelanggan,
    required this.ratingPelanggan,
    required this.teleponPelanggan,
    required this.alamat,
    required this.wilayah,
    required this.jarakKm,
    required this.menitTempuh,
    required this.catatan,
  });
}

/// Pesanan yang sedang dikerjakan teknisi.
class PekerjaanTeknisi {
  final TawaranPesanan pesanan;
  final TahapPekerjaan tahap;
  final StatusBiaya statusBiaya;
  final List<ItemBiaya> itemBiaya;
  final String catatanBiaya;

  /// Waktu tiap tahap dicapai, untuk garis waktu.
  final Map<TahapPekerjaan, DateTime> waktu;

  /// Foto pemeriksaan unit (nama berkas), diambil saat pengecekan.
  final List<String> fotoPemeriksaan;

  const PekerjaanTeknisi({
    required this.pesanan,
    this.tahap = TahapPekerjaan.menuju,
    this.statusBiaya = StatusBiaya.belumDiajukan,
    this.itemBiaya = const [],
    this.catatanBiaya = '',
    this.waktu = const {},
    this.fotoPemeriksaan = const [],
  });

  int get totalBiayaPerbaikan => itemBiaya.fold(0, (a, i) => a + i.harga);

  /// Total yang dibayar pelanggan: biaya awal + biaya perbaikan yang
  /// disetujui.
  int get totalTagihan =>
      pesanan.ongkosAwal +
      (statusBiaya == StatusBiaya.disetujui ? totalBiayaPerbaikan : 0);

  PekerjaanTeknisi copyWith({
    TahapPekerjaan? tahap,
    StatusBiaya? statusBiaya,
    List<ItemBiaya>? itemBiaya,
    String? catatanBiaya,
    Map<TahapPekerjaan, DateTime>? waktu,
    List<String>? fotoPemeriksaan,
  }) {
    return PekerjaanTeknisi(
      pesanan: pesanan,
      tahap: tahap ?? this.tahap,
      statusBiaya: statusBiaya ?? this.statusBiaya,
      itemBiaya: itemBiaya ?? this.itemBiaya,
      catatanBiaya: catatanBiaya ?? this.catatanBiaya,
      waktu: waktu ?? this.waktu,
      fotoPemeriksaan: fotoPemeriksaan ?? this.fotoPemeriksaan,
    );
  }
}

/// Satu pesanan yang sudah diselesaikan teknisi.
class RiwayatLayanan {
  final String kode;
  final String layanan;
  final String namaPelanggan;
  final String wilayah;
  final DateTime selesaiPada;

  /// Pendapatan bersih teknisi setelah potongan platform.
  final int diterima;

  /// Rating dari pelanggan; `null` bila belum dinilai.
  final int? rating;

  const RiwayatLayanan({
    required this.kode,
    required this.layanan,
    required this.namaPelanggan,
    required this.wilayah,
    required this.selesaiPada,
    required this.diterima,
    this.rating,
  });
}

/// Pengajuan pencairan saldo teknisi (ditransfer manual oleh Admin).
class PengajuanPencairan {
  final String kode;
  final int nominal;
  final String rekening;
  final DateTime diajukanPada;
  final String status;

  const PengajuanPencairan({
    required this.kode,
    required this.nominal,
    required this.rekening,
    required this.diajukanPada,
    this.status = 'Menunggu',
  });
}

/// Sumber tunggal data tiruan untuk sisi teknisi: status online, tawaran
/// pesanan, pekerjaan berjalan, pendapatan, riwayat, dan pencairan.
///
/// Halaman cukup memanggil kelas ini, supaya nanti cukup mengganti isinya
/// dengan panggilan API.
// TODO(backend): ganti dengan API + notifikasi FCM untuk tawaran dan
// Laravel Reverb untuk status persetujuan biaya.
class TeknisiService {
  TeknisiService._();

  static final TeknisiService instance = TeknisiService._();

  /// Potongan platform (%) dari total yang dibayar pelanggan.
  static const int persentasePlatform = 10;

  /// Minimum pencairan saldo (Rp).
  static const int minimumPencairan = 50000;

  /// Rekening tujuan pencairan dari data registrasi (tiruan).
  static const String rekeningTujuan = 'BNI • 1234567890 a.n Teknisi Contoh';

  /// Lama tawaran menunggu jawaban sebelum diteruskan ke teknisi lain.
  Duration batasTawaran = const Duration(seconds: 30);

  /// Jeda tiruan sebelum tawaran berikutnya datang.
  Duration jedaTawaran = const Duration(seconds: 3);

  /// Jeda tiruan sebelum pelanggan menyetujui biaya perbaikan.
  Duration jedaPersetujuan = const Duration(seconds: 3);

  final ValueNotifier<bool> online = ValueNotifier(false);
  final ValueNotifier<TawaranPesanan?> tawaran = ValueNotifier(null);
  final ValueNotifier<PekerjaanTeknisi?> pekerjaan = ValueNotifier(null);
  final ValueNotifier<List<RiwayatLayanan>> riwayat = ValueNotifier(
    _riwayatAwal,
  );
  final ValueNotifier<List<PengajuanPencairan>> pencairan = ValueNotifier(
    const [],
  );

  /// Batas waktu kartu tawaran yang sedang tampil. Sama dengan
  /// [batasTawaran], kecuali tawaran dipulihkan lewat [batalkanTolak].
  Duration batasAktif = const Duration(seconds: 30);

  /// Tawaran yang baru ditolak beserta sisa waktunya, untuk "Batalkan".
  ({TawaranPesanan tawaran, int sisaDetik})? _baruDitolak;

  Timer? _timerTawaran;
  Timer? _timerPersetujuan;
  int _urutanTawaran = 0;

  static int hitungKomisi(int totalDibayar) =>
      totalDibayar - (totalDibayar * persentasePlatform / 100).round();

  /// Pendapatan bersih hari ini.
  int get pendapatanHariIni => _hariIni.fold(0, (a, r) => a + r.diterima);

  Iterable<RiwayatLayanan> get _hariIni {
    final now = DateTime.now();
    return riwayat.value.where(
      (r) =>
          r.selesaiPada.year == now.year &&
          r.selesaiPada.month == now.month &&
          r.selesaiPada.day == now.day,
    );
  }

  /// Saldo yang bisa dicairkan: total pendapatan dikurangi pencairan yang
  /// sudah diajukan.
  int get saldo =>
      riwayat.value.fold(0, (a, r) => a + r.diterima) -
      pencairan.value.fold(0, (a, p) => a + p.nominal);

  /// Ubah status ketersediaan. Gagal (mengembalikan `false`) bila teknisi
  /// ingin offline saat masih menangani pesanan (UC-19).
  bool aturOnline(bool nilai) {
    if (!nilai && pekerjaan.value != null) return false;
    online.value = nilai;
    if (nilai) {
      _jadwalkanTawaran();
    } else {
      _timerTawaran?.cancel();
      tawaran.value = null;
    }
    return true;
  }

  void _jadwalkanTawaran() {
    _timerTawaran?.cancel();
    if (!online.value || pekerjaan.value != null || tawaran.value != null) {
      return;
    }
    _timerTawaran = Timer(jedaTawaran, () {
      if (!online.value || pekerjaan.value != null) return;
      _baruDitolak = null;
      batasAktif = batasTawaran;
      tawaran.value = _contohTawaran[_urutanTawaran % _contohTawaran.length];
      _urutanTawaran++;
    });
  }

  void terimaTawaran() {
    final t = tawaran.value;
    if (t == null) return;
    tawaran.value = null;
    pekerjaan.value = PekerjaanTeknisi(
      pesanan: t,
      waktu: {TahapPekerjaan.menuju: DateTime.now()},
    );
  }

  /// Menolak tawaran atau membiarkannya lewat batas waktu; tawaran
  /// diteruskan ke teknisi lain dan teknisi ini menunggu tawaran berikutnya.
  /// Tolak tawaran. Bila [sisaDetik] diisi (ditolak manual, bukan karena
  /// waktu habis), tawaran masih bisa dipulihkan lewat [batalkanTolak]
  /// selama belum ada tawaran baru.
  void tolakTawaran({int? sisaDetik}) {
    final t = tawaran.value;
    _baruDitolak = (t != null && sisaDetik != null && sisaDetik > 0)
        ? (tawaran: t, sisaDetik: sisaDetik)
        : null;
    tawaran.value = null;
    _jadwalkanTawaran();
  }

  /// Pulihkan tawaran yang baru ditolak; `false` bila sudah tidak bisa.
  bool batalkanTolak() {
    final d = _baruDitolak;
    _baruDitolak = null;
    if (d == null || tawaran.value != null || pekerjaan.value != null) {
      return false;
    }
    if (!online.value) return false;
    _timerTawaran?.cancel();
    batasAktif = Duration(seconds: d.sisaDetik);
    tawaran.value = d.tawaran;
    return true;
  }

  /// Menuju -> Tiba -> Pengecekan.
  void lanjutTahap() {
    final p = pekerjaan.value;
    if (p == null) return;
    final berikutnya = switch (p.tahap) {
      TahapPekerjaan.menuju => TahapPekerjaan.tiba,
      TahapPekerjaan.tiba => TahapPekerjaan.pengecekan,
      _ => null,
    };
    if (berikutnya == null) return;
    pekerjaan.value = p.copyWith(
      tahap: berikutnya,
      waktu: {...p.waktu, berikutnya: DateTime.now()},
    );
  }

  void tambahFotoPemeriksaan(String nama) {
    final p = pekerjaan.value;
    if (p == null) return;
    pekerjaan.value = p.copyWith(fotoPemeriksaan: [...p.fotoPemeriksaan, nama]);
  }

  /// Kirim rincian biaya perbaikan ke pelanggan (UC-22).
  void ajukanBiaya(List<ItemBiaya> item, String catatan) {
    final p = pekerjaan.value;
    if (p == null) return;
    pekerjaan.value = p.copyWith(
      itemBiaya: item,
      catatanBiaya: catatan,
      statusBiaya: StatusBiaya.menunggu,
    );
    // Tiruan: pelanggan menyetujui setelah beberapa detik.
    _timerPersetujuan?.cancel();
    _timerPersetujuan = Timer(jedaPersetujuan, () {
      final sekarang = pekerjaan.value;
      if (sekarang == null || sekarang.statusBiaya != StatusBiaya.menunggu) {
        return;
      }
      pekerjaan.value = sekarang.copyWith(
        statusBiaya: StatusBiaya.disetujui,
        tahap: TahapPekerjaan.perbaikan,
        waktu: {...sekarang.waktu, TahapPekerjaan.perbaikan: DateTime.now()},
      );
    });
  }

  /// Pengecekan selesai tanpa biaya tambahan: langsung dikerjakan.
  void lanjutTanpaBiayaTambahan() {
    final p = pekerjaan.value;
    if (p == null) return;
    pekerjaan.value = p.copyWith(
      tahap: TahapPekerjaan.perbaikan,
      waktu: {...p.waktu, TahapPekerjaan.perbaikan: DateTime.now()},
    );
  }

  /// Selesaikan pesanan setelah bukti kerja diunggah. Komisi teknisi
  /// tercatat sebagai pendapatan. Mengembalikan komisi.
  int selesaikan({required String catatan, required List<String> foto}) {
    final p = pekerjaan.value;
    if (p == null) return 0;
    final komisi = hitungKomisi(p.totalTagihan);
    riwayat.value = [
      RiwayatLayanan(
        kode: p.pesanan.kode,
        layanan: p.pesanan.layanan,
        namaPelanggan: p.pesanan.namaPelanggan,
        wilayah: p.pesanan.wilayah,
        selesaiPada: DateTime.now(),
        diterima: komisi,
      ),
      ...riwayat.value,
    ];
    pekerjaan.value = null;
    _jadwalkanTawaran();
    return komisi;
  }

  /// Ajukan pencairan; mengembalikan pesan galat atau `null` bila berhasil.
  String? ajukanPencairan(int nominal) {
    if (nominal < minimumPencairan) {
      return 'Minimal pencairan Rp50.000';
    }
    if (nominal > saldo) return 'Nominal melebihi saldo';
    pencairan.value = [
      PengajuanPencairan(
        kode: 'WD-${DateTime.now().millisecondsSinceEpoch % 100000}',
        nominal: nominal,
        rekening: rekeningTujuan,
        diajukanPada: DateTime.now(),
      ),
      ...pencairan.value,
    ];
    return null;
  }

  /// Kembalikan ke kondisi awal (dipakai test dan saat keluar akun).
  void reset() {
    _timerTawaran?.cancel();
    _timerPersetujuan?.cancel();
    batasTawaran = const Duration(seconds: 30);
    batasAktif = batasTawaran;
    _baruDitolak = null;
    jedaTawaran = const Duration(seconds: 3);
    jedaPersetujuan = const Duration(seconds: 3);
    online.value = false;
    tawaran.value = null;
    pekerjaan.value = null;
    riwayat.value = _riwayatAwal;
    pencairan.value = const [];
    _urutanTawaran = 0;
  }

  static const _contohTawaran = [
    TawaranPesanan(
      kode: 'AC-000124',
      layanan: 'Service AC',
      unitAc: '1 Unit AC Split 1 PK • Daikin',
      ongkosAwal: 100000,
      bisaBiayaTambahan: true,
      namaPelanggan: 'Hendra Gunawan',
      ratingPelanggan: '4.9',
      teleponPelanggan: '081234500001',
      alamat: 'Jl. Engku Putri No. 12, Batam Centre',
      wilayah: 'Batam Centre',
      jarakKm: 2.1,
      menitTempuh: 7,
      catatan: 'AC kamar utama netes air dan tidak dingin.',
    ),
    TawaranPesanan(
      kode: 'AC-000125',
      layanan: 'Cuci AC',
      unitAc: '2 Unit AC Split 1 PK • Panasonic',
      ongkosAwal: 150000,
      bisaBiayaTambahan: false,
      namaPelanggan: 'Siti Rahayu',
      ratingPelanggan: '4.8',
      teleponPelanggan: '081234500002',
      alamat: 'Perumahan Batu Aji Blok C No. 5',
      wilayah: 'Batu Aji',
      jarakKm: 3.4,
      menitTempuh: 11,
      catatan: 'Sudah 6 bulan belum dicuci.',
    ),
  ];

  static final _riwayatAwal = [
    RiwayatLayanan(
      kode: 'AC-000101',
      layanan: 'Service AC',
      namaPelanggan: 'Budi Santoso',
      wilayah: 'Nagoya',
      selesaiPada: DateTime(2026, 11, 15, 14, 30),
      diterima: 180000,
      rating: 5,
    ),
    RiwayatLayanan(
      kode: 'AC-000097',
      layanan: 'Cuci AC',
      namaPelanggan: 'Rina Melati',
      wilayah: 'Batam Centre',
      selesaiPada: DateTime(2026, 11, 13, 10, 0),
      diterima: 67500,
    ),
  ];
}
