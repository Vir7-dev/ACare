import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

/// Ubah kata sandi akun pelanggan atau teknisi (bagian dari UC-04).
class UbahKataSandiPage extends StatefulWidget {
  const UbahKataSandiPage({super.key});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  final _formKey = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();
  bool _memproses = false;
  bool _sembunyi = true;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _memproses = true);
    final galat = await AuthService.ubahKataSandi(
      lama: _lama.text,
      baru: _baru.text,
    );
    if (!mounted) return;
    setState(() => _memproses = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(galat ?? 'Kata sandi berhasil diubah')),
      );
    if (galat == null) Navigator.of(context).pop();
  }

  InputDecoration _gaya(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    suffixIcon: IconButton(
      tooltip: _sembunyi ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
      icon: Icon(_sembunyi ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _sembunyi = !_sembunyi),
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
          'Ubah Kata Sandi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _lama,
              obscureText: _sembunyi,
              decoration: _gaya('Kata sandi lama'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Kolom ini wajib diisi.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _baru,
              obscureText: _sembunyi,
              decoration: _gaya('Kata sandi baru'),
              validator: validasiKataSandi,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ulang,
              obscureText: _sembunyi,
              decoration: _gaya('Ulangi kata sandi baru'),
              validator: (v) =>
                  v != _baru.text ? 'Kata sandi tidak sama' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Minimal 8 karakter dan mengandung huruf serta angka.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.teksSamar,
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
            onPressed: _memproses ? null : _simpan,
            style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
            child: Text(_memproses ? 'Menyimpan...' : 'Simpan Kata Sandi'),
          ),
        ),
      ),
    );
  }
}

/// Aturan kata sandi sesuai UC-01: minimal 8 karakter, ada huruf dan angka.
String? validasiKataSandi(String? v) {
  final teks = v ?? '';
  if (teks.length < 8 ||
      !RegExp(r'[A-Za-z]').hasMatch(teks) ||
      !RegExp(r'[0-9]').hasMatch(teks)) {
    return 'Password minimal 8 karakter dan mengandung huruf serta angka';
  }
  return null;
}
