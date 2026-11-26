import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/perangkat.dart';
import '../../services/sesi_pengguna.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profil_bersama.dart';
import '../pelanggan/pengaduan_page.dart';
import '../role_select_page.dart';
import '../umum/notifikasi_page.dart';
import '../umum/ubah_kata_sandi_page.dart';

/// Profil teknisi. Tampilan & cara edit sama dengan profil pelanggan
/// (komponen di widgets/profil_bersama.dart).
class KelolaProfilTeknisiPage extends StatefulWidget {
  const KelolaProfilTeknisiPage({super.key});

  @override
  State<KelolaProfilTeknisiPage> createState() =>
      _KelolaProfilTeknisiPageState();
}

class _KelolaProfilTeknisiPageState extends State<KelolaProfilTeknisiPage> {
  final _formKey = GlobalKey<FormState>();

  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _email = TextEditingController();
  final _kendaraan = TextEditingController();
  final _plat = TextEditingController();
  final _tentang = TextEditingController();
  final _bank = TextEditingController();
  final _rekening = TextEditingController();
  final _atasNama = TextEditingController();

  Uint8List? _foto;
  bool _modeEdit = false;
  bool _menyimpan = false;

  /// Galat per kolom dari server (misal email sudah dipakai akun lain).
  Map<String, String> _galatServer = {};

  @override
  void initState() {
    super.initState();
    _isiDariAkun();
  }

  /// Isi form dari akun yang sedang masuk.
  void _isiDariAkun() {
    final a = AuthService.akun.value;
    _nama.text = a?.nama ?? '';
    _telepon.text = a?.noTelepon ?? '';
    _email.text = a?.email ?? '';
    _kendaraan.text = a?.teknisi?.jenisKendaraan ?? '';
    _plat.text = a?.teknisi?.platNomor ?? '';
    _tentang.text = a?.teknisi?.deskripsi ?? '';
    _bank.text = a?.teknisi?.namaBank ?? '';
    _rekening.text = a?.teknisi?.noRekening ?? '';
    _atasNama.text = a?.teknisi?.atasNama ?? '';
  }

  String? _server(String kolom) => _galatServer[kolom];

  void _pesan(String teks) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _email.dispose();
    _kendaraan.dispose();
    _plat.dispose();
    _tentang.dispose();
    _bank.dispose();
    _rekening.dispose();
    _atasNama.dispose();
    super.dispose();
  }

  void _buka(Widget halaman) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));

  Future<void> _gantiFoto() async {
    final XFile? f;
    try {
      f = await Perangkat.ambilFoto();
    } catch (_) {
      if (mounted) _pesan('Gagal memilih foto');
      return;
    }
    if (f == null) return;
    final sebelumnya = _foto;
    final data = await f.readAsBytes();
    if (mounted) setState(() => _foto = data);
    try {
      await AuthService.ubahFoto(f);
      if (mounted) _pesan('Foto profil diperbarui');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _foto = sebelumnya);
      _pesan(e.pesan);
    }
  }

  void _batal() {
    _galatServer = {};
    _isiDariAkun();
    setState(() => _modeEdit = false);
  }

  Future<void> _simpan() async {
    if (_menyimpan) return;
    _galatServer = {};
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      await AuthService.ubahProfil(
        nama: _nama.text,
        telepon: _telepon.text,
        email: _email.text,
        jenisKendaraan: _kendaraan.text,
        platNomor: _plat.text.toUpperCase(),
        deskripsi: _tentang.text,
        namaBank: _bank.text,
        noRekening: _rekening.text,
        atasNama: _atasNama.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galatServer = e.galatKolom;
      });
      if (e.galatKolom.isEmpty) {
        _pesan(e.pesan);
      } else {
        _formKey.currentState!.validate();
      }
      return;
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isiDariAkun();
      _menyimpan = false;
      _modeEdit = false;
    });
    _pesan('Perubahan disimpan');
  }

  Future<void> _keluar() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu harus masuk lagi untuk memakai ACare.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.merah),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;

    await AuthService.logout();
    TeknisiService.instance.reset();
    await SesiPengguna.keluar();
    if (!mounted) return;
    // Kembali ke pemilihan peran, sama seperti saat pertama membuka aplikasi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String? wajib(String? v, String label) =>
        (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: AppColors.latar,
        surfaceTintColor: AppColors.latar,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Kelola Profil',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // Navigasi bawah disediakan oleh TeknisiShell.
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            KepalaProfil(
              nama: _nama.text,
              keterangan: 'Teknisi ACare',
              foto: _foto,
              fotoUrl: AuthService.akun.value?.fotoProfil,
              onGantiFoto: _gantiFoto,
            ),
            const SizedBox(height: 24),
            const JudulBagianProfil('Informasi Akun'),
            IsianProfil(
              label: 'Nama Lengkap',
              ikon: Icons.person_outline,
              controller: _nama,
              bisaDiubah: _modeEdit,
              onChanged: (_) => setState(() {}),
              validator: (v) => wajib(v, 'Nama') ?? _server('nama'),
            ),
            IsianProfil(
              label: 'Nomor Telepon',
              ikon: Icons.phone_outlined,
              controller: _telepon,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  wajib(v, 'Nomor telepon') ?? _server('no_telepon'),
            ),
            IsianProfil(
              label: 'Email',
              ikon: Icons.mail_outline,
              controller: _email,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
                  ? 'Email tidak valid'
                  : _server('email'),
            ),
            const SizedBox(height: 8),
            const JudulBagianProfil('Informasi Teknisi'),
            IsianProfil(
              label: 'Jenis Kendaraan',
              ikon: Icons.two_wheeler,
              controller: _kendaraan,
              bisaDiubah: _modeEdit,
              validator: (v) =>
                  wajib(v, 'Jenis kendaraan') ?? _server('jenis_kendaraan'),
            ),
            IsianProfil(
              label: 'Plat Nomor',
              ikon: Icons.pin_outlined,
              controller: _plat,
              bisaDiubah: _modeEdit,
              validator: (v) => wajib(v, 'Plat nomor') ?? _server('plat_nomor'),
            ),
            IsianProfil(
              label: 'Tentang Saya',
              ikon: Icons.notes_outlined,
              controller: _tentang,
              bisaDiubah: _modeEdit,
              baris: 3,
              validator: (v) => (v ?? '').trim().length > 300
                  ? 'Maksimal 300 karakter'
                  : _server('deskripsi'),
            ),
            const SizedBox(height: 8),
            const JudulBagianProfil('Rekening Pencairan'),
            IsianProfil(
              label: 'Bank',
              ikon: Icons.account_balance_outlined,
              controller: _bank,
              bisaDiubah: _modeEdit,
              validator: (v) => wajib(v, 'Bank') ?? _server('nama_bank'),
            ),
            IsianProfil(
              label: 'Nomor Rekening',
              ikon: Icons.numbers,
              controller: _rekening,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.number,
              validator: (v) {
                final angka = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (angka.isEmpty) return 'Nomor rekening wajib diisi';
                if (angka.length < 5) return 'Nomor rekening tidak valid';
                return _server('no_rekening');
              },
            ),
            IsianProfil(
              label: 'Atas Nama',
              ikon: Icons.badge_outlined,
              controller: _atasNama,
              bisaDiubah: _modeEdit,
              validator: (v) =>
                  wajib(v, 'Nama pemilik rekening') ?? _server('atas_nama'),
            ),
            const SizedBox(height: 4),
            TombolEditProfil(
              modeEdit: _modeEdit,
              onEdit: () => setState(() => _modeEdit = true),
              onBatal: _batal,
              onSimpan: _simpan,
            ),
            const SizedBox(height: 24),
            const JudulBagianProfil('Pengaturan Akun'),
            KartuMenuProfil(
              menu: [
                ItemMenuProfil(
                  ikon: Icons.lock_outline,
                  label: 'Ubah Kata Sandi',
                  onTap: () => _buka(const UbahKataSandiPage()),
                ),
                ItemMenuProfil(
                  ikon: Icons.notifications_none,
                  label: 'Notifikasi',
                  onTap: () => _buka(const NotifikasiPage()),
                ),
                ItemMenuProfil(
                  ikon: Icons.support_agent,
                  label: 'Pusat Bantuan',
                  onTap: () => _buka(const PengaduanPage()),
                ),
                ItemMenuProfil(
                  ikon: Icons.logout,
                  label: 'Keluar',
                  bahaya: true,
                  onTap: _keluar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
