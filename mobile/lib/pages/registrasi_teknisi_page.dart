
import 'package:flutter/material.dart';

class RegistrasiTeknisiPage extends StatefulWidget {
  const RegistrasiTeknisiPage({super.key});

  @override
  State<RegistrasiTeknisiPage> createState() =>
      _RegistrasiTeknisiPageState();
}

class _RegistrasiTeknisiPageState
    extends State<RegistrasiTeknisiPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _sembunyikanPassword = true;

  static const Color biru = Color(0xFF087CC1);

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _input({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool password = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: password && _sembunyikanPassword,
            validator: validator,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Colors.black38,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: biru,
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: Color(0xFF82C8F5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: biru,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selanjutnya() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informasi pribadi berhasil diisi. '
            'Halaman berikutnya dapat dihubungkan di sini.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LatarBiruPainter(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 22,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          const Text(
                            'Registrasi Teknisi 1',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 25),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              18, 24, 18, 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  const Text(
                                    'ACare',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const Text(
                                    'Aplikasi Layanan AC yang Cepat dan Terpercaya',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  const SizedBox(height: 24),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      14, 18, 14, 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Informasi Pribadi',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        _input(
                                          label: 'Nama Lengkap',
                                          hint: 'Masukkan nama lengkap',
                                          icon: Icons.person_outline,
                                          controller: _namaController,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Nama wajib diisi';
                                            }
                                            return null;
                                          },
                                        ),

                                        _input(
                                          label: 'Nomor telepon',
                                          hint: 'Masukkan nomor telepon',
                                          icon: Icons.phone_outlined,
                                          controller: _teleponController,
                                          keyboardType: TextInputType.phone,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Nomor telepon wajib diisi';
                                            }
                                            if (!RegExp(r'^[0-9+ ]{8,16}$')
                                                .hasMatch(value.trim())) {
                                              return 'Nomor telepon tidak valid';
                                            }
                                            return null;
                                          },
                                        ),

                                        _input(
                                          label: 'Gmail',
                                          hint: 'Masukkan Gmail',
                                          icon: Icons.mail_outline,
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                !RegExp(
                                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                                ).hasMatch(value.trim())) {
                                              return 'Masukkan email yang valid';
                                            }
                                            return null;
                                          },
                                        ),

                                        _input(
                                          label: 'Verifikasi kata sandi',
                                          hint: 'Masukkan kata sandi',
                                          icon: Icons.lock_outline,
                                          controller: _passwordController,
                                          password: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.length < 8) {
                                              return 'Kata sandi minimal 8 karakter';
                                            }
                                            return null;
                                          },
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _sembunyikanPassword =
                                                    !_sembunyikanPassword;
                                              });
                                            },
                                            icon: Icon(
                                              _sembunyikanPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              size: 17,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: _selanjutnya,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: biru,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 11,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            child: const Text(
                                              'Selanjutnya',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 18),
                                  const Text(
                                    'Dengan Mendaftar Anda Menyetujui',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  const Text(
                                    'Syarat dan Ketentuan ACare',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: biru,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LatarBiruPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF087BEA);
    final atas = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(0, size.height * 0.12)
      ..close();
    canvas.drawPath(atas, paint);

    paint.color = const Color(0xFFB9E0FF);
    final atasMuda = Path()
      ..moveTo(0, size.height * 0.07)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.03,
        size.width * 0.62,
        0,
      )
      ..lineTo(size.width * 0.82, 0)
      ..lineTo(0, size.height * 0.17)
      ..close();
    canvas.drawPath(atasMuda, paint);

    paint.color = const Color(0xFF087BEA);
    final bawah = Path()
      ..moveTo(0, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 1.02,
        size.width,
        size.height * 0.88,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bawah, paint);

    paint.color = const Color(0xFFB9E0FF);
    final bawahMuda = Path()
      ..moveTo(0, size.height * 0.91)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.99,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 1.04,
        0,
        size.height * 0.98,
      )
      ..close();
    canvas.drawPath(bawahMuda, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
