import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/alamat_service.dart';
import '../../theme/app_colors.dart';
import 'form_alamat_page.dart';

/// Daftar alamat tersimpan pelanggan: tambah, ubah, hapus (UC-08).
///
/// Bila [modePilih] aktif, mengetuk alamat menutup halaman dan
/// mengembalikan [AlamatTersimpan] yang dipilih.
class KelolaAlamatPage extends StatelessWidget {
  final bool modePilih;

  const KelolaAlamatPage({super.key, this.modePilih = false});

  Future<void> _tambah(BuildContext context) async {
    final baru = await Navigator.of(context).push<AlamatTersimpan>(
      MaterialPageRoute(builder: (_) => const FormAlamatPage()),
    );
    if (baru != null && modePilih && context.mounted) {
      Navigator.of(context).pop(baru);
    }
  }

  Future<void> _hapus(BuildContext context, AlamatTersimpan a) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text('"${a.label}" akan dihapus dari alamat tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya != true || !context.mounted) return;
    final galat = AlamatService.instance.hapus(a);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(galat ?? 'Alamat dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          modePilih ? 'Pilih Alamat' : 'Alamat Tersimpan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<AlamatTersimpan>>(
        valueListenable: AlamatService.instance.daftar,
        builder: (context, daftar, _) {
          if (daftar.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 48,
                      color: AppColors.teksSamar,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada alamat tersimpan',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _tambah(context),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Tambah Alamat'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final a in daftar)
                Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  child: ListTile(
                    onTap: modePilih
                        ? () => Navigator.of(context).pop(a)
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FormAlamatPage(alamat: a),
                            ),
                          ),
                    leading: Icon(switch (a.label) {
                      'Rumah' => Icons.home_outlined,
                      'Kantor' => Icons.business_outlined,
                      _ => Icons.location_on_outlined,
                    }, color: AppColors.biruTua),
                    title: Text(
                      a.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      a.alamatLengkap,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11),
                    ),
                    trailing: modePilih
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            tooltip: 'Hapus alamat',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.merah,
                            ),
                            onPressed: () => _hapus(context, a),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tambah(context),
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Tambah Alamat'),
      ),
    );
  }
}
