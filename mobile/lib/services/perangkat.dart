import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/alamat.dart';

class LokasiException implements Exception {
  final String pesan;

  const LokasiException(this.pesan);

  @override
  String toString() => pesan;
}

/// Akses fitur perangkat (GPS, telepon, galeri). Dibuat sebagai fungsi yang
/// bisa diganti supaya mudah diuji tanpa plugin native.
class Perangkat {
  static Future<bool> Function(Uri uri) bukaUrl = (uri) => launchUrl(uri);

  static Future<XFile?> Function() ambilFoto = () =>
      ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);

  static Future<String> Function() lokasiSaatIni = _lokasiAsli;

  /// Koordinat GPS perangkat, untuk menandai titik alamat di peta.
  static Future<LatLng> Function() koordinatSaatIni = _koordinatAsli;

  /// Mencari tempat di OpenStreetMap (Nominatim) berdasarkan teks.
  static Future<List<HasilTempat>> Function(String kata) cariTempat =
      _cariNominatim;

  /// Nama alamat dari koordinat (Nominatim); `null` bila tidak ditemukan.
  static Future<String?> Function(LatLng titik) alamatDariKoordinat =
      _balikNominatim;

  static void reset() {
    koordinatSaatIni = _koordinatAsli;
    cariTempat = _cariNominatim;
    alamatDariKoordinat = _balikNominatim;
    bukaUrl = (uri) => launchUrl(uri);
    ambilFoto = () =>
        ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    lokasiSaatIni = _lokasiAsli;
  }

  static const _nominatim = 'https://nominatim.openstreetmap.org';

  static Future<List<HasilTempat>> _cariNominatim(String kata) async {
    final uri = Uri.parse('$_nominatim/search').replace(
      queryParameters: {
        'format': 'jsonv2',
        'q': kata,
        'limit': '6',
        'countrycodes': 'id',
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Pencarian gagal (${res.statusCode})');
    }
    return [
      for (final e in jsonDecode(res.body) as List)
        HasilTempat(
          nama: e['display_name'] as String,
          latitude: double.parse(e['lat'] as String),
          longitude: double.parse(e['lon'] as String),
        ),
    ];
  }

  static Future<String?> _balikNominatim(LatLng titik) async {
    final uri = Uri.parse('$_nominatim/reverse').replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': '${titik.latitude}',
        'lon': '${titik.longitude}',
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final nama = (jsonDecode(res.body) as Map)['display_name'];
    return nama is String ? nama : null;
  }

  static Future<LatLng> _koordinatAsli() async {
    final p = await _posisiAsli();
    return LatLng(p.latitude, p.longitude);
  }

  static Future<Position> _posisiAsli() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LokasiException('Layanan lokasi di perangkat belum aktif');
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied ||
        izin == LocationPermission.deniedForever) {
      throw const LokasiException(
        'Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  static Future<String> _lokasiAsli() async {
    final posisi = await _posisiAsli();

    // Nama tempat dari koordinat; di web / saat gagal, tampilkan koordinat.
    try {
      final tempat = await Geocoding().placemarkFromCoordinates(
        posisi.latitude,
        posisi.longitude,
      );
      if (tempat.isNotEmpty) {
        final p = tempat.first;
        final bagian = [
          p.subLocality,
          p.locality,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).toList();
        if (bagian.isNotEmpty) return bagian.join(', ');
      }
    } catch (_) {}
    return '${posisi.latitude.toStringAsFixed(4)}, '
        '${posisi.longitude.toStringAsFixed(4)}';
  }
}

/// Membuka aplikasi telepon; memberi tahu pengguna kalau gagal.
Future<void> teleponKe(BuildContext context, String nomor) async {
  var berhasil = false;
  try {
    berhasil = await Perangkat.bukaUrl(Uri(scheme: 'tel', path: nomor));
  } catch (_) {}
  if (!berhasil && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak bisa membuka aplikasi telepon ($nomor)')),
    );
  }
}
