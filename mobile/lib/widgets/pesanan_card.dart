import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/layanan.dart';
import '../models/pesanan.dart';
import '../pages/pelanggan/ajukan_refund_page.dart';
import '../pages/pelanggan/beri_ulasan_page.dart';
import '../pages/pelanggan/buat_pesanan_page.dart';
import '../services/refund_service.dart';
import '../theme/app_colors.dart';

class PesananCard extends StatelessWidget {
  final Pesanan pesanan;
  const PesananCard({super.key, required this.pesanan});

  ButtonStyle get _outlineStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.teks,
    side: const BorderSide(color: AppColors.garis),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    textStyle: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  void _detailPembatalan(BuildContext context, PengajuanRefund? refund) {
    final baris = <String>[
      pesanan.kode,
      '',
      'Alasan: ${pesanan.alasanBatal ?? '-'}',
      'Biaya awal: ${rupiah(pesanan.totalBiaya)}',
      if (refund == null)
        'Status: Dana tertahan, belum diajukan refund'
      else ...[
        'Refund ke: ${refund.namaBank} ${refund.nomorSamar} '
            'a.n ${refund.atasNama}',
        'Status: ${refund.status.label}',
      ],
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detail Pembatalan'),
        content: Text(baris.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _badge(bool selesai) {
    final warna = selesai ? AppColors.hijau : AppColors.merah;
    final bg = selesai ? AppColors.hijauMuda : AppColors.merahMuda;
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
        color: selesai ? Colors.white : AppColors.latar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.garisLembut),
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
                      style: const TextStyle(
                        color: AppColors.teksSamar,
                        fontSize: 12,
                      ),
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
                  color: selesai ? AppColors.biruMuda : AppColors.garisLembut,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selesai ? Icons.air : Icons.power_off_outlined,
                  color: selesai ? AppColors.biru : AppColors.teksSamar,
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
                        color: selesai ? Colors.black : AppColors.teks,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selesai
                          ? pesanan.detailUnit
                          : 'Alasan: ${pesanan.alasanBatal ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.teksSamar,
                        fontSize: 12,
                      ),
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
              style: TextStyle(color: AppColors.teksSamar, fontSize: 12),
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BeriUlasanPage(pesanan: pesanan),
                      ),
                    ),
                    child: const Text('Beri Ulasan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.biruMuda,
                      foregroundColor: AppColors.biru,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BuatPesananPage(
                          layanan: daftarLayanan.firstWhere(
                            (l) => pesanan.namaLayanan.contains(l.nama),
                            orElse: () => daftarLayanan.first,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Pesan Lagi'),
                  ),
                ),
              ],
            ),
          ] else
            // Pesanan dibatalkan: biaya awal tertahan sampai refund diajukan
            // dan ditransfer manual oleh Admin.
            ValueListenableBuilder<Map<String, PengajuanRefund>>(
              valueListenable: RefundService.instance.pengajuan,
              builder: (context, _, _) {
                final refund = RefundService.instance.untuk(pesanan.kode);
                final status = refund == null
                    ? 'Dana tertahan ${rupiah.format(pesanan.totalBiaya)}'
                    : 'Refund: ${refund.status.label}';
                final warna = refund?.status == StatusRefund.selesai
                    ? AppColors.hijau
                    : refund?.status == StatusRefund.ditolak
                    ? AppColors.merah
                    : AppColors.kuning;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Pembayaran',
                      style: TextStyle(
                        color: AppColors.teksSamar,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: warna,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: _outlineStyle,
                            onPressed: () => _detailPembatalan(context, refund),
                            child: const Text('Detail Pembatalan'),
                          ),
                        ),
                        if (refund == null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.biru,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AjukanRefundPage(pesanan: pesanan),
                                ),
                              ),
                              child: const Text('Ajukan Refund'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
