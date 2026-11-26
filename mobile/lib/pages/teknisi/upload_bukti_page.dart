import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import '../../models/layanan.dart';
import '../../services/api_client.dart';
import '../../services/perangkat.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';

/// Tahap akhir pekerjaan: teknisi mengunggah foto sebelum & sesudah serta
/// catatan pengerjaan, lalu menyelesaikan pesanan (UC-23).
/// Halaman ditutup dengan komisi teknisi bila pesanan diselesaikan.
class UploadBuktiPage extends StatefulWidget {
  const UploadBuktiPage({super.key});

  @override
  State<UploadBuktiPage> createState() => _UploadBuktiPageState();
}

class _UploadBuktiPageState extends State<UploadBuktiPage> {
  final _catatan = TextEditingController();
  XFile? _fotoSebelum;
  XFile? _fotoSesudah;
  final List<XFile> _fotoTambahan = [];
  bool _mengirim = false;

  String? _nama(XFile? f) =>
      f == null ? null : (f.name.isEmpty ? 'Foto terpilih' : f.name);
  String? get _sebelum => _nama(_fotoSebelum);
  String? get _sesudah => _nama(_fotoSesudah);
  List<String> get _tambahan => [for (final f in _fotoTambahan) _nama(f)!];

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<XFile?> _pilih() => Perangkat.ambilFoto();

  Future<void> _selesaikan() async {
    if (_mengirim) return;
    if (_fotoSebelum == null || _fotoSesudah == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Foto sebelum dan sesudah pengerjaan wajib diunggah'),
          ),
        );
      return;
    }
    if (_catatan.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Catatan pengerjaan wajib diisi')),
        );
      return;
    }
    setState(() => _mengirim = true);
    final int komisi;
    try {
      komisi = await TeknisiService.instance.selesaikan(
        catatan: _catatan.text.trim(),
        sebelum: _fotoSebelum!,
        sesudah: _fotoSesudah!,
        tambahan: _fotoTambahan,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.pesan)));
      return;
    }
    if (mounted) Navigator.of(context).pop(komisi);
  }

  @override
  Widget build(BuildContext context) {
    final kerja = TeknisiService.instance.pekerjaan.value;
    final total = kerja?.totalTagihan ?? 0;
    final komisi = TeknisiService.hitungKomisi(total);

    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Upload Bukti Kerja',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (kerja != null)
            _Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${kerja.pesanan.kode} • ${kerja.pesanan.layanan}',
                    style: _kecil,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kerja.pesanan.namaPelanggan,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(kerja.pesanan.unitAc, style: _kecil),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total tagihan pelanggan',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                      ),
                      Text(
                        rupiah(total),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.biruTua,
                        ),
                      ),
                    ],
                  ),
                  if (kerja.statusBiaya == StatusBiaya.disetujui)
                    Text(
                      'Pelanggan membayar pelunasan biaya perbaikan setelah '
                      'pesanan kamu selesaikan.',
                      style: _kecil,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dokumentasi Foto Unit', style: _judul),
                Text(
                  'Wajib lampirkan foto sebelum dan sesudah pengerjaan',
                  style: _kecil,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SlotFoto(
                        label: 'Sebelum',
                        nama: _sebelum,
                        onTap: () async {
                          final f = await _pilih();
                          if (f != null) setState(() => _fotoSebelum = f);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SlotFoto(
                        label: 'Sesudah',
                        nama: _sesudah,
                        onTap: () async {
                          final f = await _pilih();
                          if (f != null) setState(() => _fotoSesudah = f);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in _tambahan) Chip(label: Text(f)),
                    ActionChip(
                      avatar: const Icon(Icons.add_a_photo, size: 16),
                      label: const Text('Foto Tambahan (opsional)'),
                      onPressed: () async {
                        final f = await _pilih();
                        if (f != null && _fotoTambahan.length < 3) {
                          setState(() => _fotoTambahan.add(f));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catatan Pengerjaan', style: _judul),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatan,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan pekerjaan yang sudah dilakukan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _selesaikan,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Konfirmasi & Selesaikan Order'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Komisi ${rupiah(komisi)} masuk ke dompet setelah pembayaran '
              'pelanggan lunas.',
              style: _kecil,
            ),
          ],
        ),
      ),
    );
  }
}

final _kecil = GoogleFonts.plusJakartaSans(
  fontSize: 11,
  color: AppColors.teksSamar,
);
final _judul = GoogleFonts.plusJakartaSans(
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class _SlotFoto extends StatelessWidget {
  final String label;
  final String? nama;
  final VoidCallback onTap;

  const _SlotFoto({
    required this.label,
    required this.nama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ada = nama != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: ada ? AppColors.hijauMuda : AppColors.biruMuda,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ada ? AppColors.hijau : AppColors.garis),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ada ? Icons.check_circle : Icons.add_a_photo_outlined,
              color: ada ? AppColors.hijau : AppColors.teksSamar,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              nama ?? 'Ketuk untuk unggah',
              overflow: TextOverflow.ellipsis,
              style: _kecil,
            ),
          ],
        ),
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  final Widget child;

  const _Kartu({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
