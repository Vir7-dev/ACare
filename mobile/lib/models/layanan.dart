import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/layanan_service.dart';
import '../theme/app_colors.dart';

class Layanan {
  /// Id di server (`layanan.id_layanan`); `null` untuk katalog bawaan.
  final int? id;
  final String nama;
  final String deskripsi;
  final int harga;
  final int durasiMenit;
  final IconData ikon;
  final Color warnaIkon;
  final Color warnaLatar;
  final bool populer;

  const Layanan({
    this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.durasiMenit,
    required this.ikon,
    required this.warnaIkon,
    required this.warnaLatar,
    this.populer = false,
  });

  /// Dari `GET /api/layanan`. Ikon dipilih aplikasi berdasarkan nama.
  factory Layanan.dariJson(Map<String, dynamic> j) {
    final nama = j['nama'] as String? ?? '';
    final bawaan = katalogBawaan.where((l) => l.nama == nama).firstOrNull;
    return Layanan(
      id: j['id'] as int?,
      nama: nama,
      deskripsi: j['deskripsi'] as String? ?? '',
      harga: (j['harga'] as num?)?.toInt() ?? 0,
      durasiMenit: (j['estimasi_durasi'] as num?)?.toInt() ?? 0,
      ikon: bawaan?.ikon ?? Icons.ac_unit,
      warnaIkon: AppColors.biru,
      warnaLatar: AppColors.biruMuda,
      populer: bawaan?.populer ?? false,
    );
  }
}

String rupiah(int nilai) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(nilai);

/// Katalog layanan yang dipakai halaman: dari server bila sudah dimuat,
/// selain itu katalog bawaan (lihat [LayananService]).
List<Layanan> get daftarLayanan => LayananService.instance.katalog.value;

/// Katalog bawaan, sama dengan LayananSeeder di backend. Dipakai sampai
/// katalog dari server termuat (atau saat tidak ada internet).
const List<Layanan> katalogBawaan = [
  Layanan(
    nama: 'Cuci AC',
    deskripsi: 'Membersihkan filter, evaporator, dan bagian dalam AC agar lebih dingin dan hemat listrik.',
    harga: 75000,
    durasiMenit: 45,
    ikon: Icons.water_drop_outlined,
    warnaIkon: AppColors.biru,
    warnaLatar: AppColors.biruMuda,
    populer: true,
  ),
  Layanan(
    nama: 'Service AC',
    deskripsi: 'Perbaikan kerusakan AC seperti tidak dingin, bocor air, bunyi berisik, atau mati total.',
    harga: 100000,
    durasiMenit: 45,
    ikon: Icons.settings_outlined,
    warnaIkon: AppColors.biru,
    warnaLatar: AppColors.biruMuda,
  ),
  Layanan(
    nama: 'Isi Freon',
    deskripsi: 'Pengisian ulang freon berkualitas untuk menjaga performa pendinginan AC tetap optimal.',
    harga: 150000,
    durasiMenit: 45,
    ikon: Icons.propane_tank_outlined,
    warnaIkon: AppColors.biru,
    warnaLatar: AppColors.biruMuda,
  ),
  Layanan(
    nama: 'Bongkar Pasang',
    deskripsi: 'Melayani pemasangan AC baru atau pemindahan dan bongkar pasang unit AC lama.',
    harga: 100000,
    durasiMenit: 45,
    ikon: Icons.build_outlined,
    warnaIkon: AppColors.biru,
    warnaLatar: AppColors.biruMuda,
  ),
  Layanan(
    nama: 'Cek AC',
    deskripsi: 'Pemeriksaan kondisi AC oleh teknisi, cocok bila kamu belum tahu masalahnya atau sekadar ingin memastikan AC dalam kondisi baik.',
    harga: 50000,
    durasiMenit: 30,
    ikon: Icons.fact_check_outlined,
    warnaIkon: AppColors.biru,
    warnaLatar: AppColors.biruMuda,
  ),
];
