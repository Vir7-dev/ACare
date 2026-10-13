import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/ilustrasi_teknisi.dart';
import '../services/sesi_pengguna.dart';
import 'main_shell.dart';
import 'masuk_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _gambar = [
    'assets/images/splash_1.png',
    'assets/images/splash_2.png',
  ];

  int _tahap = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _tahap = 1);
      _timer = Timer(const Duration(milliseconds: 1800), _keMasuk);
    });
  }

  Future<void> _keMasuk() async {
    final sudahMasuk = await SesiPengguna.sudahMasuk();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) =>
            sudahMasuk ? const MainShell() : const MasukPage(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Column(
              key: ValueKey(_tahap),
              mainAxisSize: MainAxisSize.min,
              children: [
                IlustrasiTeknisi(asset: _gambar[_tahap]),
                const SizedBox(height: 24),
                Text(
                  'Layanan AC',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
