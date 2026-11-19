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
      ),
      home: const SplashPage(),
    );
  }
}
