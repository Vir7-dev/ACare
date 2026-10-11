import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/pesanan.dart';

class PesananCard extends StatelessWidget {
  final Pesanan pesanan;
  const PesananCard({super.key, required this.pesanan});

  static const _biru = Color(0xFF0B6E99);
  static const _biruMuda = Color(0xFFDDEBF6);
  static const _hijau = Color(0xFF1E9E5A);
  static const _merah = Color(0xFFD93A3A);
  static const _abu = Color(0xFF5A606A);

  ButtonStyle get _outlineStyle => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF2B2F36),
    side: const BorderSide(color: Color(0xFFD5D9DE)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    textStyle: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _badge(bool selesai) {
    final warna = selesai ? _hijau : _merah;
    final bg = selesai ? const Color(0xFFDDF5E6) : const Color(0xFFFDE3E3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        selesai ? 'Selesai' : 'Dibatalkan',
        style: TextStyle(
          color: warna,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selesai = pesanan.status == StatusPesanan.selesai;
    final tanggal = DateFormat(
      'd MMM yyyy, HH:mm',
      'id_ID',
    ).format(pesanan.tanggal);
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selesai ? Colors.white : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: kode, tanggal, badge status (tanpa ikon)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.kode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '$tanggal WIB',
                      style: const TextStyle(color: _abu, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _badge(selesai),
            ],
          ),
          const Divider(height: 24),

          // Layanan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selesai ? _biruMuda : const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selesai ? Icons.air : Icons.power_off_outlined,
                  color: selesai ? _biru : _abu,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.namaLayanan,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: selesai ? Colors.black : const Color(0xFF3A3F47),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selesai
                          ? pesanan.detailUnit
                          : 'Alasan: ${pesanan.alasanBatal ?? '-'}',
                      style: const TextStyle(color: _abu, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bagian bawah
          if (selesai) ...[
            const Text(
              'Total Selesai',
              style: TextStyle(color: _abu, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              rupiah.format(pesanan.totalBiaya),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: _outlineStyle,
                    onPressed: () {
                      // TODO: halaman Rating/Ulasan
                    },
                    child: const Text('Beri Ulasan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _biruMuda,
                      foregroundColor: _biru,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // TODO: halaman Memesan Layanan (Pesan Lagi)
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Pesan Lagi'),
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Pembayaran',
                        style: TextStyle(color: _abu, fontSize: 12),
                      ),
                      Text(
                        pesanan.statusPembayaran ?? '-',
                        style: const TextStyle(
                          color: _hijau,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: _outlineStyle,
                  onPressed: () {
                    // TODO: halaman Detail Pembatalan
                  },
                  child: const Text('Detail Pembatalan'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}