import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Peta OpenStreetMap sederhana dengan penanda teknisi dan (opsional)
/// pelanggan.
class PetaLokasi extends StatelessWidget {
  final LatLng posisiTeknisi;
  final LatLng? posisiPelanggan;
  final double zoom;

  /// Dimatikan di test supaya tidak memuat ubin peta dari internet.
  static bool aktif = true;

  const PetaLokasi({
    super.key,
    this.posisiTeknisi = const LatLng(1.1283, 104.0530), // Batam Centre
    this.posisiPelanggan,
    this.zoom = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!aktif) {
      return Container(
        color: AppColors.garisLembut,
        alignment: Alignment.center,
        child: const Icon(Icons.map_outlined, color: AppColors.teksSamar),
      );
    }
    final tujuan = posisiPelanggan;
    return FlutterMap(
      options: MapOptions(
        initialCenter: tujuan == null
            ? posisiTeknisi
            : LatLng(
                (posisiTeknisi.latitude + tujuan.latitude) / 2,
                (posisiTeknisi.longitude + tujuan.longitude) / 2,
              ),
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.acare.mobile',
        ),
        MarkerLayer(
          markers: [
            if (tujuan != null)
              Marker(
                point: tujuan,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  size: 38,
                  color: AppColors.merah,
                ),
              ),
            Marker(
              point: posisiTeknisi,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.biruTua,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}
