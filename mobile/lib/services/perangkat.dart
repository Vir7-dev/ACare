import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static void reset() {
    bukaUrl = (uri) => launchUrl(uri);
    ambilFoto = () =>
        ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    lokasiSaatIni = _lokasiAsli;
  }

  static Future<String> _lokasiAsli() async {
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

    final posisi = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

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
