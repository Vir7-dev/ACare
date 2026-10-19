import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/status_layanan.dart';
import '../../models/teknisi.dart';
import '../../services/perangkat.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pesanan_berlangsung_card.dart';
import '../../widgets/servis_terakhir_card.dart';
import 'chat_teknisi_page.dart';
import 'detail_layanan_page.dart';
import 'detail_pesanan_page.dart';
import 'mencari_teknisi_page.dart';
import 'tracking_teknisi_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  // Data dummy, nanti diganti daftar lokasi tersimpan dari API / GPS
  static const _daftarLokasi = [
    'Batu Aji, Batam',
    'Nagoya, Batam',
    'Batam Centre, Batam',
    'Sekupang, Batam',
    'Tiban, Batam',
  ];

  static const _lokasiSaatIni = '__lokasi_saat_ini__';

  String? _lokasi;
  String? _nama;
  bool _mencariLokasi = false;

  @override
  void initState() {
    super.initState();
    _muatSesi();
  }

  Future<void> _muatSesi() async {
    final lokasi = await SesiPengguna.lokasi();
    final nama = await SesiPengguna.nama();
    if (!mounted) return;
    setState(() {
      _lokasi = lokasi;
      _nama = nama;
    });
  }

  Future<void> _simpanLokasi(String lokasi) async {
    setState(() => _lokasi = lokasi);
    await SesiPengguna.simpanLokasi(lokasi);
  }

  Future<void> _pakaiLokasiSaatIni() async {
    setState(() => _mencariLokasi = true);
    try {
      final lokasi = await Perangkat.lokasiSaatIni();
      if (!mounted) return;
      await _simpanLokasi(lokasi);
    } on LokasiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan lokasi saat ini')),
      );
    } finally {
      if (mounted) setState(() => _mencariLokasi = false);
    }
  }

  Future<void> _pilihLokasi() async {
    final dipilih = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Pilih Lokasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.my_location,
                color: AppColors.biruAksen,
              ),
              title: const Text('Gunakan lokasi saya saat ini'),
              onTap: () => Navigator.of(context).pop(_lokasiSaatIni),
            ),
            const Divider(height: 1),
            for (final l in _daftarLokasi)
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(l),
                trailing: l == _lokasi
                    ? const Icon(Icons.check, color: AppColors.biruAksen)
                    : null,
                onTap: () => Navigator.of(context).pop(l),
              ),
          ],
        ),
      ),
    );
    if (dipilih == null) return;
    if (dipilih == _lokasiSaatIni) {
      await _pakaiLokasiSaatIni();
    } else {
      await _simpanLokasi(dipilih);
    }
  }

  void _bukaNotifikasi() {
    // Data dummy, nanti diganti notifikasi dari API
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Notifikasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.two_wheeler, color: AppColors.hijau),
              title: Text('Teknisi menuju lokasimu'),
              subtitle: Text('GanAnWo tiba sekitar 12 menit lagi'),
            ),
            const ListTile(
              leading: Icon(Icons.schedule, color: AppColors.biruAksen),
              title: Text('Waktunya servis berkala'),
              subtitle: Text('Sudah 3 bulan sejak Cuci AC terakhir'),
            ),
          ],
        ),
      ),
    );
  }

  void _buka(BuildContext context, Widget halaman) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));
  }

  void _cariTeknisi(BuildContext context, Layanan layanan) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MencariTeknisiPage(layanan: layanan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Lokasi + notifikasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: _pilihLokasi,
                    iconAlignment: IconAlignment.start,
                    icon: const Icon(Icons.location_on_outlined, size: 16),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _mencariLokasi
                                ? 'Mencari lokasi...'
                                : (_lokasi ?? 'Pilih Lokasi'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E6EE)),
                      shape: const StadiumBorder(),
                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E6EE)),
                      ),
                      child: IconButton(
                        onPressed: _bukaNotifikasi,
                        icon: const Icon(Icons.notifications_none, size: 20),
                      ),
                    ),
                    Positioned(
                      right: 9,
                      top: 9,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.biruAksen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Selamat Datang, ${_nama ?? 'Pengguna'}!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Dinginnya Pas, Servisnya Puas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            ServisTerakhirCard(
              layanan: 'Cuci AC',
              tanggal: '12 Sep 2026',
              pesan: 'Sudah masuk siklus 3 bulan. Waktunya dicuci lagi!',
              onJadwalkanUlang: () => _cariTeknisi(context, daftarLayanan[0]),
            ),
            const SizedBox(height: 20),

            // Kategori layanan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9EDF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kategori Layanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DetailLayananPage(),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Lihat Detail',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.biruAksen,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.biruAksen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, c) {
                      const jarak = 10.0;
                      final lebar = (c.maxWidth - jarak * 2) / 3;
                      return Wrap(
                        spacing: jarak,
                        runSpacing: jarak,
                        children: [
                          for (final l in daftarLayanan)
                            SizedBox(
                              width: lebar,
                              child: _KategoriItem(
                                layanan: l,
                                onTap: () => _cariTeknisi(context, l),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sedang berlangsung
            Row(
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.hijau),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sedang Berlangsung',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hijauMuda,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Menuju Lokasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.hijau,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PesananBerlangsungCard(
              namaTeknisi: teknisiDummy.nama,
              rating: teknisiDummy.rating,
              jumlahUlasan: teknisiDummy.jumlahUlasan,
              kendaraan: '${teknisiDummy.kendaraan} • ${teknisiDummy.plat}',
              estimasi: '12 Menit lagi',
              // TODO: status pesanan diambil dari API
              onTap: () => _buka(
                context,
                const DetailPesananPage(
                  status: StatusLayanan.menungguPembayaran,
                ),
              ),
              onChat: () =>
                  _buka(context, const ChatTeknisiPage(teknisi: teknisiDummy)),
              onLacakPeta: () => _buka(
                context,
                const TrackingTeknisiPage(teknisi: teknisiDummy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KategoriItem extends StatelessWidget {
  final Layanan layanan;
  final VoidCallback onTap;

  const _KategoriItem({required this.layanan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: layanan.warnaLatar, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: layanan.warnaLatar,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(layanan.ikon, color: layanan.warnaIkon),
            ),
            const SizedBox(height: 8),
            Text(
              layanan.nama,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
