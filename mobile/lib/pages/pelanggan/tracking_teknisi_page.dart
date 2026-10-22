import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/teknisi.dart';
import '../../services/perangkat.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_info_card.dart';
import 'chat_teknisi_page.dart';
import 'detail_pesanan_page.dart';

/// Halaman peta teknisi menuju lokasi.
///
/// Setelah [lamaTampil] halaman ini otomatis pindah ke [DetailPesananPage],
/// yang lalu menampilkan status pekerjaan secara berurutan.
class TrackingTeknisiPage extends StatefulWidget {
  final Teknisi teknisi;

  /// Lama dummy sebelum layar detail pesanan muncul.
  final Duration lamaTampil;

  const TrackingTeknisiPage({
    super.key,
    required this.teknisi,
    this.lamaTampil = const Duration(seconds: 5),
  });

  @override
  State<TrackingTeknisiPage> createState() => _TrackingTeknisiPageState();
}

class _TrackingTeknisiPageState extends State<TrackingTeknisiPage> {
  Timer? _timerPindah;

  @override
  void initState() {
    super.initState();
    _timerPindah = Timer(widget.lamaTampil, _keDetailPesanan);
  }

  @override
  void dispose() {
    _timerPindah?.cancel();
    super.dispose();
  }

  /// Ganti halaman tracking dengan detail pesanan di stack, supaya tombol
  /// back dari detail pesanan tidak kembali ke peta tracking.
  void _keDetailPesanan() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            DetailPesananPage(teknisi: widget.teknisi, bisaDibatalkan: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teknisi = widget.teknisi;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header biru + estimasi tiba
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.biru,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teknisi Menuju Lokasi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Sedang dalam perjalanan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.hijauMuda,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: AppColors.hijau,
                              size: 26,
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimasi Tiba',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  '20 Menit lagi',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Peta OpenStreetMap
          const Expanded(child: _PetaTeknisi()),

          // Kartu teknisi
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD5D9DE)),
              ),
              child: TeknisiInfoCard(
                teknisi: teknisi,
                onPesan: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatTeknisiPage(teknisi: teknisi),
                  ),
                ),
                onTelepon: () => teleponKe(context, teknisi.telepon),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Peta OpenStreetMap: posisi teknisi menuju lokasi pelanggan.
class _PetaTeknisi extends StatelessWidget {
  const _PetaTeknisi();

  // Data dummy, nanti diganti posisi realtime dari API
  static const _lokasiPelanggan = LatLng(1.0436, 103.9806); // Batu Aji, Batam
  static const _lokasiTeknisi = LatLng(1.0505, 103.9722);
  static const _rute = [
    LatLng(1.0505, 103.9722),
    LatLng(1.0490, 103.9745),
    LatLng(1.0470, 103.9760),
    LatLng(1.0455, 103.9790),
    LatLng(1.0436, 103.9806),
  ];

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(1.0470, 103.9764),
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.acare_mobile',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _rute,
              strokeWidth: 4,
              color: const Color(0xFF2F6BE0),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _lokasiPelanggan,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                size: 38,
                color: AppColors.merah,
              ),
            ),
            Marker(
              point: _lokasiTeknisi,
              width: 140,
              height: 70,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      'Teknisi sedang menuju lokasi',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.hijau,
                    child: Icon(
                      Icons.two_wheeler,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
