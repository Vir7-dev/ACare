import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'perangkat.dart';

/// Tahap pekerjaan yang dijalankan teknisi untuk satu pesanan.
enum TahapPekerjaan {
  menuju('Menuju'),
  tiba('Tiba'),
  pengecekan('Pengecekan'),
  perbaikan('Perbaikan'),
  selesai('Selesai');

  final String label;
  const TahapPekerjaan(this.label);

  /// Dari status pesanan di server.
  static TahapPekerjaan dariServer(String? s) => switch (s) {
    'tiba' => tiba,
    'pengecekan_awal' || 'menunggu_persetujuan_biaya' => pengecekan,
    'dikerjakan' => perbaikan,
    'menunggu_pembayaran' || 'selesai' => selesai,
    _ => menuju,
  };
}

/// Status rincian biaya perbaikan yang diajukan ke pelanggan.
enum StatusBiaya {
  belumDiajukan,
  menunggu,
  disetujui,
  ditolak;

  static StatusBiaya dariServer(String? s) => switch (s) {
    'menunggu' => menunggu,
    'disetujui' => disetujui,
    'ditolak' => ditolak,
    _ => belumDiajukan,
  };
}

enum JenisItemBiaya {
  jasa('Jasa Perbaikan'),
  sukuCadang('Suku Cadang / Material');

  final String label;
  const JenisItemBiaya(this.label);

  /// Nilai `jenis` di API (`jasa` / `suku_cadang`).
  String get nilai => this == jasa ? 'jasa' : 'suku_cadang';
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
  /// Id pesanan di server.
  final int id;
  final String kode;
  final String layanan;
  final String unitAc;

  /// Biaya awal yang sudah dibayar pelanggan.
  final int ongkosAwal;

  /// Layanan yang bisa bertambah biaya setelah pengecekan.
  final bool bisaBiayaTambahan;
  final String namaPelanggan;

  /// Kosong selama masih tawaran; terlihat setelah diterima.
  final String teleponPelanggan;
  final String alamat;
  final String wilayah;
  final double jarakKm;
  final int menitTempuh;
  final String catatan;
  final double? latitude;
  final double? longitude;

  const TawaranPesanan({
    this.id = 0,
    required this.kode,
    required this.layanan,
    required this.unitAc,
    required this.ongkosAwal,
    required this.bisaBiayaTambahan,
    required this.namaPelanggan,
    required this.teleponPelanggan,
    required this.alamat,
    required this.wilayah,
    required this.jarakKm,
    required this.menitTempuh,
    required this.catatan,
    this.latitude,
    this.longitude,
  });

  /// Dari `PekerjaanTeknisiResource` di backend.
  factory TawaranPesanan.dariJson(Map<String, dynamic> j) {
    final pelanggan = j['pelanggan'] as Map<String, dynamic>? ?? const {};
    final alamat = j['alamat'] as Map<String, dynamic>? ?? const {};
    final detail = j['detail_layanan'];
    final keluhan = detail is Map && detail['keluhan'] is List
        ? (detail['keluhan'] as List).join(', ')
        : '';
    final catatan = [
      if (keluhan.isNotEmpty) 'Keluhan: $keluhan',
      if (detail is Map && detail['jenis_freon'] != null)
        'Freon ${detail['jenis_freon']}',
      if ((j['catatan'] as String?)?.trim().isNotEmpty ?? false)
        (j['catatan'] as String).trim(),
    ].join('. ');
    final pk = (j['pk'] as num?)?.toDouble();
    final merek = (j['merek'] as String?)?.trim();
    final jenis = (j['jenis_ac'] as String?) ?? '';
    return TawaranPesanan(
      id: j['id'] as int,
      kode: j['kode'] as String? ?? '',
      layanan: j['layanan'] as String? ?? '',
      unitAc:
          [
            '${j['jumlah_unit'] ?? 1} Unit AC',
            if (jenis.isNotEmpty)
              '${jenis[0].toUpperCase()}${jenis.substring(1)}',
            if (pk != null) '${pk == pk.roundToDouble() ? pk.toInt() : pk} PK',
          ].join(' ') +
          (merek == null || merek.isEmpty ? '' : ' • $merek'),
      ongkosAwal: (j['biaya_awal'] as num?)?.toInt() ?? 0,
      bisaBiayaTambahan: j['bisa_biaya_tambahan'] == true,
      namaPelanggan: pelanggan['nama'] as String? ?? '',
      teleponPelanggan: pelanggan['no_telepon'] as String? ?? '',
      alamat: alamat['alamat_lengkap'] as String? ?? '',
      wilayah: alamat['detail_lokasi'] as String? ?? '',
      jarakKm: (j['jarak_km'] as num?)?.toDouble() ?? 0,
      menitTempuh: (j['menit_tempuh'] as num?)?.toInt() ?? 0,
      catatan: catatan,
      latitude: (alamat['latitude'] as num?)?.toDouble(),
      longitude: (alamat['longitude'] as num?)?.toDouble(),
    );
  }
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

  /// Foto pemeriksaan unit yang sudah diunggah.
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

  /// Dari `PekerjaanTeknisiResource` di backend.
  factory PekerjaanTeknisi.dariJson(Map<String, dynamic> j) {
    final biaya = j['biaya'] as Map<String, dynamic>? ?? const {};
    final waktu = j['waktu'] as Map<String, dynamic>? ?? const {};
    DateTime? w(String k) =>
        DateTime.tryParse(waktu[k] as String? ?? '')?.toLocal();
    final foto = (j['foto'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((f) => f['tahap'] == 'pemeriksaan')
        .toList();
    return PekerjaanTeknisi(
      pesanan: TawaranPesanan.dariJson(j),
      tahap: TahapPekerjaan.dariServer(j['status'] as String?),
      statusBiaya: StatusBiaya.dariServer(biaya['status_biaya'] as String?),
      itemBiaya: [
        for (final r
            in (biaya['rincian'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          if (r['jenis'] != 'layanan')
            ItemBiaya(
              nama: r['nama'] as String? ?? '',
              jenis: r['jenis'] == 'jasa'
                  ? JenisItemBiaya.jasa
                  : JenisItemBiaya.sukuCadang,
              harga: (r['subtotal'] as num?)?.toInt() ?? 0,
            ),
      ],
      catatanBiaya: biaya['catatan'] as String? ?? '',
      waktu: {
        TahapPekerjaan.menuju: ?w('diterima'),
        TahapPekerjaan.tiba: ?w('tiba'),
        TahapPekerjaan.pengecekan: ?w('pengecekan'),
        TahapPekerjaan.perbaikan: ?w('dikerjakan'),
      },
      fotoPemeriksaan: [
        for (var i = 0; i < foto.length; i++) 'Foto pemeriksaan ${i + 1}',
      ],
    );
  }

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

  factory RiwayatLayanan.dariJson(Map<String, dynamic> j) => RiwayatLayanan(
    kode: j['kode'] as String,
    layanan: j['layanan'] as String? ?? '-',
    namaPelanggan: j['nama_pelanggan'] as String? ?? '-',
    wilayah: j['wilayah'] as String? ?? '-',
    selesaiPada: DateTime.parse(j['selesai_pada'] as String).toLocal(),
    diterima: (j['diterima'] as num).toInt(),
    rating: (j['rating'] as num?)?.toInt(),
  );
}

/// Pengajuan pencairan saldo teknisi (ditransfer manual oleh Admin).
class PengajuanPencairan {
  final String kode;
  final int nominal;
  final String rekening;
  final DateTime diajukanPada;
  final String status;

  /// Alasan Admin bila pengajuan ditolak.
  final String? alasanPenolakan;

  const PengajuanPencairan({
    required this.kode,
    required this.nominal,
    required this.rekening,
    required this.diajukanPada,
    this.status = 'Menunggu',
    this.alasanPenolakan,
  });

  factory PengajuanPencairan.dariJson(Map<String, dynamic> j) =>
      PengajuanPencairan(
        kode: j['kode'] as String,
        nominal: (j['nominal'] as num).toInt(),
        rekening: j['rekening'] as String? ?? '-',
        diajukanPada: DateTime.parse(j['diajukan_pada'] as String).toLocal(),
        status: j['label_status'] as String? ?? 'Menunggu',
        alasanPenolakan: j['alasan_penolakan'] as String?,
      );
}

/// Ringkasan dompet dari server.
class DompetTeknisi {
  final int saldo;
  final int pendapatanHariIni;
  final int minimumPencairan;

  /// Rekening tujuan pencairan, misal `BNI • 123 a.n Andi`; `null` bila
  /// belum diisi.
  final String? rekening;

  const DompetTeknisi({
    required this.saldo,
    required this.pendapatanHariIni,
    required this.minimumPencairan,
    this.rekening,
  });

  factory DompetTeknisi.dariJson(Map<String, dynamic> j) {
    final r = j['rekening'] as Map<String, dynamic>?;
    return DompetTeknisi(
      saldo: (j['saldo'] as num).toInt(),
      pendapatanHariIni: (j['pendapatan_hari_ini'] as num).toInt(),
      minimumPencairan: (j['minimum_pencairan'] as num?)?.toInt() ?? 50000,
      rekening: r == null
          ? null
          : '${r['nama_bank']} • ${r['no_rekening']} a.n ${r['atas_nama']}',
    );
  }
}

/// Sisi teknisi lewat API `/api/teknisi`: status online, tawaran pesanan,
/// dan langkah kerja. Tawaran dan status pekerjaan diperiksa ke server
/// setiap [selangPeriksa] selama online.
// TODO(fcm): tawaran dan persetujuan biaya lewat notifikasi; pemeriksaan
// berkala jadi cadangan.
class TeknisiService {
  TeknisiService._();

  static final TeknisiService instance = TeknisiService._();

  /// Potongan platform (%) dari total yang dibayar pelanggan.
  static const int persentasePlatform = 10;

  /// Minimum pencairan saldo (Rp).
  static const int minimumPencairan = 50000;

  /// Selang pemeriksaan tawaran & status pekerjaan ke server.
  static Duration selangPeriksa = const Duration(seconds: 3);

  /// Selang pengiriman lokasi selama online (server menganggap lokasi
  /// lebih lama dari 30 menit tidak aktif).
  static Duration selangLokasi = const Duration(minutes: 5);

  final ValueNotifier<bool> online = ValueNotifier(false);
  final ValueNotifier<TawaranPesanan?> tawaran = ValueNotifier(null);
  final ValueNotifier<PekerjaanTeknisi?> pekerjaan = ValueNotifier(null);

  /// Pekerjaan selesai (dari server, terbaru dulu).
  final ValueNotifier<List<RiwayatLayanan>> riwayat = ValueNotifier(const []);

  /// Ringkasan dompet; `null` sebelum dimuat.
  final ValueNotifier<DompetTeknisi?> dompet = ValueNotifier(null);
  final ValueNotifier<List<PengajuanPencairan>> pencairan = ValueNotifier(
    const [],
  );

  /// Batas waktu kartu tawaran yang sedang tampil (sisa waktu dari server).
  Duration batasAktif = const Duration(seconds: 30);

  Timer? _timerPeriksa;
  Timer? _timerLokasi;
  bool _sedangPeriksa = false;

  static int hitungKomisi(int totalDibayar) =>
      totalDibayar - (totalDibayar * persentasePlatform / 100).round();

  /// Pendapatan bersih hari ini (WIB), dihitung server.
  int get pendapatanHariIni => dompet.value?.pendapatanHariIni ?? 0;

  /// Saldo yang bisa dicairkan: total pendapatan dikurangi pencairan yang
  /// sedang diajukan atau sudah ditransfer (dihitung server).
  int get saldo => dompet.value?.saldo ?? 0;

  /// Rekening tujuan pencairan; `null` bila belum diisi.
  String? get rekeningTujuan => dompet.value?.rekening;

  /// Dipanggil saat aplikasi teknisi dibuka: pulihkan pekerjaan berjalan.
  Future<void> muat() async {
    if (await ApiClient.token() == null) return;
    unawaited(muatDompet());
    await _periksa();
    if (pekerjaan.value != null) {
      online.value = true;
      _mulaiPeriksa();
    }
  }

  /// Ubah status ketersediaan. Mengembalikan pesan galat atau `null`.
  /// Online butuh lokasi saat ini; offline ditolak selama ada pekerjaan.
  Future<String?> aturOnline(bool nilai) async {
    if (!nilai && pekerjaan.value != null) {
      return 'Selesaikan pesanan aktif terlebih dahulu';
    }
    final Map<String, dynamic> isi = {'online': nilai};
    if (nilai) {
      try {
        final titik = await Perangkat.koordinatSaatIni();
        isi['latitude'] = titik.latitude;
        isi['longitude'] = titik.longitude;
      } on LokasiException catch (e) {
        return e.pesan;
      } catch (_) {
        return 'Gagal mendapatkan lokasi saat ini';
      }
    }
    try {
      await ApiClient.put('/teknisi/status', isi);
    } on ApiException catch (e) {
      return e.pesan;
    }
    online.value = nilai;
    if (nilai) {
      _mulaiPeriksa();
      unawaited(_periksa());
    } else {
      _berhentiPeriksa();
      tawaran.value = null;
    }
    return null;
  }

  void _mulaiPeriksa() {
    _timerPeriksa?.cancel();
    _timerPeriksa = Timer.periodic(selangPeriksa, (_) => _periksa());
    _timerLokasi?.cancel();
    _timerLokasi = Timer.periodic(selangLokasi, (_) => _kirimLokasi());
  }

  void _berhentiPeriksa() {
    _timerPeriksa?.cancel();
    _timerLokasi?.cancel();
    _timerPeriksa = null;
    _timerLokasi = null;
  }

  Future<void> _kirimLokasi() async {
    try {
      final titik = await Perangkat.koordinatSaatIni();
      await ApiClient.put('/teknisi/lokasi', {
        'latitude': titik.latitude,
        'longitude': titik.longitude,
      });
    } catch (_) {
      // Dicoba lagi di putaran berikutnya.
    }
  }

  /// Ambil pekerjaan berjalan; bila tidak ada dan sedang online, tawaran.
  Future<void> _periksa() async {
    if (_sedangPeriksa) return;
    _sedangPeriksa = true;
    try {
      final kerja = await ApiClient.get('/teknisi/pekerjaan');
      final data = kerja['data'];
      pekerjaan.value = data is Map<String, dynamic>
          ? PekerjaanTeknisi.dariJson(data)
          : null;
      if (pekerjaan.value != null || !online.value) {
        tawaran.value = null;
        return;
      }
      final res = await ApiClient.get('/teknisi/tawaran');
      final t = res['data'];
      if (t is! Map<String, dynamic>) {
        tawaran.value = null;
        return;
      }
      final baru = TawaranPesanan.dariJson(t);
      if (tawaran.value?.id != baru.id) {
        final sisa =
            ((t['tawaran'] as Map?)?['sisa_detik'] as num?)?.toInt() ?? 30;
        batasAktif = Duration(seconds: sisa);
        tawaran.value = baru;
      }
    } on ApiException {
      // Koneksi putus sesaat: coba lagi di putaran berikutnya.
    } finally {
      _sedangPeriksa = false;
    }
  }

  /// Terima tawaran. Mengembalikan pesan galat (misal tawaran sudah
  /// diteruskan ke teknisi lain) atau `null`.
  Future<String?> terimaTawaran() async {
    final t = tawaran.value;
    if (t == null) return 'Tawaran sudah tidak berlaku';
    try {
      final res = await ApiClient.post('/teknisi/tawaran/${t.id}/terima');
      pekerjaan.value = PekerjaanTeknisi.dariJson(
        res['data'] as Map<String, dynamic>,
      );
      return null;
    } on ApiException catch (e) {
      return e.pesan;
    } finally {
      tawaran.value = null;
    }
  }

  /// Tolak tawaran atau biarkan lewat batas waktu; server meneruskannya ke
  /// teknisi lain.
  Future<void> tolakTawaran() async {
    final t = tawaran.value;
    tawaran.value = null;
    if (t == null) return;
    try {
      await ApiClient.post('/teknisi/tawaran/${t.id}/tolak');
    } on ApiException {
      // Lewat batas waktu: server sudah meneruskannya sendiri.
    }
  }

  /// Menuju -> Tiba -> Pengecekan.
  Future<String?> lanjutTahap() async {
    final p = pekerjaan.value;
    if (p == null) return null;
    final langkah = switch (p.tahap) {
      TahapPekerjaan.menuju => 'tiba',
      TahapPekerjaan.tiba => 'pengecekan',
      _ => null,
    };
    if (langkah == null) return null;
    return _langkah(p, langkah);
  }

  /// Unggah foto kondisi unit saat pengecekan.
  Future<String?> tambahFotoPemeriksaan(XFile foto) async {
    final p = pekerjaan.value;
    if (p == null) return null;
    try {
      final res = await ApiClient.multipart(
        '/teknisi/pekerjaan/${p.pesanan.id}/foto-pemeriksaan',
        berkas: {'foto': foto},
      );
      pekerjaan.value = PekerjaanTeknisi.dariJson(
        res['data'] as Map<String, dynamic>,
      );
      return null;
    } on ApiException catch (e) {
      return e.pesan;
    }
  }

  /// Kirim rincian biaya perbaikan ke pelanggan (UC-22).
  Future<String?> ajukanBiaya(List<ItemBiaya> item, String catatan) async {
    final p = pekerjaan.value;
    if (p == null) return null;
    return _langkah(p, 'biaya', {
      'item': [
        for (final i in item)
          {'nama': i.nama, 'jenis': i.jenis.nilai, 'harga': i.harga},
      ],
      if (catatan.trim().isNotEmpty) 'catatan': catatan.trim(),
    });
  }

  /// Pengecekan selesai tanpa biaya tambahan: langsung dikerjakan.
  Future<String?> lanjutTanpaBiayaTambahan() async {
    final p = pekerjaan.value;
    if (p == null) return null;
    return _langkah(p, 'tanpa-biaya');
  }

  Future<String?> _langkah(
    PekerjaanTeknisi p,
    String langkah, [
    Map<String, dynamic>? isi,
  ]) async {
    try {
      final res = await ApiClient.post(
        '/teknisi/pekerjaan/${p.pesanan.id}/$langkah',
        isi,
      );
      pekerjaan.value = PekerjaanTeknisi.dariJson(
        res['data'] as Map<String, dynamic>,
      );
      return null;
    } on ApiException catch (e) {
      return e.pesan;
    }
  }

  /// Unggah bukti kerja dan selesaikan pesanan. Mengembalikan komisi
  /// teknisi; melempar [ApiException] bila ditolak server.
  Future<int> selesaikan({
    required String catatan,
    required XFile sebelum,
    required XFile sesudah,
    List<XFile> tambahan = const [],
  }) async {
    final p = pekerjaan.value;
    if (p == null) return 0;
    await ApiClient.multipart(
      '/teknisi/pekerjaan/${p.pesanan.id}/selesai',
      kolom: {'catatan': catatan},
      berkas: {
        'foto_sebelum': sebelum,
        'foto_sesudah': sesudah,
        for (var i = 0; i < tambahan.length; i++)
          'foto_tambahan[$i]': tambahan[i],
      },
    );
    final komisi = hitungKomisi(p.totalTagihan);
    // Pendapatan dicatat server setelah pelanggan lunas; muat ulang dompet.
    unawaited(muatDompet());
    pekerjaan.value = null;
    return komisi;
  }

  /// Muat saldo, pendapatan hari ini, riwayat pencairan, dan riwayat
  /// pekerjaan dari server. Gagal (tanpa koneksi) = data lama tetap tampil.
  Future<void> muatDompet() async {
    try {
      final hasil = await Future.wait([
        ApiClient.get('/teknisi/dompet'),
        ApiClient.get('/teknisi/riwayat'),
      ]);
      final d = hasil[0]['data'] as Map<String, dynamic>;
      dompet.value = DompetTeknisi.dariJson(d);
      pencairan.value = [
        for (final p in (d['pencairan'] as List).cast<Map<String, dynamic>>())
          PengajuanPencairan.dariJson(p),
      ];
      riwayat.value = [
        for (final r in (hasil[1]['data'] as List).cast<Map<String, dynamic>>())
          RiwayatLayanan.dariJson(r),
      ];
    } on ApiException catch (e) {
      debugPrint('Dompet gagal dimuat: ${e.pesan}');
    }
  }

  /// Ajukan pencairan; mengembalikan pesan galat atau `null` bila berhasil.
  Future<String?> ajukanPencairan(int nominal) async {
    if (nominal < minimumPencairan) {
      return 'Minimal pencairan Rp50.000';
    }
    if (nominal > saldo) return 'Nominal melebihi saldo';
    try {
      final res = await ApiClient.post('/teknisi/pencairan', {
        'nominal': nominal,
      });
      final d = res['data'] as Map<String, dynamic>;
      dompet.value = DompetTeknisi.dariJson(d);
      pencairan.value = [
        for (final p in (d['pencairan'] as List).cast<Map<String, dynamic>>())
          PengajuanPencairan.dariJson(p),
      ];
      return null;
    } on ApiException catch (e) {
      return e.pesan;
    }
  }

  /// Kembalikan ke kondisi awal (dipakai test dan saat keluar akun).
  void reset() {
    _berhentiPeriksa();
    batasAktif = const Duration(seconds: 30);
    online.value = false;
    tawaran.value = null;
    pekerjaan.value = null;
    riwayat.value = const [];
    dompet.value = null;
    pencairan.value = const [];
  }
}
