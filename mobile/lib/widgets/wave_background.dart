import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar gelombang biru di atas dan bawah halaman Masuk / Daftar.
class WaveBackground extends StatelessWidget {
  final Widget child;

  const WaveBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _WavePainter())),
        child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Atas: gelombang muda (lebar) lalu gelombang tua di pojok kiri
    final atasMuda = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.04)
      ..cubicTo(w * 0.7, h * 0.12, w * 0.35, h * 0.02, 0, h * 0.12)
      ..close();
    canvas.drawPath(atasMuda, Paint()..color = AppColors.biruMuda);

    final atasTua = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.55, 0)
      ..cubicTo(w * 0.35, h * 0.03, w * 0.2, h * 0.02, 0, h * 0.075)
      ..close();
    canvas.drawPath(atasTua, Paint()..color = AppColors.biruTua);

    // Bawah: kebalikan dari atas
    final bawahMuda = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w, h * 0.88)
      ..cubicTo(w * 0.7, h * 0.96, w * 0.35, h * 0.9, 0, h * 0.97)
      ..close();
    canvas.drawPath(bawahMuda, Paint()..color = AppColors.biruMuda);

    final bawahTua = Path()
      ..moveTo(w, h)
      ..lineTo(w * 0.35, h)
      ..cubicTo(w * 0.6, h * 0.97, w * 0.8, h * 0.9, w, h * 0.9)
      ..close();
    canvas.drawPath(bawahTua, Paint()..color = AppColors.biruTua);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
