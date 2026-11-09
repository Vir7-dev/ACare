import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Elemen tampilan bersama untuk halaman teknisi. Warna dan font mengikuti
/// pelanggan ([AppColors], Plus Jakarta Sans); tata letaknya sendiri.
const Color garisKartu = Color(0xFFE5E7EB);
const Color garisIkon = Color(0xFFE2E6EE);

TextStyle gayaJudul({double ukuran = 14}) =>
    GoogleFonts.plusJakartaSans(fontSize: ukuran, fontWeight: FontWeight.w700);

TextStyle gayaSamar({double ukuran = 12}) =>
    GoogleFonts.plusJakartaSans(fontSize: ukuran, color: Colors.black54);

PreferredSizeWidget appBarTeknisi(
  String judul, {
  bool tampilkanKembali = true,
  List<Widget>? aksi,
  PreferredSizeWidget? bawah,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: tampilkanKembali,
    title: Text(judul, style: gayaJudul(ukuran: 16)),
    actions: aksi,
    bottom: bawah,
  );
}

/// Kartu putih seperti kartu di beranda pelanggan.
class KartuTeknisi extends StatelessWidget {
  const KartuTeknisi({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isi = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: garisKartu),
      ),
      child: child,
    );
    if (onTap == null) return isi;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: isi,
    );
  }
}

/// Tombol utama biru, sama dengan tombol aksi di alur pesanan pelanggan.
class TombolUtama extends StatelessWidget {
  const TombolUtama(
    this.teks,
    this.onPressed, {
    super.key,
    this.ikon,
    this.warna = AppColors.biru,
  });

  final String teks;
  final VoidCallback? onPressed;
  final IconData? ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final gaya = ElevatedButton.styleFrom(
      backgroundColor: warna,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    if (ikon == null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: gaya,
        child: Text(teks),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      iconAlignment: IconAlignment.end,
      icon: Icon(ikon, size: 18),
      label: Text(teks),
      style: gaya,
    );
  }
}

/// Tombol sekunder berbingkai.
class TombolSekunder extends StatelessWidget {
  const TombolSekunder(this.teks, this.onPressed, {super.key});

  final String teks;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: garisIkon),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(teks),
    );
  }
}

/// Bilah tombol di bawah layar (putih, garis atas tipis).
class BilahBawah extends StatelessWidget {
  const BilahBawah({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: garisKartu)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

/// Label status kecil berwarna, seperti "Menuju Lokasi" di pelanggan.
class ChipStatus extends StatelessWidget {
  const ChipStatus(
    this.teks, {
    super.key,
    this.warna = AppColors.hijau,
    this.latar = AppColors.hijauMuda,
  });

  final String teks;
  final Color warna;
  final Color latar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        teks,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          color: warna,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Baris "label ... nilai" untuk ringkasan biaya.
class BarisNilai extends StatelessWidget {
  const BarisNilai(
    this.label,
    this.nilai, {
    super.key,
    this.tebal = false,
    this.samar = false,
  });

  final String label;
  final String nilai;
  final bool tebal;
  final bool samar;

  @override
  Widget build(BuildContext context) {
    final gaya = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
      color: samar ? Colors.black54 : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: gaya)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(nilai, textAlign: TextAlign.right, style: gaya),
          ),
        ],
      ),
    );
  }
}
