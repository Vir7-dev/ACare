import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/layanan.dart';
import '../models/teknisi.dart';

/// Status ringkas pesanan pelanggan.
enum StatusPesananPelanggan {
  mencariTeknisi('Mencari Teknisi'),
  teknisiDitemukan('Menuju Lokasi'),
  dikerjakan('Sedang Dikerjakan'),
  selesai('Selesai'),
  dibatalkan('Dibatalkan');

  final String label;
  const StatusPesananPelanggan(this.label);
}

/// Jenis AC yang bisa dipilih pelanggan.
enum JenisAc {
  split('Split'),
  cassette('Cassette'),
  standing('Standing'),
  window('Window');

  final String label;
  const JenisAc(this.label);
}

/// Pilihan jenis pekerjaan untuk layanan Bongkar Pasang.
enum JenisBongkarPasang {
  pasangBaru('Pasang Baru'),
  pindah('Pindah'),
  bongkar('Bongkar');

  final String label;
  const JenisBongkarPasang(this.label);
}

/// Data pesanan pelanggan. Dipakai untuk menyimpan pesanan yang sedang
/// berjalan di [OrderService.pesananAktif].
class PesananPelanggan {
  final Layanan layanan;
  final int jumlahUnit;
  final JenisAc jenisAc;
  final double pk;
  final String? merek;
  final String alamat;
  final String detailAlamat;
  final DateTime jadwal;
  final String? catatan;
  final String metodeBayar;
  final int totalEstimasi;
  final StatusPesananPelanggan status;
  final String? namaTeknisi;
  final String? plat;
  final String? rating;
  final int? jumlahUlasan;
  final Duration? estimasiTiba;

  const PesananPelanggan({
    required this.layanan,
    required this.jumlahUnit,
    required this.jenisAc,
    required this.pk,
    this.merek,
    required this.alamat,
    required this.detailAlamat,
    required this.jadwal,
    this.catatan,
    required this.metodeBayar,
    required this.totalEstimasi,
    this.status = StatusPesananPelanggan.mencariTeknisi,
    this.namaTeknisi,
    this.plat,
    this.rating,
    this.jumlahUlasan,
    this.estimasiTiba,
  });

  bool get teknisiSudahDitemukan =>
      namaTeknisi != null && namaTeknisi!.trim().isNotEmpty;

  bool get aktif =>
      teknisiSudahDitemukan &&
      status != StatusPesananPelanggan.selesai &&
      status != StatusPesananPelanggan.dibatalkan;

  String get ringkasanUnit =>
      '$jumlahUnit Unit AC ${jenisAc.label} ${_pkLabel(pk)} PK'
      '${merek == null || merek!.trim().isEmpty ? '' : ' • $merek'}';

  String get alamatLengkap =>
      detailAlamat.trim().isEmpty ? alamat : '$detailAlamat, $alamat';

  /// Data teknisi untuk halaman tracking/chat. `null` kalau belum ditemukan.
  Teknisi? get teknisi {
    if (!teknisiSudahDitemukan) return null;
    return Teknisi(
      nama: namaTeknisi!,
      rating: rating ?? '-',
      jumlahUlasan: jumlahUlasan ?? 0,
      kendaraan: layanan.nama,
      plat: plat ?? '-',
      telepon: _teleponTeknisi,
      testimoni: 'Teknisi yang hebat mantep pokoknya',
    );
  }

  /// Nomor telepon teknisi (dummy untuk sementara).
  // TODO(backend): ambil nomor teknisi dari API.
  static const String _teleponTeknisi = '081234567890';

  /// Salinan dengan sebagian data diganti.
  PesananPelanggan copyWith({
    StatusPesananPelanggan? status,
    String? namaTeknisi,
    String? plat,
    String? rating,
    int? jumlahUlasan,
    Duration? estimasiTiba,
    String? metodeBayar,
  }) {
    return PesananPelanggan(
      layanan: layanan,
      jumlahUnit: jumlahUnit,
      jenisAc: jenisAc,
      pk: pk,
      merek: merek,
      alamat: alamat,
      detailAlamat: detailAlamat,
      jadwal: jadwal,
      catatan: catatan,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      totalEstimasi: totalEstimasi,
      status: status ?? this.status,
      namaTeknisi: namaTeknisi ?? this.namaTeknisi,
      plat: plat ?? this.plat,
      rating: rating ?? this.rating,
      jumlahUlasan: jumlahUlasan ?? this.jumlahUlasan,
      estimasiTiba: estimasiTiba ?? this.estimasiTiba,
    );
  }
}

/// Label PK yang rapi: `0.5`, `1`, `1.5`, `2`.
String _pkLabel(double pk) =>
    pk == pk.roundToDouble() ? pk.toStringAsFixed(0) : pk.toString();

/// Sumber tunggal mock data pesanan pelanggan.
///
/// Harga layanan TIDAK disimpan di sini: semuanya dibaca dari
/// [daftarLayanan] (lihat [layananDenganNama] dan [hitungTotalEstimasi])
/// supaya tidak ada angka yang di-hardcode di halaman.
class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  /// Biaya aplikasi tetap (mock). // TODO(backend): ambil dari konfigurasi API.
  static const int biayaAplikasi = 5000;

  /// Biaya layanan yang belum termasuk komponen, jadi diagnosis teknisi bisa
  /// menambah tagihan (Service AC & Cek AC).
  static const Set<String> layananBerbiayaTambahan = {'Service AC', 'Cek AC'};

  /// Pesanan yang sedang berjalan. `null` berarti pelanggan belum punya
  /// pesanan aktif, sehingga section "Sedang Berlangsung" disembunyikan.
  final ValueNotifier<PesananPelanggan?> pesananAktif =
      ValueNotifier<PesananPelanggan?>(null);

  /// Riwayat servis terakhir pelanggan (mock, kosong = belum pernah servis).
  // TODO(backend): ambil riwayat dari API pelanggan.
  final ValueNotifier<PesananPelanggan?> servisTerakhir =
      ValueNotifier<PesananPelanggan?>(null);

  /// Cari layanan dari [daftarLayanan] berdasarkan namanya. Melempar
  /// [ArgumentError] kalau nama layanan tidak dikenal.
  static Layanan layananDenganNama(String nama) {
    for (final l in daftarLayanan) {
      if (l.nama == nama) return l;
    }
    throw ArgumentError.value(nama, 'nama', 'Layanan tidak dikenal');
  }

  /// Total estimasi = harga layanan x jumlah unit + biaya aplikasi.
  static int hitungTotalEstimasi(Layanan layanan, int jumlahUnit) =>
      layanan.harga * jumlahUnit + biayaAplikasi;

  /// Biaya layanan (harga x unit) tanpa biaya aplikasi.
  static int hitungBiayaLayanan(Layanan layanan, int jumlahUnit) =>
      layanan.harga * jumlahUnit;

  /// Nomor pencarian yang sedang berjalan; dinaikkan tiap [batalkan] supaya
  /// hasil pencarian lama tidak menimpa pembatalan.
  int _tokenPencarian = 0;

  /// Timer pencarian yang aktif, dibatalkan oleh [batalkan].
  Timer? _timerPencarian;

  /// Hasil pencarian yang menunggu; diselesaikan `false` saat dibatalkan.
  Completer<bool>? _hasilPencarian;

  /// Mencari teknisi terdekat untuk [p]. Data teknisi masih dummy dan
  /// diselesaikan setelah [lamaCari] (default 5 detik).
  ///
  /// Mengembalikan `false` kalau pencarian dibatalkan (lewat [batalkan] atau
  /// karena pelanggan meninggalkan halaman pencarian).
  // TODO(backend): panggil API pencarian teknisi dan langganan statusnya.
  Future<bool> cariTeknisi(
    PesananPelanggan p, {
    Duration lamaCari = const Duration(seconds: 5),
  }) {
    _pastikanBelumAdaPesananAktif();

    final token = ++_tokenPencarian;
    _timerPencarian?.cancel();
    _selesaikanPencarian(false);

    final hasil = _hasilPencarian = Completer<bool>();
    // Ditunda ke akhir frame: cariTeknisi sering dipanggil dari initState,
    // dan memberi tahu ValueNotifier saat frame sedang dibangun akan memicu
    // "setState() called during build" pada listener (mis. beranda).
    _tundaSetelahFrame(() {
      if (token == _tokenPencarian) pesananAktif.value = p;
    });

    _timerPencarian = Timer(lamaCari, () {
      _timerPencarian = null;
      // Pesanan dibatalkan selama proses pencarian: jangan timpa.
      if (token != _tokenPencarian || pesananAktif.value == null) {
        if (!hasil.isCompleted) hasil.complete(false);
        return;
      }

      final menit = 10 + Random().nextInt(11);
      pesananAktif.value = p.copyWith(
        status: StatusPesananPelanggan.teknisiDitemukan,
        namaTeknisi: 'GanAnWo',
        plat: 'BP 4892 QL',
        rating: '4.9',
        jumlahUlasan: 67,
        estimasiTiba: Duration(minutes: menit),
      );
      if (!hasil.isCompleted) hasil.complete(true);
    });
    return hasil.future;
  }

  /// Tolak pesanan baru kalau masih ada pesanan aktif.
  // TODO(backend): validasi juga di sisi server.
  void _pastikanBelumAdaPesananAktif() {
    final aktif = pesananAktif.value;
    if (aktif != null && aktif.aktif) {
      throw StateError('Masih ada pesanan yang sedang berjalan.');
    }
  }

  /// Batalkan pencarian/pesanan yang sedang berjalan.
  // TODO(backend): panggil API pembatalan pesanan.
  void batalkan() {
    _tokenPencarian++;
    _timerPencarian?.cancel();
    _timerPencarian = null;
    _selesaikanPencarian(false);
    pesananAktif.value = null;
  }

  void _selesaikanPencarian(bool ditemukan) {
    final hasil = _hasilPencarian;
    if (hasil != null && !hasil.isCompleted) hasil.complete(ditemukan);
    _hasilPencarian = null;
  }

  /// Jalankan [aksi] setelah frame saat ini selesai dibangun.
  void _tundaSetelahFrame(VoidCallback aksi) {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => aksi());
    } else {
      aksi();
    }
  }

  /// Selesaikan pesanan aktif lalu simpan sebagai riwayat servis terakhir.
  // TODO(backend): kirim status selesai ke API dan tarik riwayat terbaru.
  void selesaikan() {
    final p = pesananAktif.value;
    if (p == null) return;
    servisTerakhir.value = p.copyWith(status: StatusPesananPelanggan.selesai);
    pesananAktif.value = null;
  }

  /// Kembalikan service ke kondisi awal (dipakai unit test).
  @visibleForTesting
  void reset() {
    _tokenPencarian++;
    _timerPencarian?.cancel();
    _timerPencarian = null;
    _selesaikanPencarian(false);
    pesananAktif.value = null;
    servisTerakhir.value = null;
  }
}
