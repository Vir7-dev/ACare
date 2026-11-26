import 'dart:convert';

import 'package:acare_mobile/services/api_client.dart';
import 'package:acare_mobile/services/auth_service.dart';
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
    {'id': 1, 'nama': 'Cuci AC', 'deskripsi': 'Cuci', 'harga': 75000, 'estimasi_durasi': 45, 'bisa_biaya_tambahan': false},
    {'id': 2, 'nama': 'Service AC', 'deskripsi': 'Service', 'harga': 100000, 'estimasi_durasi': 45, 'bisa_biaya_tambahan': true},
    {'id': 3, 'nama': 'Isi Freon', 'deskripsi': 'Freon', 'harga': 150000, 'estimasi_durasi': 45, 'bisa_biaya_tambahan': false},
    {'id': 4, 'nama': 'Bongkar Pasang', 'deskripsi': 'Bongkar', 'harga': 100000, 'estimasi_durasi': 45, 'bisa_biaya_tambahan': false},
    {'id': 5, 'nama': 'Cek AC', 'deskripsi': 'Cek', 'harga': 50000, 'estimasi_durasi': 30, 'bisa_biaya_tambahan': true},
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

  Map<String, String> _cekUnik(
    String? email,
    String? telepon, {
    int? kecuali,
  }) {
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

    final cocokAlamat = RegExp(r'^(PUT|DELETE) /alamat/(\d+)$').firstMatch(
      '${r.method} $path',
    );
    if (cocokAlamat != null) {
      final daftar = alamat[saya['id'] as int] ?? [];
      final id = int.parse(cocokAlamat.group(2)!);
      final i = daftar.indexWhere((a) => a['id'] == id);
      if (i < 0) return _json(404, {'message': 'Data tidak ditemukan.'});
      if (cocokAlamat.group(1) == 'DELETE') {
        if (alamatDipakai.contains(id)) {
          return _json(422, {
            'message':
                'Alamat tidak dapat dihapus karena sedang digunakan pada pesanan aktif.',
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
