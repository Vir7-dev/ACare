import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../models/status_layanan.dart';
import '../../models/tagihan.dart';
import '../../models/teknisi.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/perangkat.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_info_card.dart';
import 'chat_teknisi_page.dart';
import 'pembayaran_page.dart';

/// Detail pesanan setelah teknisi ditemukan: data teknisi, garis waktu
/// status, dan pembayaran.
///
/// Alur status:
/// Pengecekan Awal -> Menunggu Persetujuan Biaya (pelanggan Setuju/Tolak)
/// -> Melakukan Perbaikan -> Menunggu Pembayaran (pelunasan) -> Selesai.
/// Bila tidak ada biaya perbaikan, tahap persetujuan dan pelunasan dilewati.
/// Menolak biaya perbaikan langsung menyelesaikan pesanan dengan biaya awal.
///
/// Pesanan tidak bisa dibatalkan di sini karena teknisi sudah ditemukan.
///
/// Status diambil dari server setiap [OrderService.selangPeriksa] selama
/// pesanan belum selesai.
class DetailPesananPage extends StatefulWidget {
  /// Pesanan dari server yang sudah punya teknisi.
  final PesananPelanggan pesanan;

  const DetailPesananPage({super.key, required this.pesanan});

  @override
  State<DetailPesananPage> createState() => _DetailPesananPageState();
}

class _DetailPesananPageState extends State<DetailPesananPage> {
  bool _komponenTerbuka = false;
  bool _memproses = false;

  late PesananPelanggan _p = widget.pesanan;
  Timer? _timerPeriksa;

  static const _daftarTampil = StatusLayanan.langkahTampil;

  /// Kunci waktu di server untuk tiap langkah garis waktu.
  static const _kunciWaktu = {
    StatusLayanan.pengecekanAwal: 'pengecekan',
    StatusLayanan.melakukanPerbaikan: 'dikerjakan',
    StatusLayanan.menungguPembayaran: 'menunggu_pembayaran',
    StatusLayanan.selesai: 'selesai',
  };

  static const _ikonLangkah = {
    StatusLayanan.pengecekanAwal: Icons.search,
    StatusLayanan.melakukanPerbaikan: Icons.build_outlined,
    StatusLayanan.menungguPembayaran: Icons.credit_card,
    StatusLayanan.selesai: Icons.check_circle_outline,
  };

  StatusLayanan get _status => _p.statusLayanan;
  Tagihan get _tagihan => _p.tagihan;
  Teknisi get _teknisi => _p.teknisi ?? teknisiDummy;

  /// Pelanggan menolak (atau tidak menanggapi) biaya perbaikan: pesanan
  /// selesai dengan biaya awal.
  bool get _biayaDitolak => _p.biayaDitolak;

  /// Posisi status sekarang di garis waktu.
  int get _indeks => _daftarTampil.indexOf(_status.langkah);

  /// Jam langkah ke-[i] (mis. "14.30"), bila sudah dicapai.
  String? _jam(int i) {
    final w = _p.waktu[_kunciWaktu[_daftarTampil[i]]];
    return w == null ? null : DateFormat('HH.mm').format(w);
  }

  @override
  void initState() {
    super.initState();
    _timerPeriksa = Timer.periodic(
      OrderService.selangPeriksa,
      (_) => _segarkan(),
    );
  }

  @override
  void dispose() {
    _timerPeriksa?.cancel();
    super.dispose();
  }

  Future<void> _segarkan() async {
    if (_p.id == null || _status == StatusLayanan.selesai) {
      _timerPeriksa?.cancel();
      return;
    }
    try {
      final terbaru = await OrderService.instance.muatUlang(_p.id!);
      if (mounted) setState(() => _p = terbaru);
    } on ApiException {
      // Koneksi putus sesaat: coba lagi di putaran berikutnya.
    }
  }

  void _pesan(String teks) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));

  Future<void> _tanggapi({required bool setuju}) async {
    if (_memproses) return;
    setState(() => _memproses = true);
    try {
      final hasil = await OrderService.instance.tanggapiBiaya(
        _p,
        setuju: setuju,
      );
      if (mounted) setState(() => _p = hasil);
    } on ApiException catch (e) {
      if (!mounted) return;
      _pesan(e.pesan);
      await _segarkan();
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  void _setujuiBiaya() => _tanggapi(setuju: true);

  Future<void> _tolakBiaya() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak biaya perbaikan?'),
        content: const Text(
          'Teknisi tidak akan melanjutkan perbaikan. Pesanan selesai hanya '
          'dengan biaya awal yang sudah kamu bayar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    await _tanggapi(setuju: false);
  }

  Future<void> _bayar() async {
    final lunas = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PembayaranPage(pesanan: _p)),
    );
    if (lunas == true && mounted) await _segarkan();
  }

  void _bukaChat() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ChatTeknisiPage(teknisi: _teknisi)));

  @override
  Widget build(BuildContext context) {
    final idx = _indeks;
    final selesai = _status == StatusLayanan.selesai;

    return Scaffold(
      backgroundColor: AppColors.latar,
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
              // Biaya ditolak: teknisi tidak memperbaiki, hanya merampungkan
              // pesanan dengan biaya awal.
              _biayaDitolak && !selesai
                  ? 'Biaya ditolak, teknisi merampungkan pesanan'
                  : _status.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.garisLembut),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          _KartuBagian(
            judul: 'Teknisi',
            child: TeknisiInfoCard(
              teknisi: _teknisi,
              onPesan: _bukaChat,
              onTelepon: () => teleponKe(context, _teknisi.telepon),
            ),
          ),
          const SizedBox(height: 12),
          _KartuBagian(
            judul: 'Status Layanan',
            child: Column(
              children: [
                for (var i = 0; i < _daftarTampil.length; i++)
                  if (!_biayaDitolak ||
                      _daftarTampil[i] == StatusLayanan.pengecekanAwal ||
                      _daftarTampil[i] == StatusLayanan.selesai)
                    _LangkahStatus(
                      label: _daftarTampil[i].label,
                      ikon: _ikonLangkah[_daftarTampil[i]]!,
                      jam: i <= idx ? _jam(i) : null,
                      tercapai: i <= idx,
                      aktif: i == idx && !selesai,
                      garisBerikutnya: i < _daftarTampil.length - 1,
                      garisAktif: i + 1 <= idx,
                    ),
              ],
            ),
          ),
          if (_status == StatusLayanan.menungguPersetujuanBiaya)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _KartuPersetujuanBiaya(
                tagihan: _tagihan,
                onSetuju: _setujuiBiaya,
                onTolak: _tolakBiaya,
              ),
            ),
          const SizedBox(height: 12),
          _KartuBagian(
            judul: 'Pembayaran',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Baris('Biaya awal', '${rupiah(_tagihan.pemeriksaan)} • Lunas'),
                const SizedBox(height: 10),
                ..._rincianPerbaikan(),
              ],
            ),
          ),
          if (_status == StatusLayanan.menungguPembayaran)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              child: _TombolAksi(
                label: 'Bayar Pesanan',
                ikon: Icons.check,
                warna: AppColors.biru,
                aktif: true,
                utama: true,
                onTap: _bayar,
              ),
            )
          else
            const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Bagian biaya perbaikan di kartu pembayaran, menyesuaikan status.
  List<Widget> _rincianPerbaikan() {
    final t = _tagihan;

    if (_biayaDitolak) {
      return [
        const _Baris('Biaya perbaikan', 'Ditolak', kecil: true),
        const SizedBox(height: 14),
        _Baris('Total dibayar', rupiah(t.pemeriksaan), tebal: true),
      ];
    }

    if (!t.adaBiayaPerbaikan) {
      return [
        _Baris(
          'Biaya perbaikan',
          _status == StatusLayanan.pengecekanAwal
              ? 'Menunggu hasil pengecekan'
              : 'Tidak ada',
          kecil: true,
        ),
        if (_status == StatusLayanan.selesai) ...[
          const SizedBox(height: 14),
          _Baris('Total dibayar', rupiah(t.pemeriksaan), tebal: true),
        ],
      ];
    }

    switch (_status) {
      case StatusLayanan.pengecekanAwal:
        return const [
          _Baris('Biaya perbaikan', 'Menunggu hasil pengecekan', kecil: true),
        ];
      case StatusLayanan.menungguPersetujuanBiaya:
        return [
          _Baris(
            'Biaya perbaikan',
            '${rupiah(t.totalKomponen)} • Menunggu persetujuanmu',
            kecil: true,
          ),
        ];
      case StatusLayanan.melakukanPerbaikan:
        return [
          _Baris('Biaya perbaikan', rupiah(t.totalKomponen)),
          const SizedBox(height: 6),
          const _Baris('Dibayar setelah perbaikan selesai', '', kecil: true),
        ];
      case StatusLayanan.menungguPembayaran:
      case StatusLayanan.selesai:
        final lunas = _status == StatusLayanan.selesai;
        return [
          InkWell(
            onTap: () => setState(() => _komponenTerbuka = !_komponenTerbuka),
            child: _Baris(
              'Biaya perbaikan',
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
          lunas
              ? _Baris('Total dibayar', rupiah(t.total), tebal: true)
              : _Baris('Sisa tagihan', rupiah(t.sisaTagihan), tebal: true),
        ];
    }
  }
}

/// Rincian biaya perbaikan dari teknisi yang perlu disetujui pelanggan.
class _KartuPersetujuanBiaya extends StatelessWidget {
  final Tagihan tagihan;
  final VoidCallback onSetuju;
  final VoidCallback onTolak;

  const _KartuPersetujuanBiaya({
    required this.tagihan,
    required this.onSetuju,
    required this.onTolak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kuningMuda,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kuningGaris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AppColors.kuning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rincian Biaya Perbaikan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Teknisi menemukan perbaikan tambahan setelah pengecekan. '
            'Perbaikan dimulai setelah kamu setuju.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          for (final k in tagihan.komponen)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _Baris(k.nama, rupiah(k.harga), kecil: true),
            ),
          const Divider(height: 16, color: AppColors.kuningGaris),
          _Baris(
            'Total biaya perbaikan',
            rupiah(tagihan.totalKomponen),
            tebal: true,
          ),
          if (tagihan.catatanTeknisi.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan teknisi: ${tagihan.catatanTeknisi}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Jika ditolak atau tidak ditanggapi dalam '
            '${batasPersetujuanBiaya.inMinutes} menit, pesanan selesai '
            'dengan biaya awal saja.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.teksSamar,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TombolAksi(
                  label: 'Tolak',
                  ikon: Icons.close,
                  warna: AppColors.merah,
                  aktif: true,
                  onTap: onTolak,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TombolAksi(
                  label: 'Setuju',
                  ikon: Icons.check,
                  warna: AppColors.biru,
                  aktif: true,
                  utama: true,
                  onTap: onSetuju,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu putih berjudul, gaya bagian yang sama dengan layar lain.
class _KartuBagian extends StatelessWidget {
  final String judul;
  final Widget child;

  const _KartuBagian({required this.judul, required this.child});

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
          child,
        ],
      ),
    );
  }
}

class _LangkahStatus extends StatelessWidget {
  final String label;
  final IconData ikon;
  final String? jam;
  final bool tercapai;

  /// Langkah yang sedang berjalan (langkah terakhir yang tercapai).
  final bool aktif;
  final bool garisBerikutnya;
  final bool garisAktif;

  const _LangkahStatus({
    required this.label,
    required this.ikon,
    required this.jam,
    required this.tercapai,
    required this.aktif,
    required this.garisBerikutnya,
    required this.garisAktif,
  });

  @override
  Widget build(BuildContext context) {
    final warna = tercapai ? AppColors.biruTua : AppColors.teksSamar;

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
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: warna,
                        fontWeight: tercapai
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (aktif) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.biruMuda,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sedang berjalan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.biruTua,
                        ),
                      ),
                    ),
                  ],
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
                  Text(jam!, style: const TextStyle(fontSize: 11)),
                  const Text('Hari ini', style: TextStyle(fontSize: 11)),
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
                    color: tercapai ? AppColors.biruTua : AppColors.garisLembut,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 13,
                    color: tercapai ? Colors.white : AppColors.teksNonaktif,
                  ),
                ),
                if (garisBerikutnya)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: garisAktif
                          ? AppColors.biruTua
                          : AppColors.garisLembut,
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
        Flexible(
          child: Row(
            children: [
              Flexible(child: Text(kiri, style: gaya)),
              ?tambahan,
            ],
          ),
        ),
        const SizedBox(width: 8),
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

  /// Aksi utama digambar penuh agar menonjol dari aksi sekunder.
  final bool utama;

  const _TombolAksi({
    required this.label,
    required this.ikon,
    required this.warna,
    required this.aktif,
    required this.onTap,
    this.utama = false,
  });

  @override
  Widget build(BuildContext context) {
    final gayaTeks = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    if (utama) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: aktif ? onTap : null,
          icon: Icon(ikon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: warna,
            textStyle: gayaTeks,
          ),
        ),
      );
    }
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
          side: BorderSide(color: aktif ? warna : AppColors.garis),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
