import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/perangkat.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profil_bersama.dart';
import '../role_select_page.dart';
import '../umum/notifikasi_page.dart';
import '../umum/ubah_kata_sandi_page.dart';
import 'kelola_alamat_page.dart';
import 'pengaduan_page.dart';

/// Profil pelanggan. Tampilan & cara edit sama dengan profil teknisi
/// (komponen di widgets/profil_bersama.dart). Alamat dikelola lewat menu
/// Alamat Tersimpan, bukan kolom di sini.
class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _email = TextEditingController();

  Uint8List? _foto;
  bool _modeEdit = false;
  bool _menyimpan = false;

  /// Galat per kolom dari server (misal email sudah dipakai akun lain).
  Map<String, String> _galatServer = {};

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  /// Data dari akun yang sedang masuk; data di perangkat sebagai cadangan.
  Future<void> _muatData() async {
    final akun = AuthService.akun.value;
    final nama = akun?.nama ?? await SesiPengguna.nama();
    final telepon = akun?.noTelepon ?? await SesiPengguna.telepon();
    final email = akun?.email ?? await SesiPengguna.email();
    if (!mounted) return;
    setState(() {
      _nama.text = nama ?? '';
      _telepon.text = telepon ?? '';
      _email.text = email ?? '';
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _email.dispose();
    super.dispose();
  }

  void _pesan(String teks) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(teks)));

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

  Future<void> _batal() async {
    _galatServer = {};
    await _muatData();
    if (mounted) setState(() => _modeEdit = false);
  }

  String? _server(String kolom) => _galatServer[kolom];

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
    await _muatData();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.merah),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    await AuthService.logout();
    await SesiPengguna.keluar();
    if (!mounted) return;
    // Kembali ke pemilihan peran, sama seperti saat pertama membuka aplikasi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectPage()),
      (_) => false,
    );
  }

  void _buka(Widget halaman) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));

  @override
  Widget build(BuildContext context) {
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            KepalaProfil(
              nama: _nama.text,
              keterangan: 'Pelanggan ACare',
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
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama wajib diisi'
                  : _server('nama'),
            ),
            IsianProfil(
              label: 'Nomor Telepon',
              ikon: Icons.phone_outlined,
              controller: _telepon,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nomor telepon wajib diisi'
                  : _server('no_telepon'),
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
                  ikon: Icons.location_on_outlined,
                  label: 'Alamat Tersimpan',
                  onTap: () => _buka(const KelolaAlamatPage()),
                ),
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
