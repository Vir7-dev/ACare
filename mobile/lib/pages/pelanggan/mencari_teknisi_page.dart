import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/teknisi.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ilustrasi_teknisi.dart';
import 'tracking_teknisi_page.dart';

class MencariTeknisiPage extends StatefulWidget {
  final Layanan layanan;

  /// Lama simulasi pencarian sebelum teknisi "ditemukan".
  final Duration lamaCari;

  const MencariTeknisiPage({
    super.key,
    required this.layanan,
    this.lamaCari = const Duration(seconds: 5),
  });

  @override
  State<MencariTeknisiPage> createState() => _MencariTeknisiPageState();
}

class _MencariTeknisiPageState extends State<MencariTeknisiPage> {
  Timer? _timer;
  bool _dialogTerbuka = false;
  String _lokasi = 'Perumahan Batu aji, Batam';

  Layanan get layanan => widget.layanan;

  @override
  void initState() {
    super.initState();
    // TODO: ganti simulasi ini dengan hasil pencarian dari API
    _timer = Timer(widget.lamaCari, _teknisiDitemukan);
    SesiPengguna.lokasi().then((l) {
      if (mounted && l != null) setState(() => _lokasi = l);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _teknisiDitemukan() {
    if (!mounted) return;
    if (_dialogTerbuka) {
      _timer = Timer(const Duration(seconds: 1), _teknisiDitemukan);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const TrackingTeknisiPage(teknisi: teknisiDummy),
      ),
    );
  }

  Future<void> _konfirmasiBatal(BuildContext context) async {
    _dialogTerbuka = true;
    final batal = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogBatal(),
    );
    _dialogTerbuka = false;
    if (batal == true && context.mounted) {
      // TODO: panggil API pembatalan pencarian
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mencari Teknisi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              const Spacer(),
              const IlustrasiTeknisi(
                asset: 'assets/images/mencari_teknisi.png',
                tinggi: 240,
              ),
              const SizedBox(height: 28),
              Text(
                'Mencari Teknisi Terdekat...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mencocokan teknisi yang tersedia\ndi sekitar anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              const Spacer(),
              _LokasiAnda(lokasi: _lokasi),
              const SizedBox(height: 10),
              _RingkasanBiaya(layanan: layanan),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _konfirmasiBatal(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Batalkan Pesanan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.merah,
                    side: const BorderSide(color: AppColors.merah),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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

class _LokasiAnda extends StatelessWidget {
  final String lokasi;

  const _LokasiAnda({required this.lokasi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.biruMuda,
            child: Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.biruAksen,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi Anda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                lokasi,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingkasanBiaya extends StatelessWidget {
  final Layanan layanan;

  const _RingkasanBiaya({required this.layanan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5D9DE)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Kolom(
                ikon: Icons.schedule,
                judul: 'Estimasi Kedatangan',
                nilai: '15 - 20 Menit',
                catatan: 'Berdasarkan lokasi anda',
              ),
            ),
            const VerticalDivider(width: 24, color: Color(0xFFD5D9DE)),
            Expanded(
              child: _Kolom(
                ikon: Icons.account_balance_wallet_outlined,
                judul: 'Biaya Pemeriksaan',
                nilai: rupiah(layanan.harga),
                badge: 'Pembayaran Selesai',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kolom extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String nilai;
  final String? catatan;
  final String? badge;

  const _Kolom({
    required this.ikon,
    required this.judul,
    required this.nilai,
    this.catatan,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 18, color: AppColors.biruAksen),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                judul,
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          nilai,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (catatan != null)
          Text(
            catatan!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppColors.teksSamar,
            ),
          ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.hijauMuda,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 7, color: AppColors.hijau),
                const SizedBox(width: 4),
                Text(
                  badge!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppColors.hijau,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DialogBatal extends StatelessWidget {
  const _DialogBatal();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.merah, width: 3),
              ),
              child: const Icon(
                Icons.priority_high,
                color: AppColors.merah,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Batalkan Pencarian?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apakah kamu yakin ingin membatalkan pencarian teknisi? Pencarian teknisi yang sedang berlangsung akan dihentikan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.biruAksen,
                      side: const BorderSide(color: AppColors.biruAksen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Kembali'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biruAksen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Ya, Batalkan'),
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
