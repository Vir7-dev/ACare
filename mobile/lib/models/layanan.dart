import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

String rupiah(int nilai) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(nilai);

// Data dummy, nanti diganti data dari API Laravel
const List<Layanan> daftarLayanan = [
  Layanan(
    nama: 'Cuci AC',
    deskripsi:
        'Membersihkan filter, evaporator, dan bagian dalam AC agar lebih dingin dan hemat listrik.',
    harga: 75000,
    durasiMenit: 45,
    ikon: Icons.water_drop_outlined,
    warnaIkon: Color(0xFF3B82F6),
    warnaLatar: Color(0xFFEAF2FF),
    populer: true,
  ),
  Layanan(
    nama: 'Service AC',
    deskripsi:
        'Pengecekan dan perbaikan kerusakan ringan hingga berat pada sistem pendingin AC.',
    harga: 100000,
    durasiMenit: 45,
    ikon: Icons.settings_outlined,
    warnaIkon: Color(0xFF16A34A),
    warnaLatar: Color(0xFFE6F7EC),
  ),
  Layanan(
    nama: 'Isi Freon',
    deskripsi:
        'Pengisian ulang freon berkualitas untuk menjaga performa pendinginan AC tetap optimal.',
    harga: 150000,
    durasiMenit: 45,
    ikon: Icons.propane_tank_outlined,
    warnaIkon: Color(0xFFF59E0B),
    warnaLatar: Color(0xFFFFF4DF),
  ),
  Layanan(
    nama: 'Bongkar Pasang',
    deskripsi:
        'Melayani pemasangan AC baru atau pemindahan dan bongkar pasang unit AC lama.',
    harga: 100000,
    durasiMenit: 45,
    ikon: Icons.build_outlined,
    warnaIkon: Color(0xFF6366F1),
    warnaLatar: Color(0xFFEEEBFF),
  ),
  Layanan(
    nama: 'Cek AC',
    deskripsi:
        'Menangani berbagai kerusakan AC seperti tidak dingin, bocor, atau kendala kelistrikan.',
    harga: 100000,
    durasiMenit: 45,
    ikon: Icons.fact_check_outlined,
    warnaIkon: Color(0xFF3B6FD6),
    warnaLatar: Color(0xFFEAF0FF),
  ),
];
