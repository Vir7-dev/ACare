import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/kelola_profil_teknisi_page.dart';

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
        colorSchemeSeed: const Color(0xFF0B6E99),
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      home: const KelolaProfilTeknisiPage(),
    );
  }
}
