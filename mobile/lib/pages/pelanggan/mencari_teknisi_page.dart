import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ilustrasi_teknisi.dart';
import 'tracking_teknisi_page.dart';

class MencariTeknisiPage extends StatefulWidget {
  /// Pesanan yang biaya awalnya sudah dibayar (sudah ada di server).
  final PesananPelanggan pesanan;

  const MencariTeknisiPage({super.key, required this.pesanan});

  @override
  State<MencariTeknisiPage> createState() => _MencariTeknisiPageState();
}

class _MencariTeknisiPageState extends State<MencariTeknisiPage> {
  bool _selesai = false;

  PesananPelanggan get _pesanan => widget.pesanan;

  String get _lokasi => _pesanan.alamatLengkap;

  @override
  void initState() {
    super.initState();
    _mulaiCari();
  }

  @override
  void dispose() {
    // Pencarian tetap berjalan di server; aplikasi berhenti memeriksa.
    if (!_selesai) OrderService.instance.hentikanPencarian();
    super.dispose();
  }

  Future<void> _mulaiCari() async {
    final ditemukan = await OrderService.instance.cariTeknisi(_pesanan);
    if (!mounted) return;
    if (!ditemukan) {
      // Batal karena tidak ada teknisi yang menerima dalam batas waktu.
      if (OrderService.instance.pesananAktif.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Belum ada teknisi yang tersedia. Pesanan dibatalkan dan biaya '
              'awal bisa kamu ajukan refund dari Riwayat.',
            ),
          ),
        );
        Navigator.of(context).maybePop();
      }
      return;
    }
    setState(() => _selesai = true);
    _keTracking();
  }

  /// Teknisi ditemukan: buka halaman tracking dan buang halaman alur pesanan
  /// (form, ringkasan, pencarian) dari stack. Beranda tetap jadi halaman
  /// pertama, jadi menekan back dari tracking kembali ke beranda.
  void _keTracking() {
    final aktif = OrderService.instance.pesananAktif.value;
    if (aktif?.teknisi == null) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => TrackingTeknisiPage(pesanan: aktif!)),
      (route) => route.isFirst,
    );
  }

  Future<void> _konfirmasiBatal(BuildContext context) async {
    if (_selesai) return;
    final batal = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogBatal(),
    );
    if (batal != true || !context.mounted) return;
    final galat = await OrderService.instance.batalkan();
    if (!context.mounted) return;
    if (galat != null) {
      // Misal teknisi baru saja menerima: pesanan tidak bisa dibatalkan.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(galat)));
      return;
    }
    _selesai = true;
    Navigator.of(context).pop();
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
              _RingkasanBiaya(biayaAwal: _pesanan.biayaAwal),
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
                      borderRadius: BorderRadius.circular(12),
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
        color: AppColors.biruMuda,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.biruMuda,
            child: Icon(Icons.location_on, size: 16, color: AppColors.biruTua),
          ),
          const SizedBox(width: 12),
          // Expanded: alamat asli bisa panjang, jangan meluber keluar kartu.
          Expanded(
            child: Column(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingkasanBiaya extends StatelessWidget {
  final int biayaAwal;

  const _RingkasanBiaya({required this.biayaAwal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.garis),
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
            const VerticalDivider(width: 24, color: AppColors.garis),
            Expanded(
              child: _Kolom(
                ikon: Icons.account_balance_wallet_outlined,
                judul: 'Biaya Awal',
                nilai: rupiah(biayaAwal),
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
            Icon(ikon, size: 18, color: AppColors.biruTua),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                judul,
                style: GoogleFonts.plusJakartaSans(fontSize: 11),
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
              fontSize: 11,
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
                    fontSize: 11,
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
                      foregroundColor: AppColors.biruTua,
                      side: const BorderSide(color: AppColors.biruTua),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      backgroundColor: AppColors.biruTua,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
