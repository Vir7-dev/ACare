import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/alamat.dart';
import '../../services/alamat_service.dart';
import '../../services/perangkat.dart';
import '../../theme/app_colors.dart';

/// Tambah atau ubah alamat: tandai titik di peta OpenStreetMap, isi label dan
/// alamat lengkap. Mengembalikan [AlamatTersimpan] yang tersimpan, atau null
/// bila dibatalkan.
class FormAlamatPage extends StatefulWidget {
  const FormAlamatPage({super.key, this.awal});

  final AlamatTersimpan? awal;

  @override
  State<FormAlamatPage> createState() => _FormAlamatPageState();
}

class _FormAlamatPageState extends State<FormAlamatPage> {
  /// Batam Centre; dipakai bila belum ada titik dan GPS belum dipakai.
  static const _titikAwal = LatLng(1.1301, 104.0529);
  static const _labelCepat = ['Rumah', 'Kantor', 'Kos'];

  final _kunci = GlobalKey<FormState>();
  final _peta = MapController();
  final _label = TextEditingController();
  final _alamat = TextEditingController();
  final _cari = TextEditingController();

  late LatLng _titik;
  List<HasilTempat> _hasil = const [];
  bool _mencari = false;
  bool _memuatGps = false;
  bool _memuatNama = false;
  String? _pesanPeta;

  bool get _ubah => widget.awal != null;

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    _titik = a == null ? _titikAwal : LatLng(a.latitude, a.longitude);
    if (a != null) {
      _label.text = a.label;
      _alamat.text = a.alamatLengkap;
    }
  }

  @override
  void dispose() {
    _peta.dispose();
    _label.dispose();
    _alamat.dispose();
    _cari.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _cariTempat() async {
    final kata = _cari.text.trim();
    if (kata.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _mencari = true;
      _pesanPeta = null;
      _hasil = const [];
    });
    try {
      final hasil = await Perangkat.cariTempat(kata);
      if (!mounted) return;
      setState(() {
        _hasil = hasil;
        _pesanPeta = hasil.isEmpty ? 'Tempat tidak ditemukan' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _pesanPeta = 'Pencarian gagal, periksa koneksi internet');
    } finally {
      if (mounted) setState(() => _mencari = false);
    }
  }

  void _pilihHasil(HasilTempat h) {
    final titik = LatLng(h.latitude, h.longitude);
    setState(() {
      _hasil = const [];
      _titik = titik;
      _alamat.text = h.nama;
    });
    _peta.move(titik, 17);
  }

  /// Menandai titik baru; alamat diisi otomatis bila masih kosong.
  Future<void> _tandai(LatLng titik) async {
    setState(() => _titik = titik);
    if (_alamat.text.trim().isNotEmpty) return;
    setState(() => _memuatNama = true);
    try {
      final nama = await Perangkat.alamatDariKoordinat(titik);
      if (!mounted) return;
      if (nama != null && _alamat.text.trim().isEmpty) {
        setState(() => _alamat.text = nama);
      }
    } catch (_) {
      // Pengguna tetap bisa mengetik alamat sendiri.
    } finally {
      if (mounted) setState(() => _memuatNama = false);
    }
  }

  Future<void> _pakaiGps() async {
    setState(() => _memuatGps = true);
    try {
      final titik = await Perangkat.koordinatSaatIni();
      if (!mounted) return;
      _peta.move(titik, 17);
      await _tandai(titik);
    } on LokasiException catch (e) {
      if (mounted) _pesan(e.pesan);
    } catch (_) {
      if (mounted) _pesan('Gagal mendapatkan lokasi saat ini');
    } finally {
      if (mounted) setState(() => _memuatGps = false);
    }
  }

  Future<void> _simpan() async {
    if (!_kunci.currentState!.validate()) return;
    final service = AlamatService.instance;
    final AlamatTersimpan hasil;
    if (_ubah) {
      hasil = widget.awal!.salin(
        label: _label.text.trim(),
        alamatLengkap: _alamat.text.trim(),
        latitude: _titik.latitude,
        longitude: _titik.longitude,
      );
      await service.ubah(hasil);
    } else {
      hasil = await service.tambah(
        label: _label.text,
        alamatLengkap: _alamat.text,
        latitude: _titik.latitude,
        longitude: _titik.longitude,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(hasil);
  }

  String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Kolom ini wajib diisi.' : null;

  InputDecoration _hias(String hint, {IconData? ikon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
    prefixIcon: ikon == null ? null : Icon(ikon, size: 18),
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF0F6FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF80C9F5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF80C9F5)),
    ),
  );

  Widget _judul(String teks) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      teks,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          _ubah ? 'Ubah Alamat' : 'Tambah Alamat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SizedBox(height: 330, child: _bagianPeta()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Form(
              key: _kunci,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ketuk peta atau geser untuk menandai titik lokasi layanan.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.teksSamar,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _judul('Label alamat'),
                  TextFormField(
                    controller: _label,
                    maxLength: AlamatTersimpan.maksLabel,
                    validator: _wajib,
                    decoration: _hias(
                      'Contoh: Rumah',
                      ikon: Icons.label_outline,
                    ).copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final l in _labelCepat)
                        ActionChip(
                          label: Text(l),
                          onPressed: () => setState(() => _label.text = l),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _judul('Alamat lengkap'),
                  TextFormField(
                    controller: _alamat,
                    maxLines: 3,
                    validator: _wajib,
                    decoration: _hias(
                      'Jalan, nomor, kelurahan, kota',
                      ikon: Icons.location_on_outlined,
                    ),
                  ),
                  if (_memuatNama)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Mencari nama alamat dari titik...',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.biru,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bagianPeta() {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _peta,
            options: MapOptions(
              initialCenter: _titik,
              initialZoom: 16,
              onTap: (_, titik) => _tandai(titik),
              interactionOptions: const InteractionOptions(
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
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Column(
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _cari,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _cariTempat(),
                  decoration: InputDecoration(
                    hintText: 'Cari alamat atau tempat',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _mencari
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Cari',
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            onPressed: _cariTempat,
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_hasil.isNotEmpty || _pesanPeta != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: _hasil.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                _pesanPeta!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: [
                                for (final h in _hasil)
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.place_outlined,
                                      size: 18,
                                    ),
                                    title: Text(
                                      h.nama,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => _pilihHasil(h),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 28,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: _memuatGps
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Gunakan lokasi saya',
                    onPressed: _pakaiGps,
                    icon: const Icon(Icons.my_location, size: 20),
                  ),
          ),
        ),
      ],
    );
  }
}
