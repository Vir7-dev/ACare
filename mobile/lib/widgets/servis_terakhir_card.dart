import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class ServisTerakhirCard extends StatelessWidget {
  final String layanan;
  final String tanggal;
  final String pesan;
  final VoidCallback onJadwalkanUlang;

  const ServisTerakhirCard({
    super.key,
    required this.layanan,
    required this.tanggal,
    required this.pesan,
    required this.onJadwalkanUlang,
  });

  @override
  Widget build(BuildContext context) {
    final putih = GoogleFonts.plusJakartaSans(color: Colors.white);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradienAtas, AppColors.gradienBawah],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D5BBF),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SERVIS TERAKHIR',
                    style: putih.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    layanan,
                    style: putih.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tanggal, style: putih.copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pesan,
                  style: putih.copyWith(fontSize: 11, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onJadwalkanUlang,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text('Jadwalkan ulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.biruAksen,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
