import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../models/metode_bayar.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import 'mencari_teknisi_page.dart';
import 'menunggu_pembayaran_page.dart';

/// Ringkasan pesanan + pembayaran biaya awal sebelum mencari teknisi.
///
/// Biaya awal wajib dibayar non-tunai lebih dulu; teknisi baru dicari
/// setelah pembayaran berhasil.
class RingkasanPembayaranPage extends StatefulWidget {
  const RingkasanPembayaranPage({super.key, required this.pesanan});

  final PesananPelanggan pesanan;

  @override
  State<RingkasanPembayaranPage> createState() =>
      _RingkasanPembayaranPageState();
}

class _RingkasanPembayaranPageState extends State<RingkasanPembayaranPage> {
  MetodeBayar _metode = MetodeBayar.qris;

  PesananPelanggan get pesanan => widget.pesanan;

  bool get _perluPersetujuanTambahan =>
      OrderService.layananBerbiayaTambahan.contains(pesanan.layanan.nama);

  bool _memproses = false;

  void _pesan(String teks) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));

  /// Simpan pesanan di server, bayar biaya awal, lalu mulai mencari teknisi.
  Future<void> _bayar() async {
    if (_memproses) return;
    setState(() => _memproses = true);
    final layanan = OrderService.instance;
    PesananPelanggan dibuat;
    try {
      dibuat = await layanan.buat(pesanan.copyWith(metodeBayar: _metode.label));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _memproses = false);
      _pesan(e.pesan);
      return;
    }
    if (!mounted) return;

    final dibayar = await Navigator.of(context).push<PesananPelanggan>(
      MaterialPageRoute(
        builder: (_) => MenungguPembayaranPage(
          idPesanan: dibuat.id!,
          idPembayaran: dibuat.idPembayaranAwal!,
          metode: _metode,
          nominal: dibuat.biayaAwal,
          keterangan: 'Biaya awal ${pesanan.layanan.nama}',
          pesanBerhasil:
              'Terima kasih, pembayaran kamu sudah kami terima. Kami carikan '
              'teknisi terdekat sekarang.',
        ),
      ),
    );
    if (!mounted) return;
    if (dibayar == null) {
      // Pembayaran ditinggalkan: batalkan pesanan yang belum dibayar supaya
      // tidak menghalangi pesanan berikutnya. Bila ternyata sudah dibayar,
      // server menahan dananya untuk refund.
      layanan.pesananAktif.value = dibuat;
      await layanan.batalkan(alasan: 'Pembayaran tidak diselesaikan');
      if (mounted) setState(() => _memproses = false);
      return;
    }

    // Halaman form dan pembayaran dibuang dari stack supaya tombol kembali
    // dari alur pencarian tidak membuka lagi pembayaran yang sudah lunas.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MencariTeknisiPage(pesanan: dibayar)),
      (route) => route.isFirst,
    );
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
          'Ringkasan Pembayaran',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.garisLembut),
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
            if (pesanan.detailLayanan['keluhan'] case final List k)
              _baris('Keluhan', k.join(', '), rataKanan: false),
            if (pesanan.detailLayanan['jenis_freon'] case final String f)
              _baris('Jenis freon', f),
            if (pesanan.detailLayanan['jenis_pekerjaan'] case final String j)
              _baris(
                'Jenis pekerjaan',
                JenisBongkarPasang.values.byName(j).label,
              ),
            if (pesanan.catatan != null)
              _baris('Catatan', pesanan.catatan!, rataKanan: false),
          ]),
          const SizedBox(height: 14),
          _kartu('Rincian Harga', [
            _baris(
              'Biaya awal ${rupiah(pesanan.layanan.harga)} x '
              '${pesanan.jumlahUnit} unit',
              rupiah(pesanan.biayaAwal),
            ),
            const Divider(height: 20, color: AppColors.garisLembut),
            _baris('Dibayar sekarang', rupiah(pesanan.biayaAwal), tebal: true),
          ]),
          if (_perluPersetujuanTambahan) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kuningMuda,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.kuningGaris),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.kuning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biaya perbaikan bisa bertambah setelah diagnosis dan '
                      'perlu persetujuanmu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.kuning,
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
          for (final m in MetodeBayar.values)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _metode == m ? AppColors.biru : AppColors.garis,
                  width: 1.5,
                ),
              ),
              child: RadioListTile<MetodeBayar>(
                value: m,
                // ignore: deprecated_member_use
                groupValue: _metode,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _metode = v ?? _metode),
                dense: true,
                activeColor: AppColors.biru,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                secondary: Icon(m.ikon, size: 20, color: AppColors.teksSamar),
                title: Text(
                  m.label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                subtitle: Text(
                  m.keterangan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.teksSamar,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Teknisi dicari setelah biaya awal dibayar. Jika ada perbaikan '
            'tambahan, rinciannya dikirim untuk kamu setujui dan dibayar '
            'setelah pekerjaan selesai.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
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
            onPressed: _memproses ? null : _bayar,
            label: Text(
              _memproses
                  ? 'Memproses...'
                  : 'Bayar ${rupiah(pesanan.biayaAwal)}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.biru,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
        border: Border.all(color: AppColors.garisLembut),
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
                color: tebal ? AppColors.biruTua : Colors.black87,
                fontWeight: tebal ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
