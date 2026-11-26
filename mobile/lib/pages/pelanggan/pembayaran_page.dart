import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../models/metode_bayar.dart';
import '../../models/teknisi.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import 'menunggu_pembayaran_page.dart';

/// Pelunasan biaya perbaikan setelah pekerjaan selesai.
///
/// Biaya awal sudah dibayar saat memesan, jadi yang ditagih di sini hanya
/// biaya perbaikan yang sudah disetujui pelanggan. Pembayaran non-tunai.
/// Halaman ditutup dengan hasil `true` bila pembayaran berhasil.
class PembayaranPage extends StatefulWidget {
  /// Pesanan dari server yang menunggu pelunasan.
  final PesananPelanggan pesanan;

  const PembayaranPage({super.key, required this.pesanan});

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  MetodeBayar _metode = MetodeBayar.eWallet;
  bool _memproses = false;

  Teknisi get _teknisi => widget.pesanan.teknisi ?? teknisiDummy;

  Future<void> _bayar() async {
    if (_memproses) return;
    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MenungguPembayaranPage(
          metode: _metode,
          nominal: widget.pesanan.jumlahPelunasan,
          keterangan: 'Pelunasan biaya perbaikan',
        ),
      ),
    );
    if (berhasil != true || !mounted) return;
    setState(() => _memproses = true);
    try {
      // TODO(xendit): status lunas datang dari server, bukan simulasi.
      await OrderService.instance.simulasiPelunasan(widget.pesanan);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _memproses = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.pesan)));
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.pesanan.tagihan;
    final aktif = widget.pesanan;

    return Scaffold(
      backgroundColor: AppColors.latar,
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
          child: Divider(height: 1, color: AppColors.garisLembut),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KartuBagian(
            judul: 'Ringkasan Pesanan',
            anak: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.garis,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _teknisi.nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '★ ${_teknisi.rating}  (${_teknisi.jumlahUlasan} ulasan)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.teksSamar,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                _BarisKecil(
                  'Jadwal',
                  DateFormat(
                    'EEEE, d MMM yyyy | HH.mm',
                    'id_ID',
                  ).format(aktif.jadwal),
                ),
                const Divider(height: 1),
                _BarisKecil('Alamat', aktif.alamatLengkap),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _KartuBagian(
            judul: 'Rincian Pembayaran',
            anak: Column(
              children: [
                _BarisHarga(
                  'Biaya awal (sudah dibayar)',
                  rupiah(t.pemeriksaan),
                  samar: true,
                ),
                const SizedBox(height: 8),
                _BarisHarga('Biaya perbaikan', rupiah(t.totalKomponen)),
                for (final k in t.komponen)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          k.nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          rupiah(k.harga),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                _BarisHarga(
                  'Total Pembayaran',
                  rupiah(t.sisaTagihan),
                  tebal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _KartuBagian(
            judul: 'Metode Pembayaran',
            anak: Column(
              children: [
                for (final m in MetodeBayar.values)
                  _PilihanMetode(
                    judul: m.label,
                    keterangan: m.keterangan,
                    ikon: m.ikon,
                    dipilih: _metode == m,
                    onTap: () => setState(() => _metode = m),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.garisLembut)),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        rupiah(t.sisaTagihan),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _memproses ? null : _bayar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.biru,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Bayar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih berjudul, sama dengan gaya bagian di layar lain.
class _KartuBagian extends StatelessWidget {
  final String judul;
  final Widget anak;

  const _KartuBagian({required this.judul, required this.anak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.garisLembut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          anak,
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
              style: GoogleFonts.plusJakartaSans(fontSize: 11),
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
  final bool samar;

  const _BarisHarga(
    this.kiri,
    this.kanan, {
    this.tebal = false,
    this.samar = false,
  });

  @override
  Widget build(BuildContext context) {
    final gaya = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: tebal ? FontWeight.w700 : FontWeight.w500,
      color: samar ? AppColors.teksSamar : Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(kiri, style: gaya),
        Text(kanan, style: gaya),
      ],
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
                        fontSize: 11,
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
                color: dipilih ? AppColors.hijau : AppColors.garisLembut,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: dipilih ? Colors.white : AppColors.teksNonaktif,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
