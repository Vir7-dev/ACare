import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/wave_background.dart';
import '../teknisi/teknisi_shell.dart';
import '../umum/main_shell.dart';
import 'daftar_page.dart';

class MasukPage extends StatefulWidget {
  /// Peran yang dipilih di [RoleSelectPage]; menentukan halaman setelah masuk.
  final UserRole role;

  const MasukPage({super.key, this.role = UserRole.pelanggan});

  @override
  State<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends State<MasukPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _memproses = false;

  @override
  void initState() {
    super.initState();
    _isiEmailDariAkun();
  }

  Future<void> _isiEmailDariAkun() async {
    final e = await SesiPengguna.email();
    if (mounted && e != null && _email.text.isEmpty) _email.text = e;
  }

  Future<void> _bukaDaftar() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DaftarPage()));
    // Setelah mendaftar, email langsung terisi di form masuk.
    await _isiEmailDariAkun();
  }

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  String? _wajib(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _memproses = true);
    final berhasil = await AuthService.login(
      _email.text,
      _sandi.text,
      widget.role,
    );
    if (!mounted) return;
    setState(() => _memproses = false);
    if (!berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi wajib diisi')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.role == UserRole.teknisi
            ? const TeknisiShell()
            : const MainShell(),
      ),
    );
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
                            hint: 'Email',
                            icon: Icons.mail_outline,
                            controller: _email,
                            textInputAction: TextInputAction.next,
                            validator: (v) => _wajib(v, 'Email'),
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
                          AuthButton(
                            label: _memproses ? 'Memproses...' : 'Masuk',
                            onPressed: _masuk,
                          ),
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
                                  onTap: _bukaDaftar,
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
