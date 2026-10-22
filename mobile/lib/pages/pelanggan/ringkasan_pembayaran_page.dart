import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import 'mencari_teknisi_page.dart';
import 'qris_page.dart';

/// Ringkasan pesanan + pilihan metode bayar sebelum mencari teknisi.
///
/// Pembayaran masih mock: metode hanya disimpan di [PesananPelanggan], tidak
/// ada transaksi sungguhan. // TODO(backend): integrasikan payment gateway.
class RingkasanPembayaranPage extends StatefulWidget {
  const RingkasanPembayaranPage({super.key, required this.pesanan});

  final PesananPelanggan pesanan;

  @override
  State<RingkasanPembayaranPage> createState() =>
      _RingkasanPembayaranPageState();
}

class _RingkasanPembayaranPageState extends State<RingkasanPembayaranPage> {
  static const Map<String, IconData> _metodeBayar = {
    'Tunai': Icons.payments_outlined,
    'QRIS': Icons.qr_code_2,
    'Transfer/E-Wallet': Icons.account_balance_wallet_outlined,
  };

  String _metode = 'Tunai';

  PesananPelanggan get pesanan => widget.pesanan;

  bool get _perluPersetujuanTambahan =>
      OrderService.layananBerbiayaTambahan.contains(pesanan.layanan.nama);

  void _cariTeknisi() {
    // TODO(backend): simpan pesanan ke API sebelum pencarian.
    // QRIS punya halaman kode QR dulu; metode lain langsung mencari teknisi.
    final Widget halaman = _metode == 'QRIS'
        ? QrisPage(pesanan: pesanan)
        : MencariTeknisiPage(
            layanan: pesanan.layanan,
            pesanan: pesanan,
            metodeBayar: _metode,
          );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));
  }

  @override
  Widget build(BuildContext context) {
    final biayaLayanan = OrderService.hitungBiayaLayanan(
      pesanan.layanan,
      pesanan.jumlahUnit,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ringkasan Pembayaran',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEF0F4)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _kartu('Rincian Pesanan', [
            _baris('Layanan', pesanan.layanan.nama),
            _baris('Jumlah unit', '${pesanan.jumlahUnit} unit'),
            _baris('Unit AC', pesanan.ringkasanUnit),
            _baris(
              'Jadwal',
              DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(pesanan.jadwal),
            ),
            _baris('Alamat', pesanan.alamatLengkap, rataKanan: false),
            if (pesanan.catatan != null)
              _baris('Catatan', pesanan.catatan!, rataKanan: false),
          ]),
          const SizedBox(height: 14),
          _kartu('Rincian Harga', [
            _baris(
              '${rupiah(pesanan.layanan.harga)} x ${pesanan.jumlahUnit} unit',
              rupiah(biayaLayanan),
            ),
            _baris('Biaya aplikasi', rupiah(OrderService.biayaAplikasi)),
            const Divider(height: 20, color: Color(0xFFEEF0F4)),
            _baris(
              'Total estimasi',
              rupiah(pesanan.totalEstimasi),
              tebal: true,
            ),
          ]),
          if (_perluPersetujuanTambahan) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF3D9A4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFB7791F),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biaya perbaikan bisa bertambah setelah diagnosis dan '
                      'perlu persetujuanmu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF8A5B12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final m in _metodeBayar.entries)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _metode == m.key
                      ? AppColors.biru
                      : const Color(0xFFD5D9DE),
                  width: _metode == m.key ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: m.key,
                // ignore: deprecated_member_use
                groupValue: _metode,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _metode = v ?? _metode),
                dense: true,
                activeColor: AppColors.biru,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                secondary: Icon(m.value, size: 20, color: AppColors.teksSamar),
                title: Text(
                  m.key,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            _metode == 'QRIS'
                ? 'Setelah menekan tombol di bawah, kamu akan diarahkan ke kode '
                      'QRIS untuk menyelesaikan pembayaran.'
                : 'Pembayaran belum diproses sekarang; kamu membayar setelah '
                      'pekerjaan selesai.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.teksSamar,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _cariTeknisi,
            iconAlignment: IconAlignment.end,
            icon: Icon(
              _metode == 'QRIS' ? Icons.qr_code_2 : Icons.search,
              size: 18,
            ),
            label: Text(
              _metode == 'QRIS' ? 'Lanjut ke Pembayaran' : 'Cari Teknisi',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.biru,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kartu(String judul, List<Widget> isi) {
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
            judul,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...isi,
        ],
      ),
    );
  }

  Widget _baris(
    String kiri,
    String kanan, {
    bool tebal = false,
    bool rataKanan = true,
  }) {
    final gaya = GoogleFonts.plusJakartaSans(
      fontSize: tebal ? 13 : 11.5,
      fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
      color: tebal ? Colors.black87 : Colors.black54,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(kiri, style: gaya)),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              kanan,
              textAlign: rataKanan ? TextAlign.right : TextAlign.left,
              style: gaya.copyWith(
                color: tebal ? AppColors.biruAksen : Colors.black87,
                fontWeight: tebal ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
