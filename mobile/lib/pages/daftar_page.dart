import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/wave_background.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _sandi = TextEditingController();
  final _verifikasi = TextEditingController();

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _sandi.dispose();
    _verifikasi.dispose();
    super.dispose();
  }

  String? _wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  void _daftar() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: panggil API register Laravel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pendaftaran berhasil, silakan masuk')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WaveBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFCFA),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Akun',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bergabung Dengan ACare dan nikmati\nKemudahan Merawat AC',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          AuthTextField(
                            hint: 'Nama',
                            icon: Icons.person_outline,
                            controller: _nama,
                            textInputAction: TextInputAction.next,
                            validator: (v) => _wajib(v, 'Nama'),
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            hint: 'Nomor Telepon',
                            icon: Icons.phone_outlined,
                            controller: _telepon,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final salah = _wajib(v, 'Nomor telepon');
                              if (salah != null) return salah;
                              final digit = v!.replaceAll(RegExp(r'\D'), '');
                              return digit.length < 9
                                  ? 'Nomor telepon tidak valid'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            hint: 'Kata Sandi',
                            icon: Icons.lock_outline,
                            controller: _sandi,
                            password: true,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final salah = _wajib(v, 'Kata sandi');
                              if (salah != null) return salah;
                              return v!.length < 8
                                  ? 'Kata sandi minimal 8 karakter'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            hint: 'Verifikasi Kata Sandi',
                            icon: Icons.lock_outline,
                            controller: _verifikasi,
                            password: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => v != _sandi.text
                                ? 'Kata sandi tidak sama'
                                : null,
                          ),
                          const SizedBox(height: 24),
                          AuthButton(label: 'Daftar', onPressed: _daftar),
                          const SizedBox(height: 16),
                          Center(
                            child: Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.teksSamar,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Dengan Mendaftar Anda Menyetujui\n',
                                  ),
                                  TextSpan(
                                    text: 'Syarat dan Ketentuan',
                                    style: TextStyle(color: AppColors.tautan),
                                  ),
                                  TextSpan(text: ' ACare'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Sudah punya akun? Masuk'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
