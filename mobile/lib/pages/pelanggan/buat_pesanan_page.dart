import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../services/order_service.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';
import 'ringkasan_pembayaran_page.dart';

/// Form detail pesanan: dipilih dari "Lihat Detail" atau kategori di beranda.
///
/// Alur: pilih layanan -> [BuatPesananPage] -> RingkasanPembayaranPage ->
/// MencariTeknisiPage -> Beranda.
class BuatPesananPage extends StatefulWidget {
  const BuatPesananPage({super.key, required this.layanan, this.alamatAwal});

  final Layanan layanan;

  /// Alamat dari lokasi beranda; kalau null dibaca dari [SesiPengguna].
  final String? alamatAwal;

  @override
  State<BuatPesananPage> createState() => _BuatPesananPageState();
}

class _BuatPesananPageState extends State<BuatPesananPage> {
  static const Color biru = Color(0xFF0788D1);

  static const List<String> _keluhan = [
    'Tidak dingin',
    'Bocor air',
    'Bunyi berisik',
    'Mati total',
    'Lainnya',
  ];

  static const List<String> _jenisFreon = ['R32', 'R410A', 'R22'];

  final _formKey = GlobalKey<FormState>();
  final _detailAlamat = TextEditingController();
  final _merek = TextEditingController();
  final _catatan = TextEditingController();

  late final Layanan _layanan = widget.layanan;
  int _jumlahUnit = 1;
  JenisAc? _jenisAc;
  double? _pk;
  JenisBongkarPasang _bongkarPasang = JenisBongkarPasang.pasangBaru;

  final Set<String> _keluhanDipilih = {};
  String? _freon;
  bool _sekarang = true;
  DateTime? _tanggalJadwal;
  TimeOfDay? _jamJadwal;
  String? _fotoKondisi;

  String? _errorJenisAc;
  String? _errorPk;
  String? _errorFreon;

  String _alamat = '';

  /// Cuci AC hanya butuh data AC; Service AC & Cek AC butuh keluhan.
  bool get _perluKeluhan =>
      _layanan.nama == 'Service AC' || _layanan.nama == 'Cek AC';

  bool get _perluFreon => _layanan.nama == 'Isi Freon';

  bool get _perluBongkarPasang => _layanan.nama == 'Bongkar Pasang';

  @override
  void initState() {
    super.initState();
    _muatAlamat();
  }

  Future<void> _muatAlamat() async {
    final awal = widget.alamatAwal;
    if (awal != null && awal.trim().isNotEmpty) {
      setState(() => _alamat = awal.trim());
      return;
    }
    final dariSesi = await SesiPengguna.lokasi();
    if (!mounted) return;
    setState(() {
      _alamat = (dariSesi == null || dariSesi.trim().isEmpty)
          ? 'Lokasi belum diatur'
          : dariSesi.trim();
    });
  }

  @override
  void dispose() {
    _detailAlamat.dispose();
    _merek.dispose();
    _catatan.dispose();
    super.dispose();
  }

  /// Jadwal yang dipakai pesanan: sekarang atau tanggal + jam pilihan.
  DateTime get _jadwal {
    if (_sekarang) return DateTime.now();
    final tgl = _tanggalJadwal ?? DateTime.now();
    final jam = _jamJadwal ?? TimeOfDay.now();
    return DateTime(tgl.year, tgl.month, tgl.day, jam.hour, jam.minute);
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggalJadwal ?? sekarang,
      firstDate: DateTime(sekarang.year, sekarang.month, sekarang.day),
      lastDate: sekarang.add(const Duration(days: 30)),
      helpText: 'Pilih tanggal servis',
    );
    if (hasil != null && mounted) setState(() => _tanggalJadwal = hasil);
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: _jamJadwal ?? TimeOfDay.now(),
      helpText: 'Pilih jam servis',
    );
    if (hasil != null && mounted) setState(() => _jamJadwal = hasil);
  }

  void _tambahFoto() {
    // TODO(image_picker): pakai Perangkat.ambilFoto() lalu tampilkan pratinjau.
    setState(() => _fotoKondisi = 'foto_kondisi_ac.jpg');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto kondisi AC (dummy) ditambahkan')),
    );
  }

  void _lanjut() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorJenisAc = _jenisAc == null ? 'Jenis AC wajib dipilih' : null;
      _errorPk = _pk == null ? 'Kapasitas PK wajib dipilih' : null;
      _errorFreon = _perluFreon && _freon == null
          ? 'Jenis freon wajib dipilih'
          : null;
    });
    if (_errorJenisAc != null || _errorPk != null || _errorFreon != null) {
      _pesanValidasi('Lengkapi data AC terlebih dahulu');
      return;
    }
    if (!_sekarang && (_tanggalJadwal == null || _jamJadwal == null)) {
      _pesanValidasi('Lengkapi tanggal dan jam servis');
      return;
    }

    FocusScope.of(context).unfocus();

    final pesanan = PesananPelanggan(
      layanan: _layanan,
      jumlahUnit: _jumlahUnit,
      jenisAc: _jenisAc!,
      pk: _pk!,
      merek: _merek.text.trim().isEmpty ? null : _merek.text.trim(),
      alamat: _alamat,
      detailAlamat: _detailAlamat.text.trim(),
      jadwal: _jadwal,
      catatan: _catatanPesanan(),
      metodeBayar: '',
      totalEstimasi: OrderService.hitungTotalEstimasi(_layanan, _jumlahUnit),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RingkasanPembayaranPage(pesanan: pesanan),
      ),
    );
  }

  /// Gabungan isian khusus layanan + catatan tambahan.
  String? _catatanPesanan() {
    final bagian = <String>[];
    if (_keluhanDipilih.isNotEmpty) {
      bagian.add('Keluhan: ${_keluhanDipilih.join(', ')}');
    }
    if (_freon != null) bagian.add('Freon: $_freon');
    if (_layanan.nama == 'Bongkar Pasang') {
      bagian.add('Jenis pekerjaan: ${_bongkarPasang.label}');
    }
    final tambahan = _catatan.text.trim();
    if (tambahan.isNotEmpty) bagian.add(tambahan);
    return bagian.isEmpty ? null : bagian.join('\n');
  }

  void _pesanValidasi(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
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
          'Detail Pesanan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEF0F4)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _kartuLayanan(),
            const SizedBox(height: 20),
            _judul('Data AC'),
            _stepperJumlahUnit(),
            const SizedBox(height: 12),
            _pilihanJenisAc(),
            if (_errorJenisAc != null) _teksError(_errorJenisAc!),
            const SizedBox(height: 12),
            _pilihanPk(),
            if (_errorPk != null) _teksError(_errorPk!),
            const SizedBox(height: 12),
            _input(
              label: 'Merek AC (opsional)',
              hint: 'Contoh: Daikin, Panasonic',
              icon: Icons.business_outlined,
              controller: _merek,
              validator: (_) => null,
            ),
            if (_perluKeluhan) ...[
              const SizedBox(height: 20),
              _judul('Keluhan'),
              _checklistKeluhan(),
            ],
            if (_perluFreon) ...[
              const SizedBox(height: 20),
              _judul('Jenis Freon'),
              _pilihanFreon(),
              if (_errorFreon != null) _teksError(_errorFreon!),
            ],
            if (_perluBongkarPasang) ...[
              const SizedBox(height: 20),
              _judul('Jenis Pekerjaan'),
              _pilihanBongkarPasang(),
            ],
            const SizedBox(height: 20),
            _judul('Lokasi'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF80C9F5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: biru),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _alamat.isEmpty ? 'Memuat lokasi...' : _alamat,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _input(
              label: 'Detail alamat / patokan',
              hint: 'Contoh: Blok C No. 12, sebelah warung',
              icon: Icons.signpost_outlined,
              controller: _detailAlamat,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Detail alamat wajib diisi'
                  : null,
            ),
            const SizedBox(height: 10),
            _judul('Jadwal Servis'),
            _pilihanJadwal(),
            const SizedBox(height: 20),
            _judul('Catatan & Foto'),
            _input(
              label: 'Catatan tambahan (opsional)',
              hint: 'Contoh: AC di lantai 2, gunakan tangga sendiri',
              icon: Icons.notes_outlined,
              controller: _catatan,
              maxLines: 3,
              validator: (_) => null,
            ),
            _unggahFoto(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: _lanjut,
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
            child: const Text('Lanjut'),
          ),
        ),
      ),
    );
  }

  Widget _kartuLayanan() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _layanan.warnaLatar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_layanan.ikon, color: _layanan.warnaIkon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _layanan.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _layanan.deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Mulai ${rupiah(_layanan.harga)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.biruAksen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.schedule,
                      size: 12,
                      color: AppColors.teksSamar,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '± ${_layanan.durasiMenit} menit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.teksSamar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.biruAksen,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }

  Widget _judul(String teks) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      teks,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _teksError(String teks) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(teks, style: const TextStyle(fontSize: 10, color: Colors.red)),
  );

  Widget _stepperJumlahUnit() {
    return Row(
      children: [
        Text('Jumlah unit', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
        const Spacer(),
        _tombolBulat(
          ikon: Icons.remove,
          aktif: _jumlahUnit > 1,
          onTap: () => setState(() => _jumlahUnit--),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$_jumlahUnit',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _tombolBulat(
          ikon: Icons.add,
          aktif: _jumlahUnit < 5,
          onTap: () => setState(() => _jumlahUnit++),
        ),
      ],
    );
  }

  Widget _tombolBulat({
    required IconData ikon,
    required bool aktif,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: aktif ? onTap : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: aktif ? biru : const Color(0xFFCBD0D8)),
        ),
        child: Icon(
          ikon,
          size: 16,
          color: aktif ? biru : const Color(0xFFCBD0D8),
        ),
      ),
    );
  }

  Widget _pilihanJenisAc() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final j in JenisAc.values)
          _chipPilihan(
            label: j.label,
            dipilih: _jenisAc == j,
            onTap: () => setState(() {
              _jenisAc = j;
              _errorJenisAc = null;
            }),
          ),
      ],
    );
  }

  Widget _pilihanPk() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final pk in const [0.5, 1.0, 1.5, 2.0])
          _chipPilihan(
            label: '${_pkLabel(pk)} PK',
            dipilih: _pk == pk,
            onTap: () => setState(() {
              _pk = pk;
              _errorPk = null;
            }),
          ),
      ],
    );
  }

  Widget _pilihanFreon() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in _jenisFreon)
          _chipPilihan(
            label: f,
            dipilih: _freon == f,
            onTap: () => setState(() {
              _freon = f;
              _errorFreon = null;
            }),
          ),
      ],
    );
  }

  Widget _pilihanBongkarPasang() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in JenisBongkarPasang.values)
          _chipPilihan(
            label: b.label,
            dipilih: _bongkarPasang == b,
            onTap: () => setState(() => _bongkarPasang = b),
          ),
      ],
    );
  }

  Widget _chipPilihan({
    required String label,
    required bool dipilih,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: dipilih ? const Color(0xFFE3F1FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dipilih ? biru : const Color(0xFFCBD0D8),
            width: dipilih ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: dipilih ? biru : Colors.black87,
            fontWeight: dipilih ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _checklistKeluhan() {
    return Column(
      children: [
        for (final k in _keluhan)
          CheckboxListTile(
            value: _keluhanDipilih.contains(k),
            onChanged: (v) => setState(() {
              if (v == true) {
                _keluhanDipilih.add(k);
              } else {
                _keluhanDipilih.remove(k);
              }
            }),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity: VisualDensity.compact,
            title: Text(k, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
            activeColor: biru,
          ),
      ],
    );
  }

  Widget _pilihanJadwal() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _chipPilihan(
                label: 'Sekarang',
                dipilih: _sekarang,
                onTap: () => setState(() => _sekarang = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _chipPilihan(
                label: 'Jadwalkan',
                dipilih: !_sekarang,
                onTap: () => setState(() => _sekarang = false),
              ),
            ),
          ],
        ),
        if (!_sekarang) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pilihTanggal,
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                  label: Text(
                    _tanggalJadwal == null
                        ? 'Pilih tanggal'
                        : DateFormat(
                            'd MMM yyyy',
                            'id_ID',
                          ).format(_tanggalJadwal!),
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: _gayaTombolJadwal(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pilihJam,
                  icon: const Icon(Icons.schedule, size: 16),
                  label: Text(
                    _jamJadwal == null
                        ? 'Pilih jam'
                        : _jamJadwal!.format(context),
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: _gayaTombolJadwal(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ButtonStyle _gayaTombolJadwal() => OutlinedButton.styleFrom(
    foregroundColor: biru,
    side: const BorderSide(color: Color(0xFF80C9F5)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 10),
  );

  Widget _unggahFoto() {
    return InkWell(
      onTap: _tambahFoto,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              size: 28,
              color: Colors.black38,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fotoKondisi ?? 'Unggah foto kondisi AC',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Format JPG, PNG | Maks. 5MB',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
              prefixIcon: Icon(icon, color: biru, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF80C9F5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: biru, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label PK yang rapi: `0.5`, `1`, `1.5`, `2`.
String _pkLabel(double pk) =>
    pk == pk.roundToDouble() ? pk.toStringAsFixed(0) : pk.toString();
