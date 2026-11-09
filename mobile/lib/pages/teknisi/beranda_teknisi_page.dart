import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/layanan.dart';
import '../../models/pesanan_teknisi.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';
import 'pengerjaan_page.dart';

class BerandaTeknisiPage extends StatefulWidget {
  const BerandaTeknisiPage({super.key});

  @override
  State<BerandaTeknisiPage> createState() => _BerandaTeknisiPageState();
}

class _BerandaTeknisiPageState extends State<BerandaTeknisiPage> {
  static const _lokasiTeknisi = LatLng(1.0470, 103.9764);
  static const _lokasiPelanggan = LatLng(1.0455, 103.9790);

  final _service = TeknisiService.instance;
  final _peta = MapController();
  Timer? _timer;
  int _sisaDetik = 0;

  @override
  void initState() {
    super.initState();
    _service.periksaPesananMasuk();
    _service.addListener(_hitungMundur);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _hitungMundur());
    _hitungMundur();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _service.removeListener(_hitungMundur);
    _peta.dispose();
    super.dispose();
  }

  void _hitungMundur() {
    final batas = _service.batasMasuk;
    final sisa = batas == null
        ? 0
        : batas.difference(DateTime.now()).inSeconds.clamp(0, 999);
    if (batas != null && sisa == 0) {
      _service.tolakPesanan();
      return;
    }
    if (mounted && sisa != _sisaDetik) setState(() => _sisaDetik = sisa);
  }

  void _terima() {
    if (!_service.terimaPesanan()) return;
    _bukaPengerjaan();
  }

  void _bukaPengerjaan() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PengerjaanPage()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final masuk = _service.pesananMasuk;
        final aktif = _service.pesananAktif;
        return Scaffold(
          appBar: appBarTeknisi(
            'Beranda',
            tampilkanKembali: false,
            aksi: [
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Belum ada notifikasi.')),
                  );
                },
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(child: _petaLayar(aktif != null || masuk != null)),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: _KartuStatus(service: _service),
              ),
              Positioned(
                right: 12,
                top: 96,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    tooltip: 'Pusatkan peta',
                    onPressed: () => _peta.move(_lokasiTeknisi, 15),
                    icon: const Icon(Icons.my_location, size: 20),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(top: false, child: _panelBawah(masuk, aktif)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _petaLayar(bool tampilkanPelanggan) {
    return FlutterMap(
      mapController: _peta,
      options: const MapOptions(
        initialCenter: _lokasiTeknisi,
        initialZoom: 15,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.acare_mobile',
        ),
        MarkerLayer(
          markers: [
            const Marker(
              point: _lokasiTeknisi,
              width: 36,
              height: 36,
              child: Icon(
                Icons.two_wheeler,
                size: 30,
                color: AppColors.biruAksen,
              ),
            ),
            if (tampilkanPelanggan)
              const Marker(
                point: _lokasiPelanggan,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_on,
                  size: 38,
                  color: AppColors.merah,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _panelBawah(PesananTeknisi? masuk, PesananTeknisi? aktif) {
    if (aktif != null) {
      return _PanelAktif(pesanan: aktif, onTap: _bukaPengerjaan);
    }
    if (masuk != null) {
      return _PanelPesananMasuk(
        pesanan: masuk,
        sisaDetik: _sisaDetik,
        onTolak: _service.tolakPesanan,
        onTerima: _terima,
      );
    }
    return _PanelMenunggu(online: _service.online);
  }
}

const _sudutAtas = BorderRadius.vertical(top: Radius.circular(16));

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: _sudutAtas,
      ),
      child: child,
    );
  }
}

class _KartuStatus extends StatelessWidget {
  const _KartuStatus({required this.service});

  final TeknisiService service;

  @override
  Widget build(BuildContext context) {
    final online = service.online;
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pendapatan hari ini', style: gayaSamar(ukuran: 11)),
                  Text(
                    rupiah(service.pendapatanHariIni),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.biruAksen,
                    ),
                  ),
                  Text(
                    '${service.orderSelesaiHariIni} dari ${service.targetOrder} '
                    'order selesai',
                    style: gayaSamar(ukuran: 11),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  online ? 'Online' : 'Offline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: online ? AppColors.hijau : AppColors.teksSamar,
                  ),
                ),
                Switch(
                  value: online,
                  onChanged: service.pesananAktif != null
                      ? null
                      : (v) {
                          service.setOnline(v);
                          if (v) service.periksaPesananMasuk();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelMenunggu extends StatelessWidget {
  const _PanelMenunggu({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Text(
        online
            ? 'Menunggu pesanan masuk di sekitar Anda.'
            : 'Anda sedang offline. Aktifkan status online untuk menerima '
                  'pesanan.',
        style: gayaSamar(ukuran: 13),
      ),
    );
  }
}

class _PanelAktif extends StatelessWidget {
  const _PanelAktif({required this.pesanan, required this.onTap});

  final PesananTeknisi pesanan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan sedang berjalan', style: gayaJudul()),
                const SizedBox(height: 2),
                Text(
                  '${pesanan.pelanggan}  •  ${pesanan.tahap.label}',
                  style: gayaSamar(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: TombolUtama('Lanjutkan', onTap)),
        ],
      ),
    );
  }
}

class _PanelPesananMasuk extends StatelessWidget {
  const _PanelPesananMasuk({
    required this.pesanan,
    required this.sisaDetik,
    required this.onTolak,
    required this.onTerima,
  });

  final PesananTeknisi pesanan;
  final int sisaDetik;
  final VoidCallback onTolak;
  final VoidCallback onTerima;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pesanan masuk', style: gayaJudul(ukuran: 17)),
              ),
              Text(
                'Sisa $sisaDetik dtk',
                key: const Key('sisa-waktu'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sisaDetik <= 10 ? AppColors.merah : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pesanan.layanan, style: gayaJudul()),
                    Text(pesanan.deskripsiLayanan, style: gayaSamar()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Ongkos awal', style: gayaSamar()),
                  Text(
                    rupiah(pesanan.ongkosAwal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.biruAksen,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Biaya perbaikan bisa bertambah setelah diagnosis.',
            style: gayaSamar(),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(pesanan.pelanggan)),
              const Icon(Icons.star, size: 15, color: Color(0xFFF59E0B)),
              const SizedBox(width: 3),
              Text(pesanan.ratingPelanggan, style: gayaSamar()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pesanan.alamat),
                    Text(
                      '${pesanan.wilayah}  •  ${pesanan.jarakKm} km, '
                      '${pesanan.estimasiMenit} menit',
                      style: gayaSamar(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFD1D5DB), width: 3),
              ),
            ),
            child: Text(
              'Catatan pelanggan: ${pesanan.catatanMasalah}',
              style: gayaSamar(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 2, child: TombolSekunder('Tolak', onTolak)),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: TombolUtama('Terima pesanan', onTerima)),
            ],
          ),
        ],
      ),
    );
  }
}
