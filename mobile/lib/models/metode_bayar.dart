import 'package:flutter/material.dart';

/// Satu pilihan pembayaran di Xendit. [kode] = channel_code yang dikirim
/// ke server (harus sama dengan `Xendit::METODE` di backend).
class KanalBayar {
  final String kode;
  final String nama;

  const KanalBayar(this.kode, this.nama);
}

/// Kelompok metode pembayaran non-tunai yang diproses lewat Xendit.
/// Dipakai untuk pembayaran awal maupun pelunasan biaya perbaikan.
enum MetodeBayar {
  qris('QRIS', 'Bayar dari e-wallet atau m-banking apa pun', Icons.qr_code_2, [
    KanalBayar('QRIS', 'QRIS'),
  ]),
  eWallet(
    'E-Wallet',
    'DANA, ShopeePay',
    Icons.account_balance_wallet_outlined,
    [KanalBayar('DANA', 'DANA'), KanalBayar('SHOPEEPAY', 'ShopeePay')],
  ),
  virtualAccount(
    'Virtual Account',
    'BNI, BRI, Mandiri',
    Icons.account_balance_outlined,
    [
      KanalBayar('BNI_VIRTUAL_ACCOUNT', 'BNI'),
      KanalBayar('BRI_VIRTUAL_ACCOUNT', 'BRI'),
      KanalBayar('MANDIRI_VIRTUAL_ACCOUNT', 'Mandiri'),
    ],
  );

  final String label;
  final String keterangan;
  final IconData ikon;

  /// Pilihan di dalam kelompok ini; bila hanya satu, langsung dipakai.
  final List<KanalBayar> kanal;

  const MetodeBayar(this.label, this.keterangan, this.ikon, this.kanal);
}
