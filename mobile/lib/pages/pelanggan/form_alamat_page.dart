import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../services/alamat_service.dart';
import '../../services/perangkat.dart';
import '../../theme/app_colors.dart';
import '../../widgets/peta_lokasi.dart';

/// Tambah atau ubah alamat layanan dengan titik lokasi di peta (UC-08).
/// Halaman ditutup dengan [AlamatTersimpan] yang disimpan.
class FormAlamatPage extends StatefulWidget {
  /// Alamat yang diubah; `null` untuk menambah alamat baru.
  final AlamatTersimpan? alamat;

  const FormAlamatPage({super.key, this.alamat});

  @override
  State<FormAlamatPage> createState() => _FormAlamatPageState();
}

class _FormAlamatPageState extends State<FormAlamatPage> {
  static const _labelCepat = ['Rumah', 'Kantor', 'Kos'];

  final _formKey = GlobalKey<FormState>();
  final _peta = MapController();
  late final _label = TextEditingController(text: widget.alamat?.label ?? '');
  late final _alamat = TextEditingController(
    text: widget.alamat?.alamatLengkap ?? '',
  );
  final _cari = TextEditingController();

  late LatLng _titik = widget.alamat == null
      ? const LatLng(1.1283, 104.0530) // Batam Centre
      : LatLng(widget.alamat!.latitude, widget.alamat!.longitude);

  bool _memuat = false;

  @override
  void dispose() {
    _label.dispose();
    _alamat.dispose();
    _cari.dispose();
    super.dispose();
  }

  void _pindahKe(LatLng titik) {
    setState(() => _titik = titik);
    if (PetaLokasi.aktif) _peta.move(titik, 16);
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _cariAlamat() async {
    final teks = _cari.text.trim();
    if (teks.isEmpty) return;
    setState(() => _memuat = true);
    final hasil = await Perangkat.cariAlamat(teks);
    if (!mounted) return;
    setState(() => _memuat = false);
    if (hasil == null) {
      _pesan('Alamat tidak ditemukan, coba kata kunci lain');
      return;
    }
    _pindahKe(hasil);
    if (_alamat.text.trim().isEmpty) _alamat.text = teks;
  }

  Future<void> _lokasiSaya() async {
    setState(() => _memuat = true);
    try {
      _pindahKe(await Perangkat.koordinatSaatIni());
    } on LokasiException catch (e) {
      _pesan(e.pesan);
    } catch (_) {
      _pesan('Gagal mendapatkan lokasi saat ini');
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final layanan = AlamatService.instance;
    final lama = widget.alamat;
    final AlamatTersimpan hasil;
    if (lama == null) {
      hasil = layanan.tambah(
        label: _label.text.trim(),
        alamatLengkap: _alamat.text.trim(),
        latitude: _titik.latitude,
        longitude: _titik.longitude,
      );
    } else {
      if (layanan.dipakaiPesananAktif(lama)) {
        _pesan(
          'Alamat sedang dipakai pesanan aktif. Tambahkan alamat baru '
          'bila ingin memakai lokasi lain.',
        );
        return;
      }
      hasil = lama.copyWith(
        label: _label.text.trim(),
        alamatLengkap: _alamat.text.trim(),
        latitude: _titik.latitude,
        longitude: _titik.longitude,
      );
      layanan.simpan(hasil);
    }
    _pesan('Alamat berhasil disimpan');
    Navigator.of(context).pop(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.alamat == null ? 'Tambah Alamat' : 'Ubah Alamat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(child: _petaPilih()),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _cari,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _cariAlamat(),
                        decoration: InputDecoration(
                          hintText: 'Cari alamat atau tempat',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _memuat
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'lokasi_saya',
                      tooltip: 'Lokasi saya saat ini',
                      onPressed: _lokasiSaya,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.biruTua,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Ketuk peta untuk menandai titik lokasi layanan.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.teksSamar,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Label Alamat', style: _judul),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final l in _labelCepat)
                        ChoiceChip(
                          label: Text(l),
                          selected: _label.text == l,
                          onSelected: (_) => setState(() => _label.text = l),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _label,
                    maxLength: 50,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Atau tulis label sendiri',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: _wajib,
                  ),
                  const SizedBox(height: 8),
                  Text('Alamat Lengkap', style: _judul),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _alamat,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Nama jalan, nomor rumah, blok, patokan',
                      border: OutlineInputBorder(),
                    ),
                    validator: _wajib,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _simpan,
            style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
            child: const Text('Simpan'),
          ),
        ),
      ),
    );
  }

  static String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Kolom ini wajib diisi.' : null;

  Widget _petaPilih() {
    if (!PetaLokasi.aktif) {
      return GestureDetector(
        onTap: () => _pindahKe(_titik),
        child: Container(
          color: AppColors.garisLembut,
          alignment: Alignment.center,
          child: const Icon(Icons.location_on, color: AppColors.merah),
        ),
      );
    }
    return FlutterMap(
      mapController: _peta,
      options: MapOptions(
        initialCenter: _titik,
        initialZoom: 16,
        onTap: (_, titik) => setState(() => _titik = titik),
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
            Marker(
              point: _titik,
              width: 44,
              height: 44,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_on,
                size: 44,
                color: AppColors.merah,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final _judul = GoogleFonts.plusJakartaSans(
  fontSize: 13,
  fontWeight: FontWeight.w700,
);
