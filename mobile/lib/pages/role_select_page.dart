import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'pelanggan/masuk_page.dart';
import '../theme/app_colors.dart';

/// Layar pemilihan peran sebelum masuk.
class RoleSelectPage extends StatefulWidget {
  const RoleSelectPage({super.key});

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> {
  UserRole _pilihan = UserRole.pelanggan;

  void _lanjutkan() {
    // TODO(backend): peran cukup dibawa ke halaman masuk; penyimpanan sesi
    // dilakukan AuthService.login setelah kredensial divalidasi.
    // pushReplacement: setelah memilih peran, kembali dari halaman masuk
    // berarti keluar aplikasi, bukan kembali ke pemilihan peran.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MasukPage(role: _pilihan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gelombang
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.biru, AppColors.biruGaris],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Selamat Datang di',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 20),
                    ),
                    Text(
                      'ACare',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk sebagai',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.teksSamar,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _RoleCard(
                      icon: Icons.person_outline,
                      title: UserRole.pelanggan.label,
                      subtitle: 'Pesan dan pantau servis AC kamu',
                      selected: _pilihan == UserRole.pelanggan,
                      onTap: () =>
                          setState(() => _pilihan = UserRole.pelanggan),
                    ),
                    const SizedBox(height: 14),
                    _RoleCard(
                      icon: Icons.build_outlined,
                      title: UserRole.teknisi.label,
                      subtitle: 'Terima dan kelola pesanan servis',
                      selected: _pilihan == UserRole.teknisi,
                      onTap: () => setState(() => _pilihan = UserRole.teknisi),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.biru,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _lanjutkan,
                        child: Text(
                          'Lanjutkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.biruMuda : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.biru : AppColors.garis,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.biruGaris,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.biru, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.teksSamar,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: selected
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('on'),
                        color: AppColors.biru,
                        size: 26,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('off'),
                        color: AppColors.teksSamar,
                        size: 26,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.55,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height - 80,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
