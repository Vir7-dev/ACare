import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/pesanan_teknisi.dart';
import '../../services/perangkat.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';

/// Langkah terakhir: foto sebelum dan sesudah, catatan pengerjaan, lalu order
/// selesai.
class UploadBuktiPage extends StatefulWidget {
  const UploadBuktiPage({super.key});

  @override
  State<UploadBuktiPage> createState() => _UploadBuktiPageState();
}

class _UploadBuktiPageState extends State<UploadBuktiPage> {
  static const _maksTambahan = 2;

  final _service = TeknisiService.instance;
  final _ringkasan = TextEditingController();
  String? _sebelum;
  String? _sesudah;
  final List<String> _tambahan = [];
  bool _dicoba = false;

  @override
  void dispose() {
    _ringkasan.dispose();
    super.dispose();
  }

  Future<String?> _ambil() async {
    try {
      final f = await Perangkat.ambilFoto();
      return f?.path;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto tidak bisa diambil.')),
        );
      }
      return null;
    }
  }

  Future<void> _isiSebelum() async {
    final f = await _ambil();
    if (f != null && mounted) setState(() => _sebelum = f);
  }

  Future<void> _isiSesudah() async {
    final f = await _ambil();
    if (f != null && mounted) setState(() => _sesudah = f);
  }

  Future<void> _tambahFoto() async {
    final f = await _ambil();
    if (f != null && mounted) setState(() => _tambahan.add(f));
  }

  void _selesai() {
    setState(() => _dicoba = true);
    if (_sebelum == null ||
        _sesudah == null ||
        _ringkasan.text.trim().isEmpty) {
      return;
    }
    final p = _service.pesananAktif;
    if (p == null) return;
    final bersih = p.pendapatanBersih;
    _service.selesaikanOrder(
      ringkasan: _ringkasan.text,
      jumlahFoto: 2 + _tambahan.length,
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order selesai. ${rupiah(bersih)} masuk ke dompet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _service.pesananAktif;
    if (p == null) return const Scaffold();
    final salahFoto = _dicoba && (_sebelum == null || _sesudah == null);
    final salahRingkasan = _dicoba && _ringkasan.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      appBar: appBarTeknisi('Upload bukti kerja'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _KartuProgres(),
          const SizedBox(height: 12),
          _KartuOrder(pesanan: p),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dokumentasi foto fisik unit', style: gayaJudul()),
                Text(
                  'Wajib lampirkan foto sebelum dan sesudah pengerjaan',
                  style: gayaSamar(ukuran: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SlotBukti(
                        label: 'Sebelum',
                        path: _sebelum,
                        onTap: _isiSebelum,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SlotBukti(
                        label: 'Sesudah',
                        path: _sesudah,
                        onTap: _isiSesudah,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _tambahan.length; i++)
                      SizedBox(
                        width: 100,
                        child: _SlotBukti(
                          label: 'Tambahan ${i + 1}',
                          path: _tambahan[i],
                          onTap: () {},
                          onHapus: () => setState(() => _tambahan.removeAt(i)),
                        ),
                      ),
                    if (_tambahan.length < _maksTambahan)
                      SizedBox(
                        width: 100,
                        child: _SlotBukti(
                          label: '+ Foto tambahan',
                          keterangan: 'Opsional',
                          path: null,
                          onTap: _tambahFoto,
                        ),
                      ),
                  ],
                ),
                if (salahFoto)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Foto sebelum dan sesudah wajib diunggah.',
                      style: TextStyle(fontSize: 12, color: AppColors.merah),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catatan pengerjaan teknisi', style: gayaJudul()),
                const SizedBox(height: 8),
                TextField(
                  controller: _ringkasan,
                  maxLines: 5,
                  onChanged: (_) {
                    if (_dicoba) setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Apa yang dikerjakan dan bagaimana kondisi unit '
                        'sekarang',
                    errorText: salahRingkasan ? 'Catatan wajib diisi' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BilahBawah(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TombolUtama(
              'Konfirmasi & selesaikan order',
              _selesai,
              ikon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: gayaSamar(ukuran: 11),
                children: [
                  const TextSpan(text: 'Komisi teknisi '),
                  TextSpan(
                    text: rupiah(p.pendapatanBersih),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.hijau,
                    ),
                  ),
                  const TextSpan(
                    text: ' langsung masuk dompet setelah dikonfirmasi.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progres 4 tahap; semua selesai kecuali unggah bukti.
class _KartuProgres extends StatelessWidget {
  const _KartuProgres();

  static const _nama = ['Menuju lokasi', 'Cek awal', 'Perbaikan', 'Upload bukti'];

  @override
  Widget build(BuildContext context) {
    return KartuTeknisi(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Progres servis unit', style: gayaJudul(ukuran: 13)),
                ),
                const ChipStatus(
                  'Tahap 4 dari 4 (akhir)',
                  warna: AppColors.biruAksen,
                  latar: Color(0xFFE0ECFF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i == 0
                                  ? Colors.transparent
                                  : AppColors.biruAksen,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.biruAksen,
                            ),
                            child: Icon(
                              i < 3 ? Icons.check : Icons.upload_outlined,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _nama[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: i == 3
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: i == 3 ? AppColors.biruAksen : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KartuOrder extends StatelessWidget {
  const _KartuOrder({required this.pesanan});

  final PesananTeknisi pesanan;

  @override
  Widget build(BuildContext context) {
    final paket = pesanan.itemBiaya.isEmpty
        ? pesanan.layanan
        : pesanan.itemBiaya.map((i) => i.nama).join(', ');
    return KartuTeknisi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChipStatus(
                      pesanan.unitAc,
                      warna: AppColors.biruAksen,
                      latar: const Color(0xFFE0ECFF),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pesanan.pelanggan,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${pesanan.wilayah}, ${pesanan.alamat}',
                            style: gayaSamar(ukuran: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total tagihan', style: gayaSamar(ukuran: 11)),
                  Text(
                    rupiah(pesanan.totalTagihan),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.biruAksen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // TODO(backend): status pembayaran dari aplikasi pelanggan.
                  const ChipStatus('Lunas (non-tunai)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.latarBeranda,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppColors.biruAksen,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paket servis', style: gayaJudul(ukuran: 13)),
                      Text(
                        paket,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: gayaSamar(ukuran: 11),
                      ),
                    ],
                  ),
                ),
                Text('1 unit', style: gayaSamar(ukuran: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotBukti extends StatelessWidget {
  const _SlotBukti({
    required this.label,
    required this.path,
    required this.onTap,
    this.keterangan,
    this.onHapus,
  });

  final String label;
  final String? keterangan;
  final String? path;
  final VoidCallback onTap;
  final VoidCallback? onHapus;

  @override
  Widget build(BuildContext context) {
    final terisi = path != null;
    return InkWell(
      onTap: terisi ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.latarBeranda,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.biruMuda),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (terisi)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(path!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.image),
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.biruAksen,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.biruAksen,
                      ),
                    ),
                    if (keterangan != null)
                      Text(keterangan!, style: gayaSamar(ukuran: 9)),
                  ],
                ),
              if (terisi)
                Positioned(
                  left: 6,
                  top: 6,
                  child: ChipStatus(
                    label,
                    warna: Colors.white,
                    latar: Colors.black54,
                  ),
                ),
              if (terisi && onHapus != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: InkWell(
                    onTap: onHapus,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
