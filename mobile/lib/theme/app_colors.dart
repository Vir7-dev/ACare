import 'package:flutter/material.dart';

/// Palet warna tunggal ACare. Semua layar mengambil warna dari sini;
/// jangan menulis kode warna (`Color(0x...)`) langsung di halaman.
///
/// Warna teks sudah diuji kontras WCAG AA (minimal 4,5:1) di atas putih
/// dan [latar]: [biru] 5,3:1, [biruTua] 6,8:1, [teksSamar] 5,4:1,
/// [hijau] 5,0:1, [merah] 4,8:1, [kuning] 5,0:1.
class AppColors {
  AppColors._();

  // Warna utama (merek).
  /// Tombol utama, tautan, ikon aktif, elemen terpilih.
  static const biru = Color(0xFF0B6FB5);

  /// Penekanan: nominal penting, judul berwarna, ujung gradien.
  static const biruTua = Color(0xFF0A5E9C);

  /// Latar lembut untuk kartu terpilih, info, avatar, chip.
  static const biruMuda = Color(0xFFE8F1FB);

  /// Garis tepi berwarna biru (kolom isian, kartu bergaris biru).
  static const biruGaris = Color(0xFFA8CDEB);

  // Netral.
  static const latar = Color(0xFFF5F7FA);
  static const teks = Color(0xFF1F2937);

  /// Teks keterangan / sekunder.
  static const teksSamar = Color(0xFF646B76);

  /// Hanya untuk elemen nonaktif dan ikon dekoratif, bukan teks penting.
  static const teksNonaktif = Color(0xFF9AA1AB);

  /// Garis tepi kartu dan kolom netral.
  static const garis = Color(0xFFD5DAE1);

  /// Pemisah, latar elemen nonaktif, isian abu-abu.
  static const garisLembut = Color(0xFFE6EAF0);

  // Status.
  static const hijau = Color(0xFF15803D);
  static const hijauMuda = Color(0xFFE3F6E9);
  static const merah = Color(0xFFDC2626);
  static const merahMuda = Color(0xFFFDE3E3);
  static const kuning = Color(0xFFB45309);
  static const kuningMuda = Color(0xFFFFF4DF);
  static const kuningGaris = Color(0xFFF3D9A4);

  /// Bintang rating (ikon, bukan teks).
  static const bintang = Color(0xFFF5B301);

  // Gradien kartu/latar biru.
  static const gradienAtas = biru;
  static const gradienBawah = biruTua;
}
