import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // TODO(backend): isi dari data profil teknisi di API. Sementara data contoh.
  static const _awal = (
    nama: 'Rizky Pratama',
    telepon: '081200000003',
    email: 'teknisi@acare.id',
    kendaraan: 'Honda Beat',
    plat: 'BP 1234 AC',
    tentang: 'Berpengalaman 5 tahun menangani AC rumah dan kantor.',
  );
  final _nama = TextEditingController(text: _awal.nama);
  final _telepon = TextEditingController(text: _awal.telepon);
  final _email = TextEditingController(text: _awal.email);
  final _kendaraan = TextEditingController(text: _awal.kendaraan);
  final _plat = TextEditingController(text: _awal.plat);
  final _tentang = TextEditingController(text: _awal.tentang);

  Uint8List? _foto;
  bool _modeEdit = false;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _email.dispose();
    _kendaraan.dispose();
    _plat.dispose();
    _tentang.dispose();
    super.dispose();
  }

  void _buka(Widget halaman) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));

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

  void _batal() {
    // TODO(backend): muat ulang dari API; sementara kembali ke data contoh.
    _nama.text = _awal.nama;
    _telepon.text = _awal.telepon;
    _email.text = _awal.email;
    _kendaraan.text = _awal.kendaraan;
    _plat.text = _awal.plat;
    _tentang.text = _awal.tentang;
    setState(() => _modeEdit = false);
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(backend): kirim perubahan profil ke API.
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
              validator: (v) => wajib(v, 'Nama'),
            ),
            IsianProfil(
              label: 'Nomor Telepon',
              ikon: Icons.phone_outlined,
              controller: _telepon,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.phone,
              validator: (v) => wajib(v, 'Nomor telepon'),
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
            const SizedBox(height: 8),
            const JudulBagianProfil('Informasi Teknisi'),
            IsianProfil(
              label: 'Jenis Kendaraan',
              ikon: Icons.two_wheeler,
              controller: _kendaraan,
              bisaDiubah: _modeEdit,
              validator: (v) => wajib(v, 'Jenis kendaraan'),
            ),
            IsianProfil(
              label: 'Plat Nomor',
              ikon: Icons.pin_outlined,
              controller: _plat,
              bisaDiubah: _modeEdit,
              validator: (v) => wajib(v, 'Plat nomor'),
            ),
            IsianProfil(
              label: 'Tentang Saya',
              ikon: Icons.notes_outlined,
              controller: _tentang,
              bisaDiubah: _modeEdit,
              baris: 3,
              validator: (v) => (v ?? '').trim().length > 300
                  ? 'Maksimal 300 karakter'
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
