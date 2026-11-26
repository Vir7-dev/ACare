import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/layanan.dart';
import '../models/pesanan.dart';
import '../models/status_layanan.dart';
import '../models/tagihan.dart';
import '../models/tagihan_online.dart';
import '../models/teknisi.dart';
import 'api_client.dart';
import 'layanan_service.dart';

/// Status ringkas pesanan pelanggan.
enum StatusPesananPelanggan {
  mencariTeknisi('Mencari Teknisi'),
  teknisiDitemukan('Menuju Lokasi'),
  dikerjakan('Sedang Dikerjakan'),
  selesai('Selesai'),
  dibatalkan('Dibatalkan');

  final String label;
  const StatusPesananPelanggan(this.label);

  /// Dari status pesanan di server (9 status) ke status ringkas.
  static StatusPesananPelanggan dariServer(String? s) => switch (s) {
    'mencari_teknisi' => mencariTeknisi,
    'menuju_lokasi' || 'tiba' => teknisiDitemukan,
    'selesai' => selesai,
    'dibatalkan' => dibatalkan,
    _ => dikerjakan,
  };
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

/// Data pesanan pelanggan: draf dari form, atau pesanan dari server
/// (`id` terisi) yang disimpan di [OrderService.pesananAktif].
class PesananPelanggan {
  /// Id pesanan di server; `null` selama masih draf di form.
  final int? id;
  final String? kode;

  /// Id alamat tersimpan (tabel `lokasi`) yang dipakai pesanan.
  final int? idLokasi;

  /// Id tagihan biaya awal di server.
  final int? idPembayaranAwal;

  /// Status lengkap dari server, misal `pengecekan_awal`.
  final String? statusServer;

  final Layanan layanan;
  final int jumlahUnit;
  final JenisAc jenisAc;
  final double pk;
  final String? merek;
  final String alamat;
  final String detailAlamat;
  final DateTime jadwal;
  final String? catatan;

  /// Isian khusus layanan (dikirim ke kolom pesanan.detail_layanan):
  /// keluhan (Service AC), jenis_freon (Isi Freon), jenis_pekerjaan
  /// (Bongkar Pasang). [catatan] hanya berisi catatan bebas pelanggan.
  final Map<String, Object> detailLayanan;
  final String metodeBayar;
  final int biayaAwal;
  final StatusPesananPelanggan status;
  final String? namaTeknisi;
  final String? plat;
  final String? kendaraan;
  final String? teleponTeknisi;
  final String? deskripsiTeknisi;
  final String? rating;
  final int? jumlahUlasan;
  final Duration? estimasiTiba;

  /// Item biaya perbaikan dari teknisi (jasa/suku cadang).
  final List<KomponenTagihan> biayaPerbaikan;

  /// `menunggu`, `disetujui`, `ditolak`, atau null (belum diajukan).
  final String? statusBiaya;
  final String catatanBiaya;

  /// Tagihan pelunasan biaya perbaikan (bila ada).
  final int? idPembayaranPelunasan;
  final String? statusPelunasan;
  final int jumlahPelunasan;

  /// Waktu tiap tahap dari server: `pengecekan`, `dikerjakan`,
  /// `menunggu_pembayaran`, `selesai`, dst.
  final Map<String, DateTime> waktu;

  const PesananPelanggan({
    this.id,
    this.kode,
    this.idLokasi,
    this.idPembayaranAwal,
    this.statusServer,
    required this.layanan,
    required this.jumlahUnit,
    required this.jenisAc,
    required this.pk,
    this.merek,
    required this.alamat,
    required this.detailAlamat,
    required this.jadwal,
    this.catatan,
    this.detailLayanan = const {},
    required this.metodeBayar,
    required this.biayaAwal,
    this.status = StatusPesananPelanggan.mencariTeknisi,
    this.namaTeknisi,
    this.plat,
    this.kendaraan,
    this.teleponTeknisi,
    this.deskripsiTeknisi,
    this.rating,
    this.jumlahUlasan,
    this.estimasiTiba,
    this.biayaPerbaikan = const [],
    this.statusBiaya,
    this.catatanBiaya = '',
    this.idPembayaranPelunasan,
    this.statusPelunasan,
    this.jumlahPelunasan = 0,
    this.waktu = const {},
  });

  /// Dari `PesananResource` di backend.
  factory PesananPelanggan.dariJson(Map<String, dynamic> j) {
    final layananJson = j['layanan'] as Map<String, dynamic>?;
    final nama = layananJson?['nama'] as String? ?? '';
    final layanan =
        daftarLayanan.where((l) => l.nama == nama).firstOrNull ??
        Layanan.dariJson({'nama': nama, 'harga': layananJson?['harga']});
    final pembayaran = (j['pembayaran'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final awal = pembayaran.where((p) => p['jenis'] == 'awal').firstOrNull;
    final pelunasan = pembayaran
        .where((p) => p['jenis'] == 'pelunasan')
        .lastOrNull;
    final biaya = j['biaya'] as Map<String, dynamic>? ?? const {};
    final rincian = (biaya['rincian'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final waktuJson = j['waktu'] as Map<String, dynamic>? ?? const {};
    final alamat = j['alamat'] as Map<String, dynamic>?;
    final teknisi = j['teknisi'] as Map<String, dynamic>?;
    final detail = j['detail_layanan'];
    return PesananPelanggan(
      id: j['id'] as int?,
      kode: j['kode'] as String?,
      idLokasi: alamat?['id'] as int?,
      idPembayaranAwal: awal?['id'] as int?,
      statusServer: j['status'] as String?,
      layanan: layanan,
      jumlahUnit: (j['jumlah_unit'] as num?)?.toInt() ?? 1,
      jenisAc:
          JenisAc.values.where((e) => e.name == j['jenis_ac']).firstOrNull ??
          JenisAc.split,
      pk: (j['pk'] as num?)?.toDouble() ?? 1,
      merek: j['merek'] as String?,
      alamat: alamat?['alamat_lengkap'] as String? ?? '',
      detailAlamat: j['detail_lokasi'] as String? ?? '',
      jadwal:
          DateTime.tryParse(j['jadwal_service'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      catatan: j['catatan'] as String?,
      detailLayanan: detail is Map
          ? detail.map((k, v) => MapEntry('$k', v as Object))
          : const {},
      metodeBayar: awal?['metode'] as String? ?? '',
      biayaAwal: (awal?['jumlah'] as num?)?.toInt() ?? 0,
      status: StatusPesananPelanggan.dariServer(j['status'] as String?),
      namaTeknisi: teknisi?['nama'] as String?,
      plat: teknisi?['plat_nomor'] as String?,
      kendaraan: teknisi?['jenis_kendaraan'] as String?,
      teleponTeknisi: teknisi?['no_telepon'] as String?,
      deskripsiTeknisi: teknisi?['deskripsi'] as String?,
      biayaPerbaikan: [
        for (final r in rincian)
          if (r['jenis'] != 'layanan')
            KomponenTagihan(
              r['nama'] as String? ?? '',
              (r['subtotal'] as num?)?.toInt() ?? 0,
            ),
      ],
      statusBiaya: biaya['status_biaya'] as String?,
      catatanBiaya: biaya['catatan_teknisi'] as String? ?? '',
      idPembayaranPelunasan: pelunasan?['id'] as int?,
      statusPelunasan: pelunasan?['status'] as String?,
      jumlahPelunasan: (pelunasan?['jumlah'] as num?)?.toInt() ?? 0,
      waktu: {
        for (final e in waktuJson.entries)
          if (e.value is String && DateTime.tryParse(e.value as String) != null)
            e.key: DateTime.parse(e.value as String).toLocal(),
      },
    );
  }

  /// Tagihan untuk halaman detail & pelunasan.
  Tagihan get tagihan => Tagihan(
    pemeriksaan: biayaAwal,
    komponen: biayaPerbaikan,
    catatanTeknisi: catatanBiaya,
  );

  bool get biayaDitolak => statusBiaya == 'ditolak';

  /// Tahap pada garis waktu detail pesanan.
  StatusLayanan get statusLayanan => switch (statusServer) {
    'menunggu_persetujuan_biaya' => StatusLayanan.menungguPersetujuanBiaya,
    'dikerjakan' => StatusLayanan.melakukanPerbaikan,
    'menunggu_pembayaran' => StatusLayanan.menungguPembayaran,
    'selesai' => StatusLayanan.selesai,
    _ => StatusLayanan.pengecekanAwal,
  };

  /// Teknisi masih di perjalanan (halaman tracking).
  bool get teknisiDiPerjalanan =>
      statusServer == 'menuju_lokasi' || statusServer == 'tiba';

  /// Biaya awal sudah dibayar (pencarian teknisi sudah berjalan).
  bool get sudahDibayar => metodeBayar.isNotEmpty;

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
      // TODO(ulasan): rating dari tabel rating_ulasan.
      rating: rating ?? '-',
      jumlahUlasan: jumlahUlasan ?? 0,
      kendaraan: kendaraan ?? '-',
      plat: plat ?? '-',
      telepon: teleponTeknisi ?? '',
      testimoni: deskripsiTeknisi ?? '',
    );
  }

  /// Salinan dengan sebagian data diganti.
  PesananPelanggan copyWith({
    StatusPesananPelanggan? status,
    String? namaTeknisi,
    String? plat,
    String? rating,
    int? jumlahUlasan,
    Duration? estimasiTiba,
    String? metodeBayar,
    int? idLokasi,
  }) {
    return PesananPelanggan(
      id: id,
      kode: kode,
      idLokasi: idLokasi ?? this.idLokasi,
      idPembayaranAwal: idPembayaranAwal,
      statusServer: statusServer,
      layanan: layanan,
      jumlahUnit: jumlahUnit,
      jenisAc: jenisAc,
      pk: pk,
      merek: merek,
      alamat: alamat,
      detailAlamat: detailAlamat,
      jadwal: jadwal,
      catatan: catatan,
      detailLayanan: detailLayanan,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      biayaAwal: biayaAwal,
      status: status ?? this.status,
      namaTeknisi: namaTeknisi ?? this.namaTeknisi,
      plat: plat ?? this.plat,
      kendaraan: kendaraan,
      teleponTeknisi: teleponTeknisi,
      deskripsiTeknisi: deskripsiTeknisi,
      rating: rating ?? this.rating,
      jumlahUlasan: jumlahUlasan ?? this.jumlahUlasan,
      estimasiTiba: estimasiTiba ?? this.estimasiTiba,
      biayaPerbaikan: biayaPerbaikan,
      statusBiaya: statusBiaya,
      catatanBiaya: catatanBiaya,
      idPembayaranPelunasan: idPembayaranPelunasan,
      statusPelunasan: statusPelunasan,
      jumlahPelunasan: jumlahPelunasan,
      waktu: waktu,
    );
  }
}

/// Label PK yang rapi: `0.5`, `1`, `1.5`, `2`.
String _pkLabel(double pk) =>
    pk == pk.roundToDouble() ? pk.toStringAsFixed(0) : pk.toString();

/// Pesanan pelanggan lewat API `/api/pesanan`.
///
/// Harga layanan TIDAK disimpan di sini: semuanya dibaca dari katalog
/// ([daftarLayanan]) dan dihitung ulang server saat pesanan dibuat.
class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  /// Biaya layanan yang belum termasuk komponen, jadi diagnosis teknisi bisa
  /// menambah tagihan. Cek AC: setelah pemeriksaan teknisi boleh
  /// mengajukan biaya perbaikan sesuai masalah yang ditemukan.
  static const Set<String> layananBerbiayaTambahan = {'Service AC', 'Cek AC'};

  /// Selang pemeriksaan status saat menunggu teknisi.
  // TODO(fcm): ganti dengan notifikasi; pemeriksaan berkala jadi cadangan.
  static Duration selangPeriksa = const Duration(seconds: 3);

  /// Pesanan yang sedang berjalan. `null` berarti pelanggan belum punya
  /// pesanan aktif, sehingga section "Sedang Berlangsung" disembunyikan.
  final ValueNotifier<PesananPelanggan?> pesananAktif =
      ValueNotifier<PesananPelanggan?>(null);

  /// Pesanan terakhir yang selesai (kartu "Servis Terakhir" di beranda).
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

  /// Perkiraan biaya awal untuk ditampilkan: harga layanan x jumlah unit.
  /// Jumlah yang ditagih tetap dihitung server.
  static int hitungBiayaAwal(Layanan layanan, int jumlahUnit) =>
      layanan.harga * jumlahUnit;

  /// Dinaikkan setiap pencarian dihentikan, supaya pemeriksaan lama berhenti.
  int _tokenPencarian = 0;

  /// Muat pesanan aktif dan servis terakhir dari server (beranda).
  Future<void> muatAktif() async {
    if (await ApiClient.token() == null) return;
    try {
      final aktif = await ApiClient.get('/pesanan?status=aktif');
      final daftar = (aktif['data'] as List? ?? const []);
      pesananAktif.value = daftar.isEmpty
          ? null
          : PesananPelanggan.dariJson(daftar.first as Map<String, dynamic>);
      final selesai = await ApiClient.get('/pesanan?status=selesai');
      final s = (selesai['data'] as List? ?? const []);
      servisTerakhir.value = s.isEmpty
          ? null
          : PesananPelanggan.dariJson(s.first as Map<String, dynamic>);
    } on ApiException {
      // Tetap tampilkan data terakhir.
    }
  }

  /// Riwayat pesanan selesai dan dibatalkan, terbaru dulu. Melempar
  /// [ApiException] bila gagal.
  Future<List<Pesanan>> muatRiwayat() async {
    final res = await ApiClient.get('/pesanan');
    return [
      for (final j in (res['data'] as List? ?? const []))
        if (['selesai', 'dibatalkan'].contains((j as Map)['status']))
          Pesanan.dariJson(j as Map<String, dynamic>),
    ];
  }

  /// Ambil pesanan terbaru dari server dan perbarui [pesananAktif].
  Future<PesananPelanggan> muatUlang(int id) async {
    final res = await ApiClient.get('/pesanan/$id');
    final p = PesananPelanggan.dariJson(res['data'] as Map<String, dynamic>);
    _simpanAktif(p);
    return p;
  }

  /// Buat pesanan di server dari draf form. Melempar [ApiException] bila
  /// ditolak (misal masih ada pesanan aktif, atau data tidak valid).
  Future<PesananPelanggan> buat(PesananPelanggan draf) async {
    var idLayanan = draf.layanan.id;
    if (idLayanan == null) {
      // Katalog bawaan belum diganti data server: muat dulu.
      await LayananService.instance.muat();
      idLayanan = daftarLayanan
          .where((l) => l.nama == draf.layanan.nama)
          .firstOrNull
          ?.id;
    }
    if (idLayanan == null || draf.idLokasi == null) {
      throw const ApiException(
        status: 0,
        pesan: 'Data layanan atau alamat belum termuat. Periksa koneksi lalu coba lagi.',
      );
    }
    final res = await ApiClient.post('/pesanan', {
      'id_layanan': idLayanan,
      'jumlah_unit': draf.jumlahUnit,
      'jenis_ac': draf.jenisAc.name,
      'pk': draf.pk,
      'merek': ?draf.merek,
      'id_lokasi': draf.idLokasi,
      'detail_lokasi': draf.detailAlamat,
      'jadwal_service': draf.jadwal.toUtc().toIso8601String(),
      'catatan': ?draf.catatan,
      'detail_layanan': draf.detailLayanan,
    });
    return PesananPelanggan.dariJson(res['data'] as Map<String, dynamic>);
  }

  /// Buat tagihan Xendit untuk pembayaran [idPembayaran] dengan metode
  /// [channel] (misal `QRIS`). Kode QR / nomor VA / tautan e-wallet ada di
  /// `instruksi`. Melempar [ApiException] bila gagal.
  Future<(PesananPelanggan, StatusTagihan)> bayarTagihan(
    int idPesanan,
    int idPembayaran,
    String channel,
  ) => _tagihan(
    ApiClient.post('/pesanan/$idPesanan/pembayaran/$idPembayaran/bayar', {
      'metode': channel,
    }),
    idPembayaran,
  );

  /// Status terbaru tagihan. Server ikut menanyakan ke Xendit bila webhook
  /// belum datang.
  Future<(PesananPelanggan, StatusTagihan)> periksaTagihan(
    int idPesanan,
    int idPembayaran,
  ) => _tagihan(ApiClient.get('/pesanan/$idPesanan'), idPembayaran);

  /// Mode pengembangan: minta server/Xendit menganggap tagihan dibayar.
  Future<(PesananPelanggan, StatusTagihan)> simulasiBayar(
    int idPesanan,
    int idPembayaran,
  ) => _tagihan(
    ApiClient.post(
      '/pesanan/$idPesanan/pembayaran/$idPembayaran/simulasi-lunas',
    ),
    idPembayaran,
  );

  Future<(PesananPelanggan, StatusTagihan)> _tagihan(
    Future<Map<String, dynamic>> permintaan,
    int idPembayaran,
  ) async {
    final data = (await permintaan)['data'] as Map<String, dynamic>;
    final p = PesananPelanggan.dariJson(data);
    _simpanAktif(p);
    return (p, StatusTagihan.dariPesanan(data, idPembayaran));
  }

  /// Tunggu sampai teknisi menerima pesanan [p]: status diperiksa ke server
  /// setiap [selangPeriksa]. Mengembalikan `false` bila pesanan batal (oleh
  /// pelanggan atau karena tidak ada teknisi) atau pencarian dihentikan.
  Future<bool> cariTeknisi(PesananPelanggan p) async {
    final token = ++_tokenPencarian;
    _simpanAktif(p);
    while (token == _tokenPencarian) {
      try {
        final terbaru = await muatUlang(p.id!);
        if (terbaru.status == StatusPesananPelanggan.dibatalkan) {
          pesananAktif.value = null;
          return false;
        }
        if (terbaru.teknisiSudahDitemukan) return true;
      } on ApiException {
        // Koneksi putus sesaat: coba lagi di putaran berikutnya.
      }
      if (token != _tokenPencarian) break;
      await _tunggu();
    }
    return false;
  }

  Timer? _timerTunggu;
  Completer<void>? _jeda;

  /// Jeda antar pemeriksaan yang bisa dihentikan seketika.
  Future<void> _tunggu() {
    final c = _jeda = Completer<void>();
    _timerTunggu = Timer(selangPeriksa, () {
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  void _hentikanJeda() {
    _tokenPencarian++;
    _timerTunggu?.cancel();
    final c = _jeda;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Hentikan pemeriksaan tanpa membatalkan pesanan (halaman ditutup).
  void hentikanPencarian() => _hentikanJeda();

  /// Batalkan pesanan aktif di server. Mengembalikan pesan galat atau
  /// `null` bila berhasil.
  Future<String?> batalkan({String? alasan}) async {
    _hentikanJeda();
    final p = pesananAktif.value;
    if (p?.id == null) {
      pesananAktif.value = null;
      return null;
    }
    try {
      await ApiClient.post('/pesanan/${p!.id}/batal', {'alasan': ?alasan});
    } on ApiException catch (e) {
      return e.pesan;
    }
    pesananAktif.value = null;
    return null;
  }

  /// Pelanggan menyetujui atau menolak rincian biaya perbaikan. Melempar
  /// [ApiException] bila ditolak server (misal waktu persetujuan habis).
  Future<PesananPelanggan> tanggapiBiaya(
    PesananPelanggan p, {
    required bool setuju,
  }) async {
    final res = await ApiClient.post('/pesanan/${p.id}/biaya', {
      'setuju': setuju,
    });
    final hasil = PesananPelanggan.dariJson(
      res['data'] as Map<String, dynamic>,
    );
    _simpanAktif(hasil);
    return hasil;
  }

  /// Pesanan aktif selesai: pindahkan ke servis terakhir.
  void selesaikan() {
    final p = pesananAktif.value;
    if (p == null) return;
    servisTerakhir.value = p.copyWith(status: StatusPesananPelanggan.selesai);
    pesananAktif.value = null;
  }

  void _simpanAktif(PesananPelanggan p) {
    if (p.status == StatusPesananPelanggan.selesai) {
      servisTerakhir.value = p;
      pesananAktif.value = null;
    } else if (p.status == StatusPesananPelanggan.dibatalkan) {
      pesananAktif.value = null;
    } else {
      pesananAktif.value = p;
    }
  }

  /// Kembalikan service ke kondisi awal (dipakai unit test dan saat keluar).
  void reset() {
    _hentikanJeda();
    pesananAktif.value = null;
    servisTerakhir.value = null;
  }
}
