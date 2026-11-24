import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  // TODO(backend): ambil profil dari API; sementara dari data pendaftaran.
  Future<void> _muatData() async {
    final nama = await SesiPengguna.nama();
    final telepon = await SesiPengguna.telepon();
    final email = await SesiPengguna.email();
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

  Future<void> _gantiFoto() async {
    try {
      final f = await Perangkat.ambilFoto();
      if (f == null) return;
      final data = await f.readAsBytes();
      // TODO(backend): unggah foto ke API supaya tersimpan permanen.
      if (mounted) setState(() => _foto = data);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal memilih foto')));
    }
  }

  Future<void> _batal() async {
    await _muatData();
    if (mounted) setState(() => _modeEdit = false);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    // TODO(backend): kirim perubahan profil ke API.
    await SesiPengguna.simpanAkun(
      nama: _nama.text.trim(),
      telepon: _telepon.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _modeEdit = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            IsianProfil(
              label: 'Nomor Telepon',
              ikon: Icons.phone_outlined,
              controller: _telepon,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nomor telepon wajib diisi'
                  : null,
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
                  : null,
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
