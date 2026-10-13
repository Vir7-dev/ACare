import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ACare',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          'Aplikasi Layanan AC yang Cepat dan Terpercaya',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
