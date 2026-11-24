import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  /// Saat true tombol dikunci dan menampilkan indikator proses, supaya
  /// pengguna tahu permintaan sedang berjalan dan tidak menekan dua kali.
  final bool memproses;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.memproses = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: memproses ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.biru,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.biru.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (memproses) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
