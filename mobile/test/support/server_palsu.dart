import 'dart:convert';

import 'package:acare_mobile/services/api_client.dart';
import 'package:acare_mobile/services/auth_service.dart';
import 'package:acare_mobile/services/order_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Tiruan API Laravel di memori untuk widget test. Aturannya mengikuti
/// backend (lihat backend/tests/Feature/Api), supaya test aplikasi menguji
/// alur yang sama tanpa server sungguhan.
class ServerPalsu {
  /// Server yang sedang terpasang di [ApiClient].
  static late ServerPalsu aktif;

  /// Kata sandi semua akun contoh.
  static const sandiContoh = 'rahasia123';

  final List<Map<String, dynamic>> akun = [
    {
      'id': 1,
      'nama': 'Dina Safitri',
      'email': 'dina@gmail.com',
      'no_telepon': '081111111111',
      'kata_sandi': sandiContoh,
      'role': 'pelanggan',
      'status_akun': 'aktif',
      'foto_profil': null,
    },
    {
      'id': 2,
      'nama': 'Rizky Pratama',
      'email': 'teknisi@acare.id',
      'no_telepon': '081200000003',
      'kata_sandi': sandiContoh,
      'role': 'teknisi',
      'status_akun': 'aktif',
      'foto_profil': null,
      'teknisi': {
        'status_verifikasi': 'terverifikasi',
        'alasan_penolakan': null,
        'jenis_kendaraan': 'Honda Beat',
        'plat_nomor': 'BP 1234 AC',
        'deskripsi': 'Berpengalaman 5 tahun menangani AC rumah dan kantor.',
        'nama_bank': 'BNI',
        'no_rekening': '1234567890',
        'atas_nama': 'Rizky Pratama',
      },
    },
  ];

  /// Katalog layanan (sama dengan LayananSeeder).
  final List<Map<String, dynamic>> layanan = [
    {
      'id': 1,
      'nama': 'Cuci AC',
      'deskripsi': 'Cuci',
      'harga': 75000,
      'estimasi_durasi': 45,
      'bisa_biaya_tambahan': false,
    },
    {
      'id': 2,
      'nama': 'Service AC',
      'deskripsi': 'Service',
      'harga': 100000,
      'estimasi_durasi': 45,
      'bisa_biaya_tambahan': true,
    },
    {
      'id': 3,
      'nama': 'Isi Freon',
      'deskripsi': 'Freon',
      'harga': 150000,
      'estimasi_durasi': 45,
      'bisa_biaya_tambahan': false,
    },
    {
      'id': 4,
      'nama': 'Bongkar Pasang',
      'deskripsi': 'Bongkar',
      'harga': 100000,
      'estimasi_durasi': 45,
      'bisa_biaya_tambahan': false,
    },
    {
      'id': 5,
      'nama': 'Cek AC',
      'deskripsi': 'Cek',
      'harga': 50000,
      'estimasi_durasi': 30,
      'bisa_biaya_tambahan': true,
    },
  ];

  /// Alamat tersimpan: id akun -> daftar alamat.
  final Map<int, List<Map<String, dynamic>>> alamat = {
    1: [
      {
        'id': 1,
        'label': 'Rumah',
        'alamat_lengkap': 'Perumahan Batu Aji Blok C No. 12, Batam',
        'latitude': 1.0436,
        'longitude': 103.9806,
      },
    ],
  };

  /// Id alamat yang sedang dipakai pesanan aktif (tidak bisa dihapus).
  final Set<int> alamatDipakai = {};

  /// Pesanan di server palsu (bentuk sama dengan PesananResource).
  final List<Map<String, dynamic>> pesanan = [];

  /// Teknisi palsu menerima pesanan yang sudah dibayar setelah status
  /// diperiksa sebanyak ini; `null` = tidak pernah ada yang menerima.
  int? terimaSetelahPeriksa = 2;

  final Map<int, int> _jumlahPeriksa = {};

  /// Langsung batalkan pencarian seolah 15 menit tanpa teknisi.
  void habisWaktuPencarian(int id) {
    final p = _p(id);
    p['status'] = 'dibatalkan';
    p['alasan_pembatalan'] =
        'Tidak ada teknisi yang menerima dalam batas waktu';
  }

  Map<String, dynamic> _p(int id) => pesanan.firstWhere((p) => p['id'] == id);

  static const _kunciWaktu = {
    'pengecekan_awal': 'pengecekan',
    'dikerjakan': 'dikerjakan',
    'menunggu_pembayaran': 'menunggu_pembayaran',
    'selesai': 'selesai',
    'tiba': 'tiba',
  };

  /// Teknisi palsu memajukan status pesanan (misal `pengecekan_awal`).
  void majukan(int id, String status) {
    final p = _p(id);
    p['status'] = status;
    final k = _kunciWaktu[status];
    if (k != null) {
      (p['waktu'] as Map)[k] = DateTime(2026, 11, 26, 14, 30).toIso8601String();
    }
  }

  /// Teknisi palsu mengajukan biaya perbaikan.
  void ajukanBiaya(int id, Map<String, int> item, {String catatan = ''}) {
    final p = _p(id);
    final biaya = p['biaya'] as Map<String, dynamic>;
    for (final e in item.entries) {
      (biaya['rincian'] as List).add({
        'nama': e.key,
        'jenis': 'suku_cadang',
        'jumlah': 1,
        'harga': e.value,
        'subtotal': e.value,
        'ditagih': false,
      });
    }
    biaya['status_biaya'] = 'menunggu';
    biaya['catatan_teknisi'] = catatan;
    majukan(id, 'menunggu_persetujuan_biaya');
  }

  /// Teknisi palsu selesai bekerja: pelunasan bila ada biaya disetujui.
  void selesaiDikerjakan(int id) {
    final p = _p(id);
    final biaya = p['biaya'] as Map<String, dynamic>;
    final tambahan = (biaya['rincian'] as List)
        .where(
          (r) =>
              r['jenis'] != 'layanan' && biaya['status_biaya'] == 'disetujui',
        )
        .fold<int>(0, (a, r) => a + (r['subtotal'] as int));
    if (tambahan <= 0) {
      majukan(id, 'selesai');
      return;
    }
    (p['pembayaran'] as List).add({
      'id': id * 10 + 1,
      'jenis': 'pelunasan',
      'status': 'menunggu',
      'jumlah': tambahan,
      'metode': null,
    });
    majukan(id, 'menunggu_pembayaran');
  }

  /// Pesanan Dina yang sudah dibayar dan diterima teknisi Andi, lalu
  /// dimajukan ke [status]. [biaya] diajukan teknisi (dan disetujui bila
  /// status sudah melewati persetujuan).
  Future<PesananPelanggan> buatPesananUji({
    String layanan = 'Service AC',
    String status = 'pengecekan_awal',
    Map<String, int>? biaya,
  }) async {
    await masukPelanggan();
    final l = this.layanan.firstWhere((x) => x['nama'] == layanan);
    final p = _buatPesanan({
      'id_layanan': l['id'],
      'jumlah_unit': 1,
      'jenis_ac': 'split',
      'pk': 1,
      'id_lokasi': 1,
      'detail_lokasi': 'Pagar hitam',
      'jadwal_service': DateTime.now().toIso8601String(),
    }, 1);
    final bayar = (p['pembayaran'] as List).first as Map<String, dynamic>;
    bayar['status'] = 'berhasil';
    bayar['metode'] = 'QRIS';
    p['bisa_dibatalkan'] = false;
    p['teknisi'] = {
      'id': 2,
      'nama': 'Andi Saputra',
      'no_telepon': '081234567890',
      'jenis_kendaraan': 'Honda Beat',
      'plat_nomor': 'BP 4892 QL',
      'deskripsi': 'Berpengalaman 5 tahun menangani AC rumah dan kantor.',
    };
    pesanan.add(p);
    final id = p['id'] as int;
    majukan(id, 'pengecekan_awal');
    if (biaya != null) ajukanBiaya(id, biaya, catatan: 'Perlu diganti.');
    if (['dikerjakan', 'menunggu_pembayaran', 'selesai'].contains(status)) {
      if (biaya != null) {
        final b = p['biaya'] as Map<String, dynamic>;
        b['status_biaya'] = 'disetujui';
        b['total'] = (b['rincian'] as List).fold<int>(
          0,
          (a, r) => a + (r['subtotal'] as int),
        );
      }
      majukan(id, 'dikerjakan');
      if (status != 'dikerjakan') selesaiDikerjakan(id);
    } else if (status != 'pengecekan_awal' && biaya == null) {
      majukan(id, status);
    }
    return PesananPelanggan.dariJson(p);
  }

  // ---------- Sisi teknisi (akun id 2) ----------

  static const _idTeknisi = 2;
  bool teknisiOnline = false;

  /// Pelanggan tiruan menyetujui biaya setelah teknisi memeriksa status
  /// sebanyak ini; `null` = tidak pernah menanggapi.
  int? setujuiSetelahPeriksa = 1;
  int _periksaBiaya = 0;

  /// Masuk sebagai teknisi contoh (Rizky).
  static Future<void> masukTeknisi() async {
    final h = await AuthService.login(
      'teknisi@acare.id',
      sandiContoh,
      UserRole.teknisi,
    );
    if (!h.berhasil) throw StateError('Gagal masuk: ${h.pesan}');
  }

  /// Pesanan baru yang sudah dibayar dan ditawarkan ke teknisi contoh.
  Map<String, dynamic> tawarkan({String layanan = 'Service AC'}) {
    final l = this.layanan.firstWhere((x) => x['nama'] == layanan);
    final p = _buatPesanan({
      'id_layanan': l['id'],
      'jumlah_unit': 1,
      'jenis_ac': 'split',
      'pk': 1,
      'merek': 'Daikin',
      'id_lokasi': 1,
      'detail_lokasi': 'Batu Aji',
      'jadwal_service': DateTime.now().toIso8601String(),
      'catatan': 'AC kamar utama netes air.',
      'detail_layanan': {
        'keluhan': ['Tidak dingin'],
      },
    }, 1);
    ((p['pembayaran'] as List).first as Map)['status'] = 'berhasil';
    p['ditawari'] = _idTeknisi;
    p['foto'] = <Map<String, dynamic>>[];
    pesanan.add(p);
    return p;
  }

  Map<String, dynamic> _jsonPekerjaan(Map<String, dynamic> p) {
    final tawaran = p['status'] == 'mencari_teknisi';
    final l = p['layanan'] as Map<String, dynamic>;
    final biaya = p['biaya'] as Map<String, dynamic>;
    return {
      'id': p['id'],
      'kode': p['kode'],
      'status': p['status'],
      'layanan': l['nama'],
      'bisa_biaya_tambahan': (layanan.firstWhere(
        (x) => x['id'] == l['id'],
      ))['bisa_biaya_tambahan'],
      'jumlah_unit': p['jumlah_unit'],
      'jenis_ac': p['jenis_ac'],
      'pk': p['pk'],
      'merek': p['merek'],
      'biaya_awal': ((biaya['rincian'] as List).first as Map)['subtotal'],
      'detail_layanan': p['detail_layanan'],
      'catatan': p['catatan'],
      'pelanggan': {
        'nama': 'Dina Safitri',
        'no_telepon': tawaran ? null : '081111111111',
      },
      'alamat': {
        'alamat_lengkap': (p['alamat'] as Map)['alamat_lengkap'],
        'detail_lokasi': p['detail_lokasi'],
        'latitude': (p['alamat'] as Map)['latitude'],
        'longitude': (p['alamat'] as Map)['longitude'],
      },
      'jarak_km': 2.1,
      'menit_tempuh': 7,
      if (tawaran) 'tawaran': {'sisa_detik': 30},
      'biaya': {
        'rincian': biaya['rincian'],
        'total': biaya['total'],
        'status_biaya': biaya['status_biaya'],
        'catatan': biaya['catatan_teknisi'],
      },
      'foto': p['foto'] ?? [],
      'waktu': p['waktu'],
    };
  }

  static const _statusBekerja = {
    'menuju_lokasi',
    'tiba',
    'pengecekan_awal',
    'menunggu_persetujuan_biaya',
    'dikerjakan',
    'menunggu_pembayaran',
  };

  Map<String, dynamic>? get _pekerjaanTeknisi => pesanan
      .where(
        (p) =>
            p['id_teknisi'] == _idTeknisi &&
            _statusBekerja.contains(p['status']),
      )
      .firstOrNull;

  http.Response? _ruteTeknisi(String rute, Map<String, dynamic> isi) {
    if (rute == 'PUT /teknisi/status') {
      if (isi['online'] != true && _pekerjaanTeknisi != null) {
        return _json(409, {
          'message': 'Selesaikan pesanan yang sedang berjalan sebelum offline.',
          'kode': 'masih_ada_pekerjaan',
        });
      }
      teknisiOnline = isi['online'] == true;
      return _json(200, {
        'data': {'online': teknisiOnline},
      });
    }
    if (rute == 'PUT /teknisi/lokasi') return _json(200, {'data': {}});
    if (rute == 'GET /teknisi/tawaran') {
      final p = teknisiOnline
          ? pesanan
                .where(
                  (p) =>
                      p['ditawari'] == _idTeknisi &&
                      p['status'] == 'mencari_teknisi',
                )
                .firstOrNull
          : null;
      return _json(200, {'data': p == null ? null : _jsonPekerjaan(p)});
    }
    if (rute == 'GET /teknisi/pekerjaan') {
      final p = _pekerjaanTeknisi;
      // Pelanggan tiruan menanggapi biaya.
      if (p != null &&
          p['status'] == 'menunggu_persetujuan_biaya' &&
          setujuiSetelahPeriksa != null &&
          ++_periksaBiaya >= setujuiSetelahPeriksa!) {
        final b = p['biaya'] as Map<String, dynamic>;
        b['status_biaya'] = 'disetujui';
        b['total'] = (b['rincian'] as List).fold<int>(
          0,
          (a, r) => a + (r['subtotal'] as int),
        );
        majukan(p['id'] as int, 'dikerjakan');
      }
      return _json(200, {'data': p == null ? null : _jsonPekerjaan(p)});
    }

    final m = RegExp(r'^POST /teknisi/(tawaran|pekerjaan)/(\d+)/([\w-]+)$')
        .firstMatch(rute);
    if (m == null) return null;
    final p = pesanan
        .where((x) => x['id'] == int.parse(m.group(2)!))
        .firstOrNull;
    if (p == null) return _json(404, {'message': 'Data tidak ditemukan.'});
    final id = p['id'] as int;
    String? harus;
    switch (m.group(3)) {
      case 'terima':
        if (p['ditawari'] != _idTeknisi || p['status'] != 'mencari_teknisi') {
          return _json(409, {
            'message':
                'Tawaran ini sudah tidak berlaku. Tunggu tawaran berikutnya.',
            'kode': 'tawaran_tidak_berlaku',
          });
        }
        p['id_teknisi'] = _idTeknisi;
        p['ditawari'] = null;
        p['teknisi'] = {'nama': 'Rizky Pratama'};
        majukan(id, 'menuju_lokasi');
      case 'tolak':
        p['ditawari'] = null;
        return _json(200, {'message': 'Tawaran ditolak.'});
      case 'tiba':
        harus = 'menuju_lokasi';
        if (p['status'] == harus) majukan(id, 'tiba');
      case 'pengecekan':
        harus = 'tiba';
        if (p['status'] == harus) majukan(id, 'pengecekan_awal');
      case 'foto-pemeriksaan':
        (p['foto'] as List).add({
          'id': (p['foto'] as List).length + 1,
          'tahap': 'pemeriksaan',
        });
      case 'biaya':
        harus = 'pengecekan_awal';
        if (p['status'] == harus) {
          ajukanBiaya(id, {
            for (final i in (isi['item'] as List).cast<Map>())
              '${i['nama']}': (i['harga'] as num).toInt(),
          }, catatan: '${isi['catatan'] ?? ''}');
          _periksaBiaya = 0;
        }
      case 'tanpa-biaya':
        harus = 'pengecekan_awal';
        if (p['status'] == harus) majukan(id, 'dikerjakan');
      case 'selesai':
        harus = 'dikerjakan';
        if (p['status'] == harus) selesaiDikerjakan(id);
    }
    if (harus != null && p['status'] == harus) {
      return _json(409, {
        'message': 'Langkah ini tidak sesuai dengan status pesanan saat ini.',
      });
    }
    return _json(200, {'data': _jsonPekerjaan(p)});
  }

  /// Riwayat contoh untuk akun Dina (selesai/dibatalkan).
  void tambahRiwayat({
    required String layanan,
    required String status,
    int total = 100000,
    String? alasan,
    String statusBayar = 'berhasil',
  }) {
    final l = this.layanan.firstWhere((x) => x['nama'] == layanan);
    final id = 100 + pesanan.length;
    pesanan.add({
      'id': id,
      'id_pelanggan': 1,
      'kode': 'AC-${id.toString().padLeft(6, '0')}',
      'status': status,
      'layanan': {'id': l['id'], 'nama': layanan, 'harga': l['harga']},
      'jumlah_unit': 1,
      'jenis_ac': 'split',
      'pk': 1,
      'merek': 'Daikin',
      'alamat': alamat[1]!.first,
      'teknisi': status == 'selesai' ? {'nama': 'Budi Santoso'} : null,
      'biaya': {'total': total, 'rincian': []},
      'pembayaran': [
        {
          'id': id * 10,
          'jenis': 'awal',
          'status': statusBayar,
          'jumlah': total,
        },
      ],
      'alasan_pembatalan': alasan,
      'waktu': {
        'dibuat': DateTime(2026, 10, 1).toIso8601String(),
        status == 'selesai' ? 'selesai' : 'dibatalkan': DateTime(
          2026,
          10,
          1,
          12,
        ).toIso8601String(),
      },
    });
  }

  Map<String, dynamic> _buatPesanan(Map<String, dynamic> isi, int idPelanggan) {
    final l = layanan.firstWhere((l) => l['id'] == isi['id_layanan']);
    final alamatnya = (alamat[idPelanggan] ?? []).firstWhere(
      (a) => a['id'] == isi['id_lokasi'],
    );
    final unit = (isi['jumlah_unit'] as num).toInt();
    final total = (l['harga'] as int) * unit;
    final id = 100 + pesanan.length;
    return {
      'id': id,
      'id_pelanggan': idPelanggan,
      'kode': 'AC-${id.toString().padLeft(6, '0')}',
      'status': 'mencari_teknisi',
      'layanan': {'id': l['id'], 'nama': l['nama'], 'harga': l['harga']},
      'jumlah_unit': unit,
      'jenis_ac': isi['jenis_ac'],
      'pk': isi['pk'],
      'merek': isi['merek'],
      'alamat': alamatnya,
      'detail_lokasi': isi['detail_lokasi'],
      'jadwal_service': isi['jadwal_service'],
      'detail_layanan': isi['detail_layanan'] ?? {},
      'catatan': isi['catatan'],
      'biaya': {
        'total': total,
        'rincian': [
          {
            'nama': l['nama'],
            'jenis': 'layanan',
            'jumlah': unit,
            'harga': l['harga'],
            'subtotal': total,
            'ditagih': true,
          },
        ],
        'status_biaya': null,
        'catatan_teknisi': null,
      },
      'waktu': {'dibuat': DateTime.now().toIso8601String()},
      'pembayaran': [
        {
          'id': id * 10,
          'jenis': 'awal',
          'status': 'menunggu',
          'jumlah': total,
          'metode': null,
        },
      ],
      'teknisi': null,
      'bisa_dibatalkan': true,
    };
  }

  int _idAlamat = 10;

  /// token -> id akun.
  final Map<String, int> token = {};

  /// Semua permintaan yang diterima, misal `POST /masuk`.
  final List<String> log = [];

  int _urut = 0;

  /// Masuk sebagai pelanggan contoh (Dina) lewat API palsu.
  static Future<void> masukPelanggan() async {
    final h = await AuthService.login(
      'dina@gmail.com',
      sandiContoh,
      UserRole.pelanggan,
    );
    if (!h.berhasil) throw StateError('Gagal masuk: ${h.pesan}');
  }

  /// Pasang server baru (data contoh segar) dan kosongkan sesi aplikasi.
  static ServerPalsu pasang() {
    final s = ServerPalsu();
    aktif = s;
    ApiClient.alamat = 'http://acare.test/api';
    ApiClient.klien = MockClient(s._tangani);
    ApiClient.penyimpanan = PenyimpananMemori();
    AuthService.akun.value = null;
    return s;
  }

  static String normalkanTelepon(String n) {
    var a = n.replaceAll(RegExp(r'\D'), '');
    if (a.startsWith('62')) a = '0${a.substring(2)}';
    if (a.startsWith('8')) a = '0$a';
    return a;
  }

  Map<String, dynamic> _publik(Map<String, dynamic> a) => {
    for (final e in a.entries)
      if (e.key != 'kata_sandi' && e.key != 'status_akun') e.key: e.value,
  };

  http.Response _json(int status, Map<String, dynamic> isi) => http.Response(
    jsonEncode(isi),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _galat(Map<String, String> kolom) => _json(422, {
    'message': kolom.values.first,
    'errors': {
      for (final e in kolom.entries) e.key: [e.value],
    },
  });

  Map<String, dynamic>? _pemilikToken(http.Request r) {
    final h = r.headers['Authorization'] ?? r.headers['authorization'];
    final id = h == null ? null : token[h.replaceFirst('Bearer ', '')];
    if (id == null) return null;
    return akun.firstWhere((a) => a['id'] == id);
  }

  /// Kolom teks dari body multipart (berkas diabaikan).
  Map<String, String> _kolomMultipart(http.Request r) {
    final teks = latin1.decode(r.bodyBytes);
    final hasil = <String, String>{};
    final pola = RegExp(
      r'name="([^"]+)"\r\n(?!Content-Type)(?:\r\n)([\s\S]*?)\r\n--',
    );
    for (final m in pola.allMatches(teks)) {
      hasil[m.group(1)!] = m.group(2)!;
    }
    return hasil;
  }

  int _jumlahBerkas(http.Request r) =>
      RegExp('filename="').allMatches(latin1.decode(r.bodyBytes)).length;

  Map<String, String> _cekUnik(String? email, String? telepon, {int? kecuali}) {
    final g = <String, String>{};
    if (email != null &&
        akun.any((a) => a['email'] == email && a['id'] != kecuali)) {
      g['email'] = 'Email sudah terdaftar.';
    }
    if (telepon != null &&
        akun.any((a) => a['no_telepon'] == telepon && a['id'] != kecuali)) {
      g['no_telepon'] = 'Nomor telepon sudah terdaftar.';
    }
    return g;
  }

  Future<http.Response> _tangani(http.Request r) async {
    final path = r.url.path.replaceFirst('/api', '');
    log.add('${r.method} $path');
    final multipart =
        r.headers['content-type']?.startsWith('multipart/') ?? false;
    final Map<String, dynamic> isi = multipart
        ? _kolomMultipart(r)
        : (r.body.isEmpty ? {} : jsonDecode(r.body) as Map<String, dynamic>);

    switch ('${r.method} $path') {
      case 'POST /daftar':
      case 'POST /daftar/teknisi':
        final email = '${isi['email']}'.trim().toLowerCase();
        final telepon = normalkanTelepon('${isi['no_telepon']}');
        final unik = _cekUnik(email, telepon);
        if (unik.isNotEmpty) return _galat(unik);
        final teknisi = path.endsWith('teknisi');
        if (teknisi && _jumlahBerkas(r) < 5) {
          return _galat({'dokumen.ktp': 'KTP wajib diisi.'});
        }
        final baru = {
          'id': 100 + _urut++,
          'nama': '${isi['nama']}'.trim(),
          'email': email,
          'no_telepon': telepon,
          'kata_sandi': isi['kata_sandi'],
          'role': teknisi ? 'teknisi' : 'pelanggan',
          'status_akun': 'aktif',
          'foto_profil': null,
          if (teknisi)
            'teknisi': {
              'status_verifikasi': 'menunggu',
              'alasan_penolakan': null,
              'jenis_kendaraan': isi['jenis_kendaraan'],
              'plat_nomor': isi['plat_nomor'],
              'deskripsi': null,
              'nama_bank': isi['nama_bank'],
              'no_rekening': isi['no_rekening'],
              'atas_nama': isi['atas_nama'],
            },
        };
        akun.add(baru);
        return _json(201, {'message': 'OK', 'pengguna': _publik(baru)});

      case 'POST /masuk':
        final id = '${isi['identitas']}'.trim();
        final kolom = id.contains('@') ? 'email' : 'no_telepon';
        final nilai = kolom == 'email'
            ? id.toLowerCase()
            : normalkanTelepon(id);
        final a = akun.where((a) => a[kolom] == nilai).firstOrNull;
        if (a == null || a['kata_sandi'] != isi['kata_sandi']) {
          return _json(401, {
            'message': 'Email/nomor telepon atau kata sandi salah.',
            'kode': 'kredensial_salah',
          });
        }
        if (a['role'] != isi['peran']) {
          return _json(403, {
            'message': 'Akun ini terdaftar sebagai peran lain.',
            'kode': 'peran_tidak_sesuai',
          });
        }
        if (a['status_akun'] != 'aktif') {
          return _json(403, {
            'message': 'Akun kamu diblokir. Hubungi Pusat Bantuan ACare.',
            'kode': 'akun_diblokir',
          });
        }
        final t = a['teknisi'] as Map<String, dynamic>?;
        if (t != null && t['status_verifikasi'] == 'ditolak') {
          return _json(403, {
            'message': 'Pendaftaran kamu ditolak Admin.',
            'kode': 'verifikasi_ditolak',
            'alasan': t['alasan_penolakan'],
          });
        }
        if (t != null && t['status_verifikasi'] != 'terverifikasi') {
          return _json(403, {
            'message': 'Akun kamu belum diverifikasi oleh Admin.',
            'kode': 'belum_terverifikasi',
          });
        }
        final baru = 'token-${_urut++}';
        token[baru] = a['id'] as int;
        return _json(200, {'token': baru, 'pengguna': _publik(a)});
    }

    // Semua endpoint di bawah butuh token.
    final saya = _pemilikToken(r);
    if (saya == null) return _json(401, {'message': 'Unauthenticated.'});
    if (saya['status_akun'] != 'aktif') {
      return _json(403, {
        'message': 'Akun kamu diblokir. Hubungi Pusat Bantuan ACare.',
        'kode': 'akun_diblokir',
      });
    }

    switch ('${r.method} $path') {
      case 'POST /keluar':
        token.removeWhere((k, v) => r.headers['Authorization'] == 'Bearer $k');
        return _json(200, {'message': 'Kamu sudah keluar.'});

      case 'GET /saya':
        return _json(200, {'data': _publik(saya)});

      case 'PUT /saya':
        final email = (isi['email'] as String?)?.trim().toLowerCase();
        final telepon = isi['no_telepon'] == null
            ? null
            : normalkanTelepon('${isi['no_telepon']}');
        final unik = _cekUnik(email, telepon, kecuali: saya['id'] as int);
        if (unik.isNotEmpty) return _galat(unik);
        if (isi['nama'] != null) saya['nama'] = '${isi['nama']}'.trim();
        if (email != null) saya['email'] = email;
        if (telepon != null) saya['no_telepon'] = telepon;
        final t = saya['teknisi'] as Map<String, dynamic>?;
        if (t != null) {
          for (final k in ['jenis_kendaraan', 'plat_nomor', 'deskripsi']) {
            if (isi.containsKey(k)) t[k] = isi[k];
          }
        }
        return _json(200, {'data': _publik(saya)});

      case 'POST /saya/foto':
        saya['foto_profil'] = 'http://acare.test/storage/foto-profil/x.jpg';
        return _json(200, {'data': _publik(saya)});

      case 'GET /layanan':
        return _json(200, {'data': layanan});

      case 'GET /alamat':
        return _json(200, {'data': alamat[saya['id']] ?? []});

      case 'POST /alamat':
        if ('${isi['label'] ?? ''}'.trim().isEmpty) {
          return _galat({'label': 'Label alamat wajib diisi.'});
        }
        final baru = {
          'id': _idAlamat++,
          'label': '${isi['label']}'.trim(),
          'alamat_lengkap': '${isi['alamat_lengkap']}'.trim(),
          'latitude': isi['latitude'],
          'longitude': isi['longitude'],
        };
        (alamat[saya['id'] as int] ??= []).add(baru);
        return _json(201, {'data': baru});
    }

    final rute = '${r.method} $path';
    if (path.startsWith('/teknisi/')) {
      return _ruteTeknisi(rute, isi) ??
          _json(404, {'message': 'Tidak ditemukan.'});
    }
    final milikSaya = pesanan.where((p) => p['id_pelanggan'] == saya['id']);

    if (rute == 'POST /pesanan') {
      final aktif = milikSaya.any(
        (p) => !['selesai', 'dibatalkan'].contains(p['status']),
      );
      if (aktif) {
        return _json(409, {
          'message': 'Masih ada pesanan yang sedang berjalan. Selesaikan atau batalkan dulu sebelum memesan lagi.',
          'kode': 'masih_ada_pesanan_aktif',
        });
      }
      final baru = _buatPesanan(isi, saya['id'] as int);
      pesanan.add(baru);
      return _json(201, {'data': baru});
    }

    if (rute == 'GET /pesanan') {
      final status = r.url.queryParameters['status'];
      final hasil = milikSaya
          .where(
            (p) => switch (status) {
              'aktif' => !['selesai', 'dibatalkan'].contains(p['status']),
              null => true,
              _ => p['status'] == status,
            },
          )
          .toList()
          .reversed
          .toList();
      return _json(200, {'data': hasil});
    }

    final cocokPesanan = RegExp(
      r'^(GET|POST) /pesanan/(\d+)(?:/(batal|biaya|pembayaran/(\d+)/simulasi-lunas))?$',
    ).firstMatch(rute);
    if (cocokPesanan != null) {
      final id = int.parse(cocokPesanan.group(2)!);
      final p = milikSaya.where((p) => p['id'] == id).firstOrNull;
      if (p == null) return _json(404, {'message': 'Data tidak ditemukan.'});
      final aksi = cocokPesanan.group(3);
      final semuaBayar = (p['pembayaran'] as List).cast<Map<String, dynamic>>();
      final idBayar = int.tryParse(cocokPesanan.group(4) ?? '');
      final bayar = idBayar == null
          ? semuaBayar.first
          : semuaBayar.firstWhere((b) => b['id'] == idBayar);

      if (aksi == 'biaya') {
        final biaya = p['biaya'] as Map<String, dynamic>;
        if (p['status'] != 'menunggu_persetujuan_biaya') {
          return _json(409, {
            'message': 'Waktu persetujuan sudah habis, pesanan dilanjutkan dengan biaya awal saja.',
            'kode': 'tidak_ada_persetujuan',
          });
        }
        final setuju = isi['setuju'] == true;
        biaya['status_biaya'] = setuju ? 'disetujui' : 'ditolak';
        if (setuju) {
          biaya['total'] = (biaya['rincian'] as List).fold<int>(
            0,
            (a, r) => a + (r['subtotal'] as int),
          );
        }
        majukan(id, 'dikerjakan');
      } else if (aksi == 'batal') {
        if (p['status'] != 'mencari_teknisi') {
          return _json(422, {
            'message':
                'Pesanan tidak bisa dibatalkan karena teknisi sudah ditemukan.',
            'kode': 'tidak_bisa_dibatalkan',
          });
        }
        p['status'] = 'dibatalkan';
        p['bisa_dibatalkan'] = false;
        p['alasan_pembatalan'] =
            isi['alasan'] ?? 'Dibatalkan oleh pelanggan saat mencari teknisi';
        bayar['status'] = bayar['status'] == 'berhasil'
            ? 'tertahan'
            : 'kedaluwarsa';
      } else if (aksi != null) {
        bayar['status'] = 'berhasil';
        bayar['metode'] = 'SIMULASI';
        if (bayar['jenis'] == 'pelunasan') majukan(id, 'selesai');
      } else if (p['status'] == 'mencari_teknisi' &&
          bayar['status'] == 'berhasil') {
        // Pelanggan memeriksa status: teknisi palsu menerima setelah beberapa kali.
        final n = _jumlahPeriksa[id] = (_jumlahPeriksa[id] ?? 0) + 1;
        if (terimaSetelahPeriksa != null && n >= terimaSetelahPeriksa!) {
          p['status'] = 'menuju_lokasi';
          p['bisa_dibatalkan'] = false;
          p['teknisi'] = {
            'id': 2,
            'nama': 'Andi Saputra',
            'no_telepon': '081234567890',
            'jenis_kendaraan': 'Honda Beat',
            'plat_nomor': 'BP 4892 QL',
            'deskripsi': 'Berpengalaman 5 tahun menangani AC rumah dan kantor.',
          };
        }
      }
      return _json(200, {'data': p});
    }

    final cocokAlamat = RegExp(r'^(PUT|DELETE) /alamat/(\d+)$')
        .firstMatch('${r.method} $path');
    if (cocokAlamat != null) {
      final daftar = alamat[saya['id'] as int] ?? [];
      final id = int.parse(cocokAlamat.group(2)!);
      final i = daftar.indexWhere((a) => a['id'] == id);
      if (i < 0) return _json(404, {'message': 'Data tidak ditemukan.'});
      if (cocokAlamat.group(1) == 'DELETE') {
        if (alamatDipakai.contains(id)) {
          return _json(422, {
            'message': 'Alamat tidak dapat dihapus karena sedang digunakan pada pesanan aktif.',
            'kode': 'alamat_dipakai',
          });
        }
        daftar.removeAt(i);
        return _json(200, {'message': 'Alamat dihapus.'});
      }
      // Alamat yang dipakai pesanan disimpan sebagai alamat baru.
      final baru = {
        'id': alamatDipakai.contains(id) ? _idAlamat++ : id,
        'label': '${isi['label']}'.trim(),
        'alamat_lengkap': '${isi['alamat_lengkap']}'.trim(),
        'latitude': isi['latitude'],
        'longitude': isi['longitude'],
      };
      daftar[i] = baru;
      return _json(200, {'data': baru});
    }

    switch ('${r.method} $path') {
      case 'PUT /saya/kata-sandi':
        if (isi['kata_sandi_lama'] != saya['kata_sandi']) {
          return _galat({'kata_sandi_lama': 'Kata sandi lama tidak sesuai.'});
        }
        saya['kata_sandi'] = isi['kata_sandi_baru'];
        return _json(200, {'message': 'Kata sandi berhasil diubah.'});
    }

    return _json(404, {'message': 'Tidak ditemukan.'});
  }
}
