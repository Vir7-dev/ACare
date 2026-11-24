import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Ilustrasi ACare (dari desain Figma) untuk layar/bagian yang masih kosong.
const ilustrasiKosong = 'assets/images/splash_2.png';

/// Keadaan kosong: ilustrasi, judul, dan keterangan singkat.
/// [ringkas] = versi mendatar untuk dipakai di dalam kartu.
class KeadaanKosong extends StatelessWidget {
  final String judul;
  final String keterangan;
  final bool ringkas;

  const KeadaanKosong({
    super.key,
    required this.judul,
    required this.keterangan,
    this.ringkas = false,
  });

  Widget _gambar(double tinggi) => Image.asset(
    ilustrasiKosong,
    height: tinggi,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => SizedBox(
      height: tinggi,
      child: const Icon(Icons.ac_unit, size: 48, color: AppColors.biru),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final gayaJudul = GoogleFonts.plusJakartaSans(
      fontSize: ringkas ? 13 : 16,
      fontWeight: FontWeight.w700,
      color: AppColors.teks,
    );
    final gayaKet = GoogleFonts.plusJakartaSans(
      fontSize: ringkas ? 12 : 13,
      color: AppColors.teksSamar,
    );

    if (ringkas) {
      return Row(
        children: [
          _gambar(72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: gayaJudul),
                const SizedBox(height: 2),
                Text(keterangan, style: gayaKet),
              ],
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _gambar(160),
            const SizedBox(height: 16),
            Text(judul, style: gayaJudul, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(keterangan, style: gayaKet, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
