import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/layanan.dart';
import '../../models/metode_bayar.dart';
import '../../models/tagihan_online.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/perangkat.dart';
import '../../theme/app_colors.dart';

/// Halaman bayar non-tunai lewat Xendit (QRIS, e-wallet, virtual account),
/// dipakai untuk pembayaran awal maupun pelunasan.
///
/// Tagihan dibuat di server, lalu kode QR / nomor VA / tautan e-wallet
/// ditampilkan. Status diperiksa ke server setiap
/// [OrderService.selangPeriksa]; lunas hanya bila server (Xendit) bilang
/// lunas. Halaman ditutup dengan pesanan terbaru bila berhasil, atau `null`
/// bila ditinggalkan.
class MenungguPembayaranPage extends StatefulWidget {
  final int idPesanan;
  final int idPembayaran;
  final MetodeBayar metode;
  final int nominal;

  /// Penjelasan singkat tagihan, misal "Biaya awal Cuci AC".
  final String keterangan;

  /// Kalimat setelah pembayaran berhasil.
  final String pesanBerhasil;

  const MenungguPembayaranPage({
    super.key,
    required this.idPesanan,
    required this.idPembayaran,
    required this.metode,
    required this.nominal,
    required this.keterangan,
    this.pesanBerhasil = 'Terima kasih, pembayaran kamu sudah kami terima.',
  });

  @override
  State<MenungguPembayaranPage> createState() => _MenungguPembayaranPageState();
}

class _MenungguPembayaranPageState extends State<MenungguPembayaranPage> {
  final _layanan = OrderService.instance;

  KanalBayar? _kanal;
  StatusTagihan? _tagihan;
  PesananPelanggan? _pesanan;
  bool _memuat = false;
  String? _galat;
  bool _berhasil = false;

  Timer? _timerPeriksa;
  Timer? _timerDetik;
  Timer? _timerTutup;
  bool _sedangPeriksa = false;

  InstruksiBayar? get _instruksi => _tagihan?.instruksi;

  @override
  void initState() {
    super.initState();
    if (widget.metode.kanal.length == 1) {
      // Satu pilihan saja (QRIS): langsung buat tagihan.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _buat(widget.metode.kanal.first),
      );
    }
    _timerDetik = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _instruksi != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timerPeriksa?.cancel();
    _timerDetik?.cancel();
    _timerTutup?.cancel();
    super.dispose();
  }

  Future<void> _buat(KanalBayar kanal) async {
    setState(() {
      _kanal = kanal;
      _memuat = true;
      _galat = null;
    });
    try {
      final (p, t) = await _layanan.bayarTagihan(
        widget.idPesanan,
        widget.idPembayaran,
        kanal.kode,
      );
      if (!mounted) return;
      _terapkan(p, t);
      _mulaiPeriksa();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _mulaiPeriksa() {
    _timerPeriksa?.cancel();
    _timerPeriksa = Timer.periodic(
      OrderService.selangPeriksa,
      (_) => _periksa(),
    );
  }

  Future<void> _periksa() async {
    if (_sedangPeriksa || _berhasil) return;
    _sedangPeriksa = true;
    try {
      final (p, t) = await _layanan.periksaTagihan(
        widget.idPesanan,
        widget.idPembayaran,
      );
      if (mounted) _terapkan(p, t);
    } on ApiException {
      // Koneksi putus sesaat: coba lagi di putaran berikutnya.
    } finally {
      _sedangPeriksa = false;
    }
  }

  Future<void> _simulasi() async {
    setState(() => _memuat = true);
    try {
      final (p, t) = await _layanan.simulasiBayar(
        widget.idPesanan,
        widget.idPembayaran,
      );
      if (mounted) _terapkan(p, t);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.pesan)));
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _terapkan(PesananPelanggan p, StatusTagihan t) {
    setState(() {
      _pesanan = p;
      _tagihan = t;
    });
    if (t.lunas && !_berhasil) {
      _timerPeriksa?.cancel();
      setState(() => _berhasil = true);
      // Beri jeda singkat supaya pengguna sempat melihat status berhasil.
      _timerTutup = Timer(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.of(context).pop(_pesanan);
      });
    } else if (!t.menunggu && !t.lunas) {
      _timerPeriksa?.cancel();
      setState(() => _galat = 'Tagihan ini sudah tidak berlaku.');
    }
  }

  Future<void> _bukaEWallet(String url) async {
    final terbuka = await Perangkat.bukaUrl(Uri.parse(url));
    if (!terbuka && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplikasi e-wallet tidak bisa dibuka')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruksi = _instruksi;
    final kedaluwarsa =
        _tagihan != null && _tagihan!.menunggu && instruksi == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pembayaran ${widget.metode.label}',
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
          if (widget.metode.kanal.length > 1) ...[
            _PilihKanal(
              kanal: widget.metode.kanal,
              terpilih: _kanal,
              aktif: !_memuat && !_berhasil,
              onPilih: _buat,
            ),
            const SizedBox(height: 16),
          ],
          if (_berhasil || instruksi != null)
            _KartuStatus(
              berhasil: _berhasil,
              petunjuk: _petunjukSingkat(instruksi?.jenis),
              sisa: instruksi?.kedaluwarsaPada.difference(DateTime.now()),
              pesanBerhasil: widget.pesanBerhasil,
            ),
          if (_memuat)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_galat != null)
            _KotakPesan(
              pesan: _galat!,
              tombol: _kanal != null && !_berhasil ? 'Coba Lagi' : null,
              onTekan: () => _buat(_kanal!),
            )
          else if (kedaluwarsa)
            _KotakPesan(
              pesan:
                  'Waktu pembayaran habis. Buat kode baru untuk melanjutkan.',
              tombol: 'Buat Kode Baru',
              onTekan: () => _buat(_kanal!),
            )
          else if (instruksi != null) ...[
            const SizedBox(height: 18),
            AnimatedOpacity(
              opacity: _berhasil ? 0.35 : 1,
              duration: const Duration(milliseconds: 300),
              child: switch (instruksi.jenis) {
                'va' => _NomorVa(
                  nomor: instruksi.kode ?? '-',
                  bank: instruksi.namaMetode,
                ),
                'ewallet' => _InfoEWallet(
                  nama: instruksi.namaMetode,
                  onBuka: instruksi.url == null || _berhasil
                      ? null
                      : () => _bukaEWallet(instruksi.url!),
                ),
                _ => _KodeQris(data: instruksi.kode ?? ''),
              },
            ),
          ] else if (_kanal == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Pilih ${widget.metode.label.toLowerCase()} yang ingin kamu pakai.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.teksSamar,
                ),
              ),
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
          if (instruksi != null && !_berhasil) ...[
            const SizedBox(height: 18),
            _Panduan(langkah: _langkah(instruksi.jenis)),
          ],
          if (_tagihan?.bisaSimulasi == true && instruksi != null && !_berhasil)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _memuat ? null : _simulasi,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Simulasikan Pembayaran (mode uji)'),
              ),
            ),
        ],
      ),
    );
  }

  static String _petunjukSingkat(String? jenis) => switch (jenis) {
    'ewallet' => 'Selesaikan pembayaran di aplikasi e-wallet kamu.',
    'va' => 'Transfer ke nomor virtual account di bawah.',
    _ => 'Silakan pindai kode QRIS di bawah.',
  };

  static List<String> _langkah(String jenis) => switch (jenis) {
    'ewallet' => const [
      'Tekan tombol di atas untuk membuka aplikasi e-wallet.',
      'Periksa nominal, lalu konfirmasi pembayaran.',
      'Kembali ke ACare; halaman ini lanjut otomatis.',
    ],
    'va' => const [
      'Buka m-banking, ATM, atau internet banking.',
      'Pilih transfer ke Virtual Account dan masukkan nomor di atas.',
      'Pastikan nominal sesuai; halaman ini lanjut otomatis.',
    ],
    _ => const [
      'Buka aplikasi e-wallet atau m-banking yang mendukung QRIS.',
      'Pindai kode QR di atas, lalu pastikan nominalnya sudah sesuai.',
      'Selesaikan pembayaran; halaman ini lanjut otomatis.',
    ],
  };
}

class _PilihKanal extends StatelessWidget {
  final List<KanalBayar> kanal;
  final KanalBayar? terpilih;
  final bool aktif;
  final ValueChanged<KanalBayar> onPilih;

  const _PilihKanal({
    required this.kanal,
    required this.terpilih,
    required this.aktif,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in kanal)
          ChoiceChip(
            label: Text(k.nama),
            selected: terpilih?.kode == k.kode,
            onSelected: aktif && terpilih?.kode != k.kode
                ? (_) => onPilih(k)
                : null,
          ),
      ],
    );
  }
}

class _KotakPesan extends StatelessWidget {
  final String pesan;
  final String? tombol;
  final VoidCallback onTekan;

  const _KotakPesan({required this.pesan, this.tombol, required this.onTekan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.biruMuda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pesan,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          if (tombol != null) ...[
            const SizedBox(height: 10),
            FilledButton(onPressed: onTekan, child: Text(tombol!)),
          ],
        ],
      ),
    );
  }
}

class _KartuStatus extends StatelessWidget {
  final bool berhasil;
  final String petunjuk;
  final Duration? sisa;
  final String pesanBerhasil;

  const _KartuStatus({
    required this.berhasil,
    required this.petunjuk,
    required this.sisa,
    required this.pesanBerhasil,
  });

  static String _format(Duration d) {
    final s = d.isNegative ? Duration.zero : d;
    final menit = s.inMinutes.toString().padLeft(2, '0');
    final detik = (s.inSeconds % 60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

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
                      : '$petunjuk Bayar sebelum ${_format(sisa ?? Duration.zero)}.',
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

/// Kode QRIS dari Xendit, digambar sebagai QR yang bisa dipindai.
class _KodeQris extends StatelessWidget {
  final String data;

  const _KodeQris({required this.data});

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
            QrImageView(
              key: const Key('kode-qris'),
              data: data,
              size: 220,
              backgroundColor: Colors.white,
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
  final String nama;
  final VoidCallback? onBuka;

  const _InfoEWallet({required this.nama, required this.onBuka});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
            'Lanjutkan pembayaran di aplikasi $nama',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onBuka,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text('Buka $nama'),
          ),
        ],
      ),
    );
  }
}

class _NomorVa extends StatelessWidget {
  final String nomor;
  final String bank;

  const _NomorVa({required this.nomor, required this.bank});

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
            'Nomor $bank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.teksSamar,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  nomor,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: nomor));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin'),
              ),
            ],
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
