import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import 'mencari_teknisi_page.dart';

/// Halaman kode QRIS setelah pelanggan memilih metode QRIS di halaman
/// ringkasan pembayaran.
///
/// Pembayaran masih dummy: setelah [lamaProses] halaman ini menganggap
/// pembayaran berhasil, lalu pindah ke pencarian teknisi.
// TODO(backend): tampilkan QR dari payment gateway dan pantau status
// pembayaran lewat webhook/polling, bukan timer.
class QrisPage extends StatefulWidget {
  final PesananPelanggan pesanan;

  /// Lama dummy sebelum pembayaran dianggap berhasil.
  final Duration lamaProses;

  const QrisPage({
    super.key,
    required this.pesanan,
    this.lamaProses = const Duration(seconds: 5),
  });

  @override
  State<QrisPage> createState() => _QrisPageState();
}

class _QrisPageState extends State<QrisPage> {
  Timer? _timerProses;
  Timer? _timerHitungMundur;
  late int _sisaDetik = widget.lamaProses.inSeconds;
  bool _berhasil = false;

  @override
  void initState() {
    super.initState();
    _timerProses = Timer(widget.lamaProses, _tandaiBerhasil);
    _timerHitungMundur = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _sisaDetik = (_sisaDetik - 1).clamp(0, 999));
    });
  }

  @override
  void dispose() {
    _timerProses?.cancel();
    _timerHitungMundur?.cancel();
    super.dispose();
  }

  /// Pembayaran dianggap berhasil: tandai metode bayar pesanan, lalu lanjut
  /// ke pencarian teknisi.
  void _tandaiBerhasil() {
    _timerHitungMundur?.cancel();
    _timerHitungMundur = null;
    if (!mounted) return;

    final pesanan = widget.pesanan.copyWith(metodeBayar: 'QRIS');
    OrderService.instance.pesananAktif.value = pesanan;

    setState(() => _berhasil = true);
    _keMencariTeknisi(pesanan);
  }

  /// Buang halaman QRIS (dan halaman sebelumnya) dari stack supaya menekan
  /// back dari alur pencarian tidak kembali ke halaman pembayaran yang sudah
  /// selesai. Beranda tetap jadi rute pertama.
  void _keMencariTeknisi(PesananPelanggan pesanan) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MencariTeknisiPage(
          layanan: pesanan.layanan,
          pesanan: pesanan,
          metodeBayar: pesanan.metodeBayar,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pesanan = widget.pesanan;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pembayaran QRIS',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEF0F4)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _KartuStatus(berhasil: _berhasil, sisaDetik: _sisaDetik),
          const SizedBox(height: 18),
          _KodeQris(meredup: _berhasil),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Nominal: ${rupiah(pesanan.totalEstimasi)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              pesanan.layanan.nama,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.teksSamar,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _Panduan(),
        ],
      ),
    );
  }
}

class _KartuStatus extends StatelessWidget {
  final bool berhasil;
  final int sisaDetik;

  const _KartuStatus({required this.berhasil, required this.sisaDetik});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: berhasil ? AppColors.hijauMuda : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (berhasil)
            const Icon(Icons.check_circle, color: AppColors.hijau, size: 22)
          else
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.biruAksen,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  berhasil ? 'Pembayaran Berhasil' : 'Menunggu Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: berhasil ? AppColors.hijau : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  berhasil
                      ? 'Terima kasih, pembayaran QRIS kamu sudah kami terima. '
                            'Kami carikan teknisi terdekat sekarang.'
                      : 'Silakan pindai kode QRIS di bawah. Pembayaran akan '
                            'diverifikasi otomatis dalam $sisaDetik detik.',
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

/// Kotak QRIS dummy. Pola kotak hitam hanya ilustrasi, tidak bisa dipindai.
class _KodeQris extends StatelessWidget {
  final bool meredup;

  const _KodeQris({required this.meredup});

  /// Pola 13x13 tetap supaya tampilan menyerupai QR tanpa asset tambahan.
  static const int _ukuran = 13;
  static const List<String> _pola = [
    '1111111010111',
    '1000001010001',
    '1011101001101',
    '1011101110011',
    '1011101010101',
    '1000001101001',
    '1111111010101',
    '0000000011010',
    '1101011001011',
    '0010110110001',
    '1001101010111',
    '0110010011000',
    '1111111000111',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: meredup ? 0.35 : 1,
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD5D9DE)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.biru,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QRIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 208,
                height: 208,
                child: Column(
                  children: [
                    for (var i = 0; i < _ukuran; i++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var j = 0; j < _ukuran; j++)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(0.5),
                                  color: _pola[i][j] == '1'
                                      ? Colors.black87
                                      : Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ACare Indonesia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.teksSamar,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panduan extends StatelessWidget {
  const _Panduan();

  static const List<String> _langkah = [
    'Buka aplikasi e-wallet atau m-banking yang mendukung QRIS.',
    'Pindai kode QR di atas, lalu pastikan nominalnya sudah sesuai.',
    'Selesaikan pembayaran; halaman ini lanjut otomatis ke pencarian '
        'teknisi.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara Membayar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _langkah.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.biruAksen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _langkah[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
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
