import 'dart:async';
import 'dart:io';

import 'package:acare_mobile/services/perangkat.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Environment test memakai font "Ahem" yang lebar hurufnya tidak realistis,
/// sehingga teks sering overflow. Di sini Roboto bawaan SDK Flutter dipakai
/// sebagai pengganti (termasuk untuk Plus Jakarta Sans) supaya ukuran teks
/// di test mendekati aslinya, dan font tidak diunduh dari internet.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Setiap test mulai dengan penyimpanan kosong dan fitur perangkat asli
  // (yang diganti tiruan di test yang membutuhkan).
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Perangkat.reset();
  });

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final dir = '$root/bin/cache/artifacts/material_fonts';
    const berkas = {
      'regular': 'Roboto-Regular.ttf',
      '500': 'Roboto-Medium.ttf',
      '600': 'Roboto-Bold.ttf',
      '700': 'Roboto-Bold.ttf',
      '800': 'Roboto-Black.ttf',
    };

    Future<ByteData> baca(String nama) async {
      final bytes = await File('$dir/$nama').readAsBytes();
      return ByteData.view(bytes.buffer);
    }

    Future<void> muat(String keluarga, String nama) async {
      final loader = FontLoader(keluarga)..addFont(baca(nama));
      await loader.load();
    }

    if (Directory(dir).existsSync()) {
      await muat('Roboto', 'Roboto-Regular.ttf');
      for (final e in berkas.entries) {
        await muat('PlusJakartaSans_${e.key}', e.value);
      }
    }
  }

  await testMain();
}
