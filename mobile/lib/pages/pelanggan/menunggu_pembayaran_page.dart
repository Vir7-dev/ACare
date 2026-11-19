import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/metode_bayar.dart';
import '../../theme/app_colors.dart';

/// Halaman menunggu pembayaran non-tunai (QRIS, e-wallet, virtual account),
/// dipakai untuk pembayaran awal maupun pelunasan.
///
/// Pembayaran masih tiruan: setelah [lamaProses] pembayaran dianggap
/// berhasil lalu halaman ditutup dengan hasil `true`. Halaman pemanggil yang
/// menentukan langkah berikutnya.
// TODO(backend): buat invoice Xendit lewat API, tampilkan QR/nomor VA/tautan
// e-wallet dari respons, dan pantau statusnya lewat webhook, bukan timer.
class MenungguPembayaranPage extends StatefulWidget {
  final MetodeBayar metode;
  final int nominal;

  /// Penjelasan singkat tagihan, misal "Biaya awal Cuci AC".
  final String keterangan;

  /// Kalimat setelah pembayaran berhasil.
  final String pesanBerhasil;

  /// Lama tiruan sebelum pembayaran dianggap berhasil.
  final Duration lamaProses;

  const MenungguPembayaranPage({
    super.key,
    required this.metode,
    required this.nominal,
    required this.keterangan,
    this.pesanBerhasil = 'Terima kasih, pembayaran kamu sudah kami terima.',
    this.lamaProses = const Duration(seconds: 5),
  });

  @override
  State<MenungguPembayaranPage> createState() => _MenungguPembayaranPageState();
}

class _MenungguPembayaranPageState extends State<MenungguPembayaranPage> {
  Timer? _timerProses;
  Timer? _timerHitungMundur;
  Timer? _timerTutup;
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
    _timerTutup?.cancel();
    super.dispose();
  }

  void _tandaiBerhasil() {
    _timerHitungMundur?.cancel();
    if (!mounted) return;
    setState(() => _berhasil = true);
    // Beri jeda singkat supaya pengguna sempat melihat status berhasil.
    _timerTutup = Timer(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final metode = widget.metode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pembayaran ${metode.label}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.garisLembut),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _KartuStatus(
            berhasil: _berhasil,
            sisaDetik: _sisaDetik,
            petunjuk: _petunjukSingkat(metode),
            pesanBerhasil: widget.pesanBerhasil,
          ),
          const SizedBox(height: 18),
          AnimatedOpacity(
            opacity: _berhasil ? 0.35 : 1,
            duration: const Duration(milliseconds: 300),
            child: switch (metode) {
              MetodeBayar.qris => const _KodeQris(),
              MetodeBayar.eWallet => const _InfoEWallet(),
              MetodeBayar.virtualAccount => const _NomorVa(),
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Nominal: ${rupiah(widget.nominal)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              widget.keterangan,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.teksSamar,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Panduan(langkah: _langkah(metode)),
        ],
      ),
    );
  }

  static String _petunjukSingkat(MetodeBayar m) => switch (m) {
    MetodeBayar.qris => 'Silakan pindai kode QRIS di bawah.',
    MetodeBayar.eWallet => 'Selesaikan pembayaran di aplikasi e-wallet kamu.',
    MetodeBayar.virtualAccount => 'Transfer ke nomor virtual account di bawah.',
  };

  static List<String> _langkah(MetodeBayar m) => switch (m) {
    MetodeBayar.qris => const [
      'Buka aplikasi e-wallet atau m-banking yang mendukung QRIS.',
      'Pindai kode QR di atas, lalu pastikan nominalnya sudah sesuai.',
      'Selesaikan pembayaran; halaman ini lanjut otomatis.',
    ],
    MetodeBayar.eWallet => const [
      'Kamu akan diarahkan ke aplikasi e-wallet yang dipilih.',
      'Periksa nominal, lalu konfirmasi pembayaran.',
      'Kembali ke ACare; halaman ini lanjut otomatis.',
    ],
    MetodeBayar.virtualAccount => const [
      'Buka m-banking, ATM, atau internet banking.',
      'Pilih transfer ke Virtual Account dan masukkan nomor di atas.',
      'Pastikan nominal sesuai; halaman ini lanjut otomatis.',
    ],
  };
}

class _KartuStatus extends StatelessWidget {
  final bool berhasil;
  final int sisaDetik;
  final String petunjuk;
  final String pesanBerhasil;

  const _KartuStatus({
    required this.berhasil,
    required this.sisaDetik,
    required this.petunjuk,
    required this.pesanBerhasil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: berhasil ? AppColors.hijauMuda : AppColors.biruMuda,
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
                color: AppColors.biruTua,
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
                      ? pesanBerhasil
                      : '$petunjuk Pembayaran diverifikasi otomatis dalam '
                            '$sisaDetik detik.',
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

/// Kotak QRIS tiruan. Pola kotak hitam hanya ilustrasi, tidak bisa dipindai.
class _KodeQris extends StatelessWidget {
  const _KodeQris();

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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.garis),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                fontSize: 11,
                color: AppColors.teksSamar,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoEWallet extends StatelessWidget {
  const _InfoEWallet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.garis),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppColors.biru,
          ),
          const SizedBox(height: 10),
          Text(
            'Menunggu konfirmasi dari aplikasi e-wallet',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DANA, OVO, atau ShopeePay',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.teksSamar,
            ),
          ),
        ],
      ),
    );
  }
}

class _NomorVa extends StatelessWidget {
  const _NomorVa();

  // Nomor tiruan; nanti diisi dari invoice Xendit.
  static const String _nomor = '8808 1234 5678 9012';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nomor Virtual Account',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.teksSamar,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _nomor,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _nomor.replaceAll(' ', '')),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Berlaku untuk BCA, BNI, BRI, dan Mandiri',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.teksSamar,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panduan extends StatelessWidget {
  final List<String> langkah;

  const _Panduan({required this.langkah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.garisLembut),
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
          for (var i = 0; i < langkah.length; i++)
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
                      color: AppColors.biruMuda,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.biruTua,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      langkah[i],
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
