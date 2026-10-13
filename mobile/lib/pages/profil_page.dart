import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/perangkat.dart';
import '../services/sesi_pengguna.dart';
import '../theme/app_colors.dart';
import 'masuk_page.dart';
import 'pengaduan_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Data dummy, nanti diambil dari API Laravel
  final _nama = TextEditingController(text: 'Dina Safitri');
  final _telepon = TextEditingController(text: '083862865166');
  final _email = TextEditingController(text: 'sdina3066@gmail.com');
  final _lokasi = TextEditingController(text: 'Batam Kepulauan Riau');

  Uint8List? _foto;

  @override
  void initState() {
    super.initState();
    SesiPengguna.nama().then((n) {
      if (mounted && n != null) setState(() => _nama.text = n);
    });
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

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _email.dispose();
    _lokasi.dispose();
    super.dispose();
  }

  String get _inisial {
    final kata = _nama.text.trim().split(RegExp(r'\s+'));
    final huruf = kata
        .where((k) => k.isNotEmpty)
        .take(2)
        .map((k) => k[0].toUpperCase())
        .join();
    return huruf.isEmpty ? '?' : huruf;
  }

  Future<void> _simpan() async {
    // TODO: kirim perubahan profil ke API Laravel
    await SesiPengguna.masuk(_nama.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {});
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
    if (ya == true && mounted) {
      // TODO: hapus token login di API
      await SesiPengguna.keluar();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MasukPage()),
        (_) => false,
      );
    }
  }

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
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PengaduanPage())),
          ),
        ],
      ),
      body: ListView(
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
              _nama.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Informasi Akun',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.teksSamar,
            ),
          ),
          const SizedBox(height: 8),
          _Isian(
            ikon: Icons.person_outline,
            controller: _nama,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          _Isian(
            ikon: Icons.phone_outlined,
            controller: _telepon,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _Isian(
            ikon: Icons.mail_outline,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _Isian(ikon: Icons.location_on_outlined, controller: _lokasi),
          const SizedBox(height: 16),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _simpan,
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
              child: const Text('Simpan Perubahan'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pengaturan Akun',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.teksSamar,
            ),
          ),
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
            ikon: Icons.translate,
            label: 'Bahasa',
            onTap: _segera,
          ),
          _MenuPengaturan(
            ikon: Icons.help_outline,
            label: 'Pusat Bantuan',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PengaduanPage())),
          ),
          _MenuPengaturan(ikon: Icons.logout, label: 'Keluar', onTap: _keluar),
        ],
      ),
    );
  }
}

class _Isian extends StatelessWidget {
  final IconData ikon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _Isian({
    required this.ikon,
    required this.controller,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
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
