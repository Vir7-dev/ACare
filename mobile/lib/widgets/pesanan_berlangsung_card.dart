import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class PesananBerlangsungCard extends StatelessWidget {
  final String namaTeknisi;
  final String rating;
  final int jumlahUlasan;
  final String kendaraan;
  final String estimasi;
  final VoidCallback? onTap;
  final VoidCallback? onChat;
  final VoidCallback? onTelepon;
  final VoidCallback? onLacakPeta;

  const PesananBerlangsungCard({
    super.key,
    required this.namaTeknisi,
    required this.rating,
    required this.jumlahUlasan,
    required this.kendaraan,
    required this.estimasi,
    this.onTap,
    this.onChat,
    this.onTelepon,
    this.onLacakPeta,
  });

  @override
  Widget build(BuildContext context) {
    final kecil = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      color: AppColors.teksSamar,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.biruMuda,
                      child: Icon(Icons.person, color: AppColors.biruTua),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.hijau,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            namaTeknisi,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Mitra Pro',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: AppColors.biruAksen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11),
                          ),
                          Text('  •  ($jumlahUlasan ulasan)', style: kecil),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.two_wheeler,
                            size: 13,
                            color: AppColors.teksSamar,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              kendaraan,
                              style: kecil,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _AksiBulat(
                  ikon: Icons.chat_bubble_outline,
                  warna: AppColors.biruAksen,
                  latar: const Color(0xFFEAF0FF),
                  onTap: onChat ?? () {},
                ),
                const SizedBox(width: 8),
                _AksiBulat(
                  ikon: Icons.phone_outlined,
                  warna: AppColors.hijau,
                  latar: AppColors.hijauMuda,
                  onTap: onTelepon ?? () {},
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEEF0F4)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    style: kecil,
                    children: [
                      const TextSpan(text: 'Estimasi tiba: '),
                      TextSpan(
                        text: estimasi,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onLacakPeta,
                  child: Row(
                    children: [
                      Text(
                        'Lacak Peta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.biruAksen,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.biruAksen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AksiBulat extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final Color latar;
  final VoidCallback onTap;

  const _AksiBulat({
    required this.ikon,
    required this.warna,
    required this.latar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: latar, shape: BoxShape.circle),
        child: Icon(ikon, size: 18, color: warna),
      ),
    );
  }
}
