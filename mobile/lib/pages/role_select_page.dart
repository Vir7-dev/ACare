import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'pelanggan/masuk_page.dart';

/// Layar pemilihan peran sebelum masuk.
class RoleSelectPage extends StatefulWidget {
  const RoleSelectPage({super.key});

  @override
  State<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends State<RoleSelectPage> {
  UserRole _pilihan = UserRole.pelanggan;

  static const _primary = Color(0xFF0384C6);

  void _lanjutkan() {
    // TODO(backend): peran cukup dibawa ke halaman masuk; penyimpanan sesi
    // dilakukan AuthService.login setelah kredensial divalidasi.
    // pushReplacement: setelah memilih peran, kembali dari halaman masuk
    // berarti keluar aplikasi, bukan kembali ke pemilihan peran.
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => MasukPage(role: _pilihan)));
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
                  colors: [Color(0xFF1E88E5), Color(0xFFBBDEFB)],
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
                        color: Colors.grey.shade700,
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
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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

  static const _primary = Color(0xFF0384C6);

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
            color: selected ? const Color(0xFFE8F4FB) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _primary : Colors.grey.shade400,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFC5E1F3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF2F6FD0), size: 28),
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
                        color: Colors.grey.shade700,
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
                        color: _primary,
                        size: 26,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('off'),
                        color: Colors.grey.shade500,
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
