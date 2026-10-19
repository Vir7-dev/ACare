import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ilustrasi dari folder assets/images. Kalau file belum ditaruh,
/// tampil placeholder supaya layout tetap bisa dilihat.
class IlustrasiTeknisi extends StatelessWidget {
  final String asset;
  final double tinggi;

  const IlustrasiTeknisi({super.key, required this.asset, this.tinggi = 280});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: tinggi,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        height: tinggi,
        width: tinggi,
        decoration: const BoxDecoration(
          color: AppColors.biruMuda,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.ac_unit,
          size: 96,
          color: AppColors.biruTua,
        ),
      ),
    );
  }
}
