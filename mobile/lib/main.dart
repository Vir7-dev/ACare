import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/role_select_page.dart';
import 'pages/umum/splash_page.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ACareApp());
}

/// Dipakai untuk berpindah halaman dari luar widget (sesi berakhir).
final navigatorKey = GlobalKey<NavigatorState>();
final pesanKey = GlobalKey<ScaffoldMessengerState>();

class ACareApp extends StatefulWidget {
  const ACareApp({super.key});

  @override
  State<ACareApp> createState() => _ACareAppState();
}

class _ACareAppState extends State<ACareApp> {
  @override
  void initState() {
    super.initState();
    ApiClient.sesiBerakhir.addListener(_sesiBerakhir);
  }

  @override
  void dispose() {
    ApiClient.sesiBerakhir.removeListener(_sesiBerakhir);
    super.dispose();
  }

  /// Server menolak token saat pengguna sedang memakai aplikasi (token
  /// kedaluwarsa atau akun diblokir): kembali ke pemilihan peran.
  Future<void> _sesiBerakhir() async {
    // Saat aplikasi baru dibuka, splash yang menangani sesi tidak valid.
    if (AuthService.akun.value == null) return;
    await AuthService.bersihkanSesi();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RoleSelectPage()),
      (_) => false,
    );
    pesanKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Sesi kamu berakhir. Silakan masuk lagi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACare',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: pesanKey,
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
