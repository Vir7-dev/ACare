import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sesi_pengguna.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/wave_background.dart';
import 'daftar_page.dart';
import 'main_shell.dart';

class MasukPage extends StatefulWidget {
  const MasukPage({super.key});

  @override
  State<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends State<MasukPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _sandi = TextEditingController();

  @override
  void dispose() {
    _nama.dispose();
    _sandi.dispose();
    super.dispose();
  }

  String? _wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    // TODO: panggil API login Laravel; sementara hanya mengingat sesi lokal
    await SesiPengguna.masuk(_nama.text);
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
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
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                            'Selamat Datang!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Login untuk melanjutkan akun anda',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                          const SizedBox(height: 28),
                          AuthTextField(
                            hint: 'Nama',
                            icon: Icons.person_outline,
                            controller: _nama,
                            textInputAction: TextInputAction.next,
                            validator: (v) => _wajib(v, 'Nama'),
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            hint: 'Kata Sandi',
                            icon: Icons.lock_outline,
                            controller: _sandi,
                            password: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => _wajib(v, 'Kata sandi'),
                          ),
                          const SizedBox(height: 32),
                          AuthButton(label: 'Masuk', onPressed: _masuk),
                          const SizedBox(height: 24),
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Belum Punya akun? ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.teksSamar,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const DaftarPage(),
                                    ),
                                  ),
                                  child: Text(
                                    'Daftar Sekarang',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.tautan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
