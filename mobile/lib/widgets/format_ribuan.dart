import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _ribuan = NumberFormat.decimalPattern('id_ID');

/// Teks angka bertitik ("100.000") ke int; kosong atau tidak valid jadi 0.
int angkaDari(String teks) =>
    int.tryParse(teks.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Angka ke teks bertitik, misal 100000 -> "100.000".
String ribuan(int nilai) => _ribuan.format(nilai);

/// Formatter kolom nominal: hanya angka, ditampilkan dengan titik ribuan
/// agar sama dengan penulisan rupiah di bagian lain aplikasi.
class FormatRibuan extends TextInputFormatter {
  const FormatRibuan();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digit = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit.isEmpty) return const TextEditingValue();
    final teks = ribuan(int.parse(digit));
    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}
