import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/layanan.dart';
import '../models/status_layanan.dart';
import '../models/tagihan.dart';
import '../models/teknisi.dart';
import '../services/perangkat.dart';
import '../theme/app_colors.dart';
import '../widgets/teknisi_info_card.dart';
import 'chat_teknisi_page.dart';
import 'pembayaran_page.dart';

class DetailPesananPage extends StatefulWidget {
  final StatusLayanan status;
  final Teknisi teknisi;
  final Tagihan tagihan;

  const DetailPesananPage({
    super.key,
    required this.status,
    this.teknisi = teknisiDummy,
    this.tagihan = tagihanDummy,
  });

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  bool _komponenTerbuka = false;

  static const _langkah = [
    (StatusLayanan.pengecekanAwal, Icons.search),
    (StatusLayanan.melakukanPerbaikan, Icons.build_outlined),
    (StatusLayanan.menungguPembayaran, Icons.credit_card_outlined),
    (StatusLayanan.selesai, Icons.check_circle_outline),
  ];
  // Jam tiap langkah (dummy), tampil kalau langkah sudah dicapai
  static const _jam = ['12.30', '13.00', '14.30', '15.00'];

  bool get _bisaBayar => widget.status == StatusLayanan.menungguPembayaran;
  bool get _bisaBatal => widget.status == StatusLayanan.pengecekanAwal;

  Future<void> _batalkan() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Pesanan yang dibatalkan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (ya == true && mounted) {
      // TODO: panggil API pembatalan pesanan
      Navigator.of(context).pop();
    }
  }

  void _pesan() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ChatTeknisiPage(teknisi: widget.teknisi)),
  );

  @override
  Widget build(BuildContext context) {
    final t = widget.tagihan;
    final idx = widget.status.index;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.status.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.biru),
        ),
      ),
      body: ListView(
        children: [
          const _BarJudul('Detail Teknisi'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TeknisiInfoCard(
              teknisi: widget.teknisi,
              onPesan: _pesan,
              onTelepon: () => teleponKe(context, widget.teknisi.telepon),
            ),
          ),
          const _BarJudul('Status Layanan'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                for (var i = 0; i < _langkah.length; i++)
                  _LangkahStatus(
                    label: _langkah[i].$1.label,
                    ikon: _langkah[i].$2,
                    jam: i <= idx ? _jam[i] : null,
                    tercapai: i <= idx,
                    garisBerikutnya: i < _langkah.length - 1,
                    garisAktif: i + 1 <= idx,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E6EA)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _Baris('Pemeriksaan', rupiah(t.pemeriksaan)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () =>
                      setState(() => _komponenTerbuka = !_komponenTerbuka),
                  child: _Baris(
                    'Komponen',
                    rupiah(t.totalKomponen),
                    tambahan: Icon(
                      _komponenTerbuka
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                  ),
                ),
                if (_komponenTerbuka)
                  for (final k in t.komponen)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 8),
                      child: _Baris(k.nama, rupiah(k.harga), kecil: true),
                    ),
                const SizedBox(height: 14),
                _Baris('Total Pembayaran', rupiah(t.total), tebal: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _TombolAksi(
                  label: 'Bayar Pesanan',
                  ikon: Icons.check,
                  warna: AppColors.hijau,
                  aktif: _bisaBayar,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PembayaranPage(
                        teknisi: widget.teknisi,
                        tagihan: widget.tagihan,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _TombolAksi(
                  label: 'Batalkan Pesanan',
                  ikon: Icons.close,
                  warna: AppColors.merah,
                  aktif: _bisaBatal,
                  onTap: _batalkan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarJudul extends StatelessWidget {
  final String teks;

  const _BarJudul(this.teks);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.biru,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        teks,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LangkahStatus extends StatelessWidget {
  final String label;
  final IconData ikon;
  final String? jam;
  final bool tercapai;
  final bool garisBerikutnya;
  final bool garisAktif;

  const _LangkahStatus({
    required this.label,
    required this.ikon,
    required this.jam,
    required this.tercapai,
    required this.garisBerikutnya,
    required this.garisAktif,
  });

  @override
  Widget build(BuildContext context) {
    final warna = tercapai ? AppColors.biruAksen : AppColors.teksSamar;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(ikon, size: 18, color: warna),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: warna,
                      fontWeight: tercapai ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (jam != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(jam!, style: const TextStyle(fontSize: 8)),
                  const Text('Today', style: TextStyle(fontSize: 7)),
                ],
              ),
            ),
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: tercapai
                        ? AppColors.biruAksen
                        : const Color(0xFFE4E6EA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 13,
                    color: tercapai ? Colors.white : const Color(0xFFBFC4CC),
                  ),
                ),
                if (garisBerikutnya)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: garisAktif
                          ? AppColors.biruAksen
                          : const Color(0xFFE4E6EA),
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

class _Baris extends StatelessWidget {
  final String kiri;
  final String kanan;
  final bool tebal;
  final bool kecil;
  final Widget? tambahan;

  const _Baris(
    this.kiri,
    this.kanan, {
    this.tebal = false,
    this.kecil = false,
    this.tambahan,
  });

  @override
  Widget build(BuildContext context) {
    final gaya = GoogleFonts.plusJakartaSans(
      fontSize: kecil ? 11 : 13,
      fontWeight: tebal ? FontWeight.w600 : FontWeight.w400,
      color: kecil ? Colors.black54 : Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(kiri, style: gaya),
            ?tambahan,
          ],
        ),
        Text(kanan, style: gaya),
      ],
    );
  }
}

class _TombolAksi extends StatelessWidget {
  final String label;
  final IconData ikon;
  final Color warna;
  final bool aktif;
  final VoidCallback onTap;

  const _TombolAksi({
    required this.label,
    required this.ikon,
    required this.warna,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: aktif ? onTap : null,
        icon: Icon(ikon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: warna,
          disabledForegroundColor: AppColors.teksSamar,
          side: BorderSide(color: aktif ? warna : const Color(0xFFCBD0D8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
