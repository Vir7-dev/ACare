import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/umum/splash_page.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ACareApp());
}

class ACareApp extends StatelessWidget {
  const ACareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.biru)
            .copyWith(primary: AppColors.biru, error: AppColors.merah),
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        scaffoldBackgroundColor: AppColors.latar,
        // Semua tombol: sudut 12, tinggi minimal 48 (area sentuh).
        filledButtonTheme: FilledButtonThemeData(style: _gayaTombol),
        elevatedButtonTheme: ElevatedButtonThemeData(style: _gayaTombol),
        outlinedButtonTheme: OutlinedButtonThemeData(style: _gayaTombol),
        // Navigasi bawah sama untuk Pelanggan dan Teknisi.
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: AppColors.biruMuda,
          elevation: 3,
          shadowColor: Color(0x1A000000),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

final _gayaTombol = ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
