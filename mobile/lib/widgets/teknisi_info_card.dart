import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/teknisi.dart';
import '../theme/app_colors.dart';

/// Profil teknisi + tombol Pesan / Telepon.
class TeknisiInfoCard extends StatelessWidget {
  final Teknisi teknisi;
  final VoidCallback onPesan;
  final VoidCallback onTelepon;

  const TeknisiInfoCard({
    super.key,
    required this.teknisi,
    required this.onPesan,
    required this.onTelepon,
  });

  @override
  Widget build(BuildContext context) {
    final kecil = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      color: AppColors.teksSamar,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFD9DDE3),
              child: Icon(Icons.person, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teknisi.nama,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        teknisi.rating,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11),
                      ),
                      Text('  (${teknisi.jumlahUlasan} ulasan)', style: kecil),
                    ],
                  ),
                  if (teknisi.terverifikasi) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.hijauMuda,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 11,
                            color: AppColors.hijau,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Teknisi Terverifikasi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: AppColors.hijau,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.two_wheeler, size: 18, color: AppColors.teksSamar),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kendaraan : ${teknisi.kendaraan}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'BP : ${teknisi.plat}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          teknisi.testimoni,
          style: GoogleFonts.plusJakartaSans(fontSize: 10.5),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPesan,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Pesan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.biru,
                  side: const BorderSide(color: AppColors.biru),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onTelepon,
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('Telepon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.biru,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
