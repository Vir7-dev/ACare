import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/alamat.dart';
import '../../services/alamat_service.dart';
import '../../theme/app_colors.dart';
import 'form_alamat_page.dart';

/// Daftar alamat tersimpan: tambah, ubah, hapus, dan pilih alamat yang dipakai.
class KelolaAlamatPage extends StatefulWidget {
  const KelolaAlamatPage({super.key});

  @override
  State<KelolaAlamatPage> createState() => _KelolaAlamatPageState();
}

class _KelolaAlamatPageState extends State<KelolaAlamatPage> {
  final _service = AlamatService.instance;

  @override
  void initState() {
    super.initState();
    if (!_service.termuat) _service.muat();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _bukaForm([AlamatTersimpan? awal]) async {
    final hasil = await Navigator.of(context).push<AlamatTersimpan>(
      MaterialPageRoute(builder: (_) => FormAlamatPage(awal: awal)),
    );
    if (hasil != null && mounted) _pesan('Alamat berhasil disimpan');
  }

  Future<void> _hapus(AlamatTersimpan a) async {
    if (_service.dipakaiPesananAktif(a)) {
      _pesan(
        'Alamat tidak dapat dihapus karena sedang digunakan pada pesanan aktif',
      );
      return;
    }
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text('Alamat "${a.label}" akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (ya != true) return;
    await _service.hapus(a);
    if (mounted) _pesan('Alamat dihapus');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Alamat Saya',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          if (!_service.termuat) {
            return const Center(child: CircularProgressIndicator());
          }
          final daftar = _service.daftar;
          if (daftar.isEmpty) return _kosong();
          final terpilih = _service.terpilih;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _KartuAlamat(
              alamat: daftar[i],
              dipakai: terpilih?.id == daftar[i].id,
              onPakai: () => _service.pilih(daftar[i]),
              onUbah: () => _bukaForm(daftar[i]),
              onHapus: () => _hapus(daftar[i]),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _bukaForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Alamat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.biru,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.biruMuda,
              child: Icon(
                Icons.location_off_outlined,
                size: 32,
                color: AppColors.biruAksen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada alamat tersimpan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tambahkan alamat agar pesanan servis bisa langsung memakainya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.teksSamar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuAlamat extends StatelessWidget {
  const _KartuAlamat({
    required this.alamat,
    required this.dipakai,
    required this.onPakai,
    required this.onUbah,
    required this.onHapus,
  });

  final AlamatTersimpan alamat;
  final bool dipakai;
  final VoidCallback onPakai;
  final VoidCallback onUbah;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dipakai ? AppColors.biru : const Color(0xFFE2E6EE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.biruAksen,
              ),
              const SizedBox(width: 6),
              Text(
                alamat.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (dipakai) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hijauMuda,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Dipakai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.hijau,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              alamat.alamatLengkap,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (!dipakai)
                TextButton(onPressed: onPakai, child: const Text('Pakai')),
              const Spacer(),
              IconButton(
                tooltip: 'Ubah alamat',
                onPressed: onUbah,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Hapus alamat',
                onPressed: onHapus,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.merah,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
