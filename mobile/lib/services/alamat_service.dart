import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alamat.dart';
import 'order_service.dart';
import 'sesi_pengguna.dart';

/// Alamat tersimpan pelanggan (UC-08). Disimpan di perangkat dulu.
///
/// TODO(backend): ganti dengan API alamat (tabel `lokasi`, T009).
class AlamatService extends ChangeNotifier {
  AlamatService._();
  static final AlamatService instance = AlamatService._();

  static const _kDaftar = 'alamat_tersimpan';
  static const _kTerpilih = 'alamat_terpilih';

  final List<AlamatTersimpan> _daftar = [];
  String? _idTerpilih;
  bool _termuat = false;

  List<AlamatTersimpan> get daftar => List.unmodifiable(_daftar);
  bool get termuat => _termuat;

  AlamatTersimpan? get terpilih {
    for (final a in _daftar) {
      if (a.id == _idTerpilih) return a;
    }
    return null;
  }

  Future<void> muat() async {
    final p = await SharedPreferences.getInstance();
    _daftar.clear();
    try {
      final mentah = p.getString(_kDaftar);
      if (mentah != null) {
        for (final e in jsonDecode(mentah) as List) {
          _daftar.add(AlamatTersimpan.fromJson(e as Map<String, dynamic>));
        }
      }
    } catch (_) {
      _daftar.clear();
    }
    _idTerpilih = p.getString(_kTerpilih);
    _termuat = true;
    notifyListeners();
  }

  Future<void> _simpan() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kDaftar,
      jsonEncode([for (final a in _daftar) a.toJson()]),
    );
    if (_idTerpilih == null) {
      await p.remove(_kTerpilih);
    } else {
      await p.setString(_kTerpilih, _idTerpilih!);
    }
    notifyListeners();
  }

  /// Menambah alamat baru. Alamat pertama langsung dipilih.
  Future<AlamatTersimpan> tambah({
    required String label,
    required String alamatLengkap,
    required double latitude,
    required double longitude,
  }) async {
    final a = AlamatTersimpan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label.trim(),
      alamatLengkap: alamatLengkap.trim(),
      latitude: latitude,
      longitude: longitude,
    );
    _daftar.add(a);
    if (_daftar.length == 1) await pilih(a, simpan: false);
    await _simpan();
    return a;
  }

  Future<void> ubah(AlamatTersimpan a) async {
    final i = _daftar.indexWhere((e) => e.id == a.id);
    if (i < 0) return;
    _daftar[i] = a;
    if (a.id == _idTerpilih) {
      await SesiPengguna.simpanLokasi(a.alamatLengkap);
    }
    await _simpan();
  }

  /// Alamat yang sedang dipakai pesanan aktif tidak boleh dihapus.
  bool dipakaiPesananAktif(AlamatTersimpan a) {
    final p = OrderService.instance.pesananAktif.value;
    if (p == null || !p.aktif) return false;
    return p.alamat == a.alamatLengkap;
  }

  Future<void> hapus(AlamatTersimpan a) async {
    _daftar.removeWhere((e) => e.id == a.id);
    if (_idTerpilih == a.id) {
      _idTerpilih = _daftar.isEmpty ? null : _daftar.first.id;
      final baru = terpilih;
      if (baru != null) {
        await SesiPengguna.simpanLokasi(baru.alamatLengkap);
      }
    }
    await _simpan();
  }

  Future<void> pilih(AlamatTersimpan a, {bool simpan = true}) async {
    _idTerpilih = a.id;
    await SesiPengguna.simpanLokasi(a.alamatLengkap);
    if (simpan) await _simpan();
  }

  /// Kosongkan semua data (dipakai test).
  @visibleForTesting
  void reset() {
    _daftar.clear();
    _idTerpilih = null;
    _termuat = false;
  }
}
