import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/perangkat.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';
import '../role_select_page.dart';

/// Tab profil teknisi. Tampilannya mengikuti halaman profil pelanggan.
class KelolaProfilTeknisiPage extends StatefulWidget {
  const KelolaProfilTeknisiPage({super.key});

  @override
  State<KelolaProfilTeknisiPage> createState() =>
      _KelolaProfilTeknisiPageState();
}

class _KelolaProfilTeknisiPageState extends State<KelolaProfilTeknisiPage> {
  final _formKey = GlobalKey<FormState>();

  // Data dummy, nanti diambil dari API Laravel
  final _nama = TextEditingController(text: 'Dina Safitri');
  final _telepon = TextEditingController(text: '083862865166');
  final _email = TextEditingController(text: 'sdina3066@gmail.com');
  final _jenis = TextEditingController(text: 'Mekanik AC');
  final _plat = TextEditingController(text: 'BP 676767');

  bool _modeEdit = false;
  Uint8List? _foto;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _email.dispose();
    _jenis.dispose();
    _plat.dispose();
    super.dispose();
  }

  String get _inisial {
    final huruf = _nama.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .take(2)
        .map((k) => k[0].toUpperCase())
        .join();
    return huruf.isEmpty ? '?' : huruf;
  }

  Future<void> _gantiFoto() async {
    try {
      final f = await Perangkat.ambilFoto();
      if (f == null) return;
      final data = await f.readAsBytes();
      // TODO: unggah foto ke API supaya tersimpan permanen
      if (mounted) setState(() => _foto = data);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal memilih foto')));
    }
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: kirim perubahan profil ke API Laravel
    FocusScope.of(context).unfocus();
    setState(() => _modeEdit = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  void _segera() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fitur ini segera hadir')));
  }

  Future<void> _keluar() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu harus masuk lagi untuk memakai ACare.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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

  String? _wajib(String? v, String pesan) =>
      (v == null || v.trim().isEmpty) ? pesan : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kelola Profil',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: _segera),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFDDE8FA),
                    backgroundImage: _foto == null ? null : MemoryImage(_foto!),
                    child: _foto != null
                        ? null
                        : Text(
                            _inisial,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: InkWell(
                      onTap: _gantiFoto,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.biruMuda,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          size: 14,
                          color: AppColors.biruAksen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                _nama.text.trim().isEmpty ? 'Teknisi' : _nama.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                'Motor BEAT  •  ${_plat.text}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.teksSamar,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _Label('Informasi Akun'),
            const SizedBox(height: 8),
            _Isian(
              ikon: Icons.person_outline,
              hint: 'Nama',
              controller: _nama,
              bisaDiubah: _modeEdit,
              onChanged: (_) => setState(() {}),
              validator: (v) => _wajib(v, 'Nama wajib diisi'),
            ),
            const SizedBox(height: 10),
            _Isian(
              ikon: Icons.phone_outlined,
              hint: 'Nomor telepon',
              controller: _telepon,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.phone,
              validator: (v) => _wajib(v, 'Nomor telepon wajib diisi'),
            ),
            const SizedBox(height: 10),
            _Isian(
              ikon: Icons.mail_outline,
              hint: 'Email',
              controller: _email,
              bisaDiubah: _modeEdit,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
                  ? 'Email tidak valid'
                  : null,
            ),
            const SizedBox(height: 20),
            const _Label('Informasi Teknisi'),
            const SizedBox(height: 8),
            _Isian(
              ikon: Icons.home_repair_service_outlined,
              hint: 'Jenis teknisi',
              controller: _jenis,
              bisaDiubah: _modeEdit,
              validator: (v) => _wajib(v, 'Jenis teknisi wajib diisi'),
            ),
            const SizedBox(height: 10),
            _Isian(
              ikon: Icons.two_wheeler,
              hint: 'Nomor kendaraan',
              controller: _plat,
              bisaDiubah: _modeEdit,
              onChanged: (_) => setState(() {}),
              validator: (v) => _wajib(v, 'Nomor kendaraan wajib diisi'),
            ),
            const SizedBox(height: 16),
            if (_modeEdit)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _modeEdit = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.biru,
                          side: const BorderSide(color: AppColors.biru),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _TombolBiru('Simpan Perubahan', _simpan),
                  ),
                ],
              )
            else
              _TombolBiru(
                'Edit Profil',
                () => setState(() => _modeEdit = true),
              ),
            const SizedBox(height: 20),
            const _Label('Pengaturan Akun'),
            const SizedBox(height: 8),
            _MenuPengaturan(
              ikon: Icons.lock_outline,
              label: 'Ubah Kata Sandi',
              onTap: _segera,
            ),
            _MenuPengaturan(
              ikon: Icons.notifications_none,
              label: 'Notifikasi',
              onTap: _segera,
            ),
            _MenuPengaturan(
              ikon: Icons.help_outline,
              label: 'Pusat Bantuan',
              onTap: _segera,
            ),
            _MenuPengaturan(
              ikon: Icons.logout,
              label: 'Keluar',
              onTap: _keluar,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        color: AppColors.teksSamar,
      ),
    );
  }
}

class _TombolBiru extends StatelessWidget {
  const _TombolBiru(this.teks, this.onPressed);

  final String teks;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
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
        child: Text(teks),
      ),
    );
  }
}

class _Isian extends StatelessWidget {
  final IconData ikon;
  final String hint;
  final TextEditingController controller;
  final bool bisaDiubah;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _Isian({
    required this.ikon,
    required this.hint,
    required this.controller,
    required this.bisaDiubah,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: !bisaDiubah,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.teksSamar),
        prefixIcon: Icon(ikon, size: 20, color: Colors.black87),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD5D9DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.biru),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.merah),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.merah),
        ),
      ),
    );
  }
}

class _MenuPengaturan extends StatelessWidget {
  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  const _MenuPengaturan({
    required this.ikon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFBFC4CC), width: 2),
        ),
      ),
      child: Material(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          onTap: onTap,
          leading: Icon(ikon, size: 20, color: Colors.black87),
          title: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.biruAksen,
          ),
        ),
      ),
    );
  }
}
