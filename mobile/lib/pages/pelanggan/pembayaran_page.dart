import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/tagihan.dart';
import '../../models/teknisi.dart';
import '../../theme/app_colors.dart';

enum _Metode { transferBank, eWallet, cash }

class PembayaranPage extends StatefulWidget {
  final Teknisi teknisi;
  final Tagihan tagihan;

  const PembayaranPage({
    super.key,
    this.teknisi = teknisiDummy,
    this.tagihan = tagihanDummy,
  });

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  _Metode _metode = _Metode.eWallet;

  void _bayar() {
    // TODO: panggil API pembayaran sesuai metode yang dipilih
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembayaran berhasil')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tagihan;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.biru),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KartuBiru(
            judul: 'Ringkasan Pesanan',
            anak: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFD9DDE3),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teknisi.nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '★ ${widget.teknisi.rating}  (${widget.teknisi.jumlahUlasan} ulasan)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.teksSamar,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const _BarisKecil('Jadwal', 'Senin, 12 Sep 2026 | 12.00 - 14.30'),
                const Divider(height: 1),
                const _BarisKecil('Alamat', 'Perumahan Batu Aji, Batam'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _KartuBiru(
            judul: 'Rincian Pembayaran',
            anak: Column(
              children: [
                _BarisHarga('Pemeriksaan', rupiah(t.pemeriksaan)),
                const SizedBox(height: 8),
                _BarisHarga('Komponen', rupiah(t.totalKomponen)),
                for (final k in t.komponen)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          k.nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          rupiah(k.harga),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                _BarisHarga('Total Pembayaran', rupiah(t.total), tebal: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _KartuBiru(
            judul: 'Metode Pembayaran',
            anak: Column(
              children: [
                _PilihanMetode(
                  judul: 'Transfer Bank',
                  keterangan: 'BNI, MANDIRI, BCA',
                  ikon: Icons.account_balance_outlined,
                  dipilih: _metode == _Metode.transferBank,
                  onTap: () => setState(() => _metode = _Metode.transferBank),
                ),
                _PilihanMetode(
                  judul: 'E-Wallet',
                  keterangan: 'Dana, Gopay, OVO',
                  ikon: Icons.account_balance_wallet_outlined,
                  dipilih: _metode == _Metode.eWallet,
                  onTap: () => setState(() => _metode = _Metode.eWallet),
                ),
                _PilihanMetode(
                  judul: 'Cash',
                  ikon: Icons.payments_outlined,
                  dipilih: _metode == _Metode.cash,
                  onTap: () => setState(() => _metode = _Metode.cash),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.biru)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL PEMBAYARAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        rupiah(t.total),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _bayar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.hijau,
                    side: const BorderSide(color: AppColors.hijau),
                    minimumSize: const Size(110, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('BAYAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuBiru extends StatelessWidget {
  final String judul;
  final Widget anak;

  const _KartuBiru({required this.judul, required this.anak});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.biru),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.biru,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              judul,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12), child: anak),
        ],
      ),
    );
  }
}

class _BarisKecil extends StatelessWidget {
  final String kiri;
  final String kanan;

  const _BarisKecil(this.kiri, this.kanan);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(kiri, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
          Flexible(
            child: Text(
              kanan,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisHarga extends StatelessWidget {
  final String kiri;
  final String kanan;
  final bool tebal;

  const _BarisHarga(this.kiri, this.kanan, {this.tebal = false});

  @override
  Widget build(BuildContext context) {
    final gaya = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: tebal ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(kiri, style: gaya), Text(kanan, style: gaya)],
    );
  }
}

class _PilihanMetode extends StatelessWidget {
  final String judul;
  final String? keterangan;
  final IconData ikon;
  final bool dipilih;
  final VoidCallback onTap;

  const _PilihanMetode({
    required this.judul,
    this.keterangan,
    required this.ikon,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(ikon, size: 22, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (keterangan != null)
                    Text(
                      keterangan!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppColors.teksSamar,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: dipilih ? AppColors.hijau : const Color(0xFFE4E6EA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: dipilih ? Colors.white : const Color(0xFFBFC4CC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
