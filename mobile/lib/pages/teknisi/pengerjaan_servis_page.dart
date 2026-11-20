import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/layanan.dart';
import '../../services/perangkat.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/peta_lokasi.dart';
import 'input_biaya_page.dart';
import 'upload_bukti_page.dart';

/// Halaman kerja teknisi untuk pesanan yang diterima: menuju lokasi, tiba,
/// pengecekan (lalu ajukan biaya bila perlu), perbaikan, dan selesai.
class PengerjaanServisPage extends StatelessWidget {
  const PengerjaanServisPage({super.key});

  TeknisiService get _layanan => TeknisiService.instance;

  Future<void> _ambilFoto(BuildContext context) async {
    final berkas = await Perangkat.ambilFoto();
    if (berkas == null) return;
    _layanan.tambahFotoPemeriksaan(
      berkas.name.isEmpty ? 'Foto pemeriksaan' : berkas.name,
    );
  }

  Future<void> _inputBiaya(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const InputBiayaPage()));
  }

  Future<void> _uploadBukti(BuildContext context) async {
    final komisi = await Navigator.of(context)
        .push<int>(MaterialPageRoute(builder: (_) => const UploadBuktiPage()));
    if (komisi == null || !context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Pesanan selesai. ${rupiah(komisi)} masuk ke dompet.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PekerjaanTeknisi?>(
      valueListenable: _layanan.pekerjaan,
      builder: (context, kerja, _) {
        if (kerja == null) {
          return const Scaffold(
            body: Center(child: Text('Tidak ada pesanan berjalan')),
          );
        }
        final p = kerja.pesanan;

        return Scaffold(
          backgroundColor: AppColors.latar,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            // Tanpa tombol kembali: fokus ke pekerjaan. Beranda tetap bisa
            // dibuka lewat tombol kembali perangkat dan pengerjaan dilanjutkan
            // dari kartu "Pesanan Berjalan".
            automaticallyImplyLeading: false,
            title: Text(
              'Pengerjaan Servis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(
                height: 170,
                child: PetaLokasi(
                  posisiTeknisi: LatLng(1.1350, 104.0450),
                  posisiPelanggan: LatLng(1.1283, 104.0530),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nomor Tiket Servis', style: _kecil),
                              Text(
                                '#${p.kode}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Chip(p.layanan),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _KartuPutih(
                      judul: 'Status Pelaksanaan Kerja',
                      child: _GarisTahap(kerja: kerja),
                    ),
                    const SizedBox(height: 12),
                    _KartuPutih(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.biruMuda,
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.biruTua,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.namaPelanggan,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(p.unitAc, style: _kecil),
                                  ],
                                ),
                              ),
                              IconButton.filled(
                                tooltip: 'Telepon pelanggan',
                                onPressed: () =>
                                    teleponKe(context, p.teleponPelanggan),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.hijau,
                                ),
                                icon: const Icon(Icons.call, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.alamat,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (p.catatan.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.biruMuda,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Keluhan utama: "${p.catatan}"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (kerja.tahap == TahapPekerjaan.pengecekan) ...[
                      const SizedBox(height: 12),
                      _KartuPutih(
                        judul: 'Foto Bukti Pemeriksaan',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in kerja.fotoPemeriksaan)
                              Chip(
                                avatar: const Icon(Icons.image, size: 16),
                                label: Text(f),
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.add_a_photo, size: 16),
                              label: const Text('Ambil Foto'),
                              onPressed: () => _ambilFoto(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (kerja.statusBiaya != StatusBiaya.belumDiajukan) ...[
                      const SizedBox(height: 12),
                      _KartuBiaya(kerja: kerja),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _TombolTahap(
              kerja: kerja,
              onLanjut: _layanan.lanjutTahap,
              onInputBiaya: () => _inputBiaya(context),
              onTanpaBiaya: _layanan.lanjutTanpaBiayaTambahan,
              onUploadBukti: () => _uploadBukti(context),
            ),
          ),
        );
      },
    );
  }
}

final _kecil = GoogleFonts.plusJakartaSans(
  fontSize: 11,
  color: AppColors.teksSamar,
);

/// Garis 5 tahap: Menuju, Tiba, Pengecekan, Perbaikan, Selesai.
class _GarisTahap extends StatelessWidget {
  final PekerjaanTeknisi kerja;

  const _GarisTahap({required this.kerja});

  @override
  Widget build(BuildContext context) {
    final tahap = TahapPekerjaan.values;
    final aktif = kerja.tahap.index;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tahap.length; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: i < aktif
                        ? AppColors.hijau
                        : i == aktif
                        ? AppColors.biruTua
                        : AppColors.garisLembut,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i < aktif ? Icons.check : _ikon[i],
                    size: 15,
                    color: i <= aktif ? Colors.white : AppColors.teksSamar,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tahap[i].label,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: i == aktif
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i <= aktif ? Colors.black87 : AppColors.teksSamar,
                    ),
                  ),
                ),
                if (kerja.waktu[tahap[i]] case final w?)
                  Text(
                    '${w.hour.toString().padLeft(2, '0')}:'
                    '${w.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.hijau,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static const _ikon = [
    Icons.two_wheeler,
    Icons.place,
    Icons.search,
    Icons.build,
    Icons.verified,
  ];
}

class _KartuBiaya extends StatelessWidget {
  final PekerjaanTeknisi kerja;

  const _KartuBiaya({required this.kerja});

  @override
  Widget build(BuildContext context) {
    final menunggu = kerja.statusBiaya == StatusBiaya.menunggu;
    return _KartuPutih(
      judul: 'Rincian Biaya Perbaikan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in kerja.itemBiaya)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i.nama,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                  Text(
                    rupiah(i.harga),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              if (menunggu)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.hijau,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  menunggu
                      ? 'Menunggu persetujuan pelanggan'
                      : 'Disetujui pelanggan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: menunggu ? Colors.black87 : AppColors.hijau,
                  ),
                ),
              ),
              Text(
                rupiah(kerja.totalBiayaPerbaikan),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TombolTahap extends StatelessWidget {
  final PekerjaanTeknisi kerja;
  final VoidCallback onLanjut;
  final VoidCallback onInputBiaya;
  final VoidCallback onTanpaBiaya;
  final VoidCallback onUploadBukti;

  const _TombolTahap({
    required this.kerja,
    required this.onLanjut,
    required this.onInputBiaya,
    required this.onTanpaBiaya,
    required this.onUploadBukti,
  });

  @override
  Widget build(BuildContext context) {
    switch (kerja.tahap) {
      case TahapPekerjaan.menuju:
        return _utama('Saya Sudah Tiba', Icons.place, onLanjut);
      case TahapPekerjaan.tiba:
        return _utama('Mulai Pengecekan', Icons.search, onLanjut);
      case TahapPekerjaan.pengecekan:
        if (kerja.statusBiaya == StatusBiaya.menunggu) {
          return _utama('Menunggu persetujuan pelanggan...', null, null);
        }
        if (!kerja.pesanan.bisaBiayaTambahan) {
          return _utama(
            'Selesai Cek & Mulai Kerjakan',
            Icons.build,
            onTanpaBiaya,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _utama('Input Biaya Perbaikan', Icons.receipt_long, onInputBiaya),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onTanpaBiaya,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.biru,
                  side: const BorderSide(color: AppColors.biru),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Lanjut Tanpa Biaya Tambahan'),
              ),
            ),
          ],
        );
      case TahapPekerjaan.perbaikan:
        return _utama(
          'Selesai & Upload Bukti Kerja',
          Icons.photo_camera,
          onUploadBukti,
        );
      case TahapPekerjaan.selesai:
        return const SizedBox.shrink();
    }
  }

  Widget _utama(String teks, IconData? ikon, VoidCallback? aksi) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: aksi,
        icon: ikon == null ? const SizedBox.shrink() : Icon(ikon, size: 18),
        label: Text(teks),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.biru,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _KartuPutih extends StatelessWidget {
  final String? judul;
  final Widget child;

  const _KartuPutih({this.judul, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (judul != null) ...[
            Text(
              judul!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String teks;

  const _Chip(this.teks);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.biruMuda,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.biruTua,
        ),
      ),
    );
  }
}
