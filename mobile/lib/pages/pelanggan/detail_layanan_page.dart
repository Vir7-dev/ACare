import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../theme/app_colors.dart';
import 'mencari_teknisi_page.dart';

class DetailLayananPage extends StatelessWidget {
  const DetailLayananPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lihat Detail',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEF0F4)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Layanan AC',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih layanan yang Anda butuhkan untuk menjaga AC tetap dingin dan optimal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          for (final l in daftarLayanan) ...[
            _LayananTile(layanan: l),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LayananTile extends StatelessWidget {
  final Layanan layanan;

  const _LayananTile({required this.layanan});

  void _pilih(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MencariTeknisiPage(layanan: layanan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pilih(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: layanan.warnaLatar,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(layanan.ikon, color: layanan.warnaIkon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        layanan.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (layanan.populer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Populer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppColors.biruAksen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    layanan.deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rupiah(layanan.harga),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.biruAksen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.schedule,
                        size: 12,
                        color: AppColors.teksSamar,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '± ${layanan.durasiMenit} menit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.teksSamar,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Pilih',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.biruAksen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
