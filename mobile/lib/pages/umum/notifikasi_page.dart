import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/notifikasi_service.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../theme/app_colors.dart';

/// Daftar notifikasi pesanan, pembayaran, refund, dan sistem (UC-05).
class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  static IconData _ikon(TipeNotifikasi t) => switch (t) {
    TipeNotifikasi.pesanan => Icons.receipt_long_outlined,
    TipeNotifikasi.pembayaran => Icons.payments_outlined,
    TipeNotifikasi.refund => Icons.currency_exchange,
    TipeNotifikasi.sistem => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final layanan = NotifikasiService.instance;
    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: layanan.tandaiSemuaDibaca,
            child: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Notifikasi>>(
        valueListenable: layanan.daftar,
        builder: (context, daftar, _) {
          if (daftar.isEmpty) {
            return const KeadaanKosong(
              judul: 'Belum ada notifikasi',
              keterangan:
                  'Kabar pesanan, pembayaran, dan refund akan muncul di sini.',
            );
          }
          return ListView.separated(
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = daftar[i];
              return ListTile(
                tileColor: n.dibaca ? Colors.white : AppColors.biruMuda,
                leading: CircleAvatar(
                  backgroundColor: AppColors.biruMuda,
                  child: Icon(_ikon(n.tipe), color: AppColors.biruTua),
                ),
                title: Text(
                  n.judul,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: n.dibaca ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${n.isi}\n'
                  '${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(n.waktu)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11),
                ),
                isThreeLine: true,
                trailing: n.dibaca
                    ? null
                    : const Icon(Icons.circle, size: 9, color: AppColors.merah),
                onTap: () => layanan.tandaiDibaca(n.id),
              );
            },
          );
        },
      ),
    );
  }
}
