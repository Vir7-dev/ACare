import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class Layanan {
  final String nama;
  final String deskripsi;
  final int harga;
  final int durasiMenit;
  final IconData ikon;
  final Color warnaIkon;
  final Color warnaLatar;
  final bool populer;

  const Layanan({
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.durasiMenit,
    required this.ikon,
    required this.warnaIkon,
    required this.warnaLatar,
    this.populer = false,
  });
}

String rupiah(int nilai) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(nilai);

// Data dummy, nanti diganti data dari API Laravel
const List<Layanan> daftarLayanan = [
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
