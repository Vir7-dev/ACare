import 'package:flutter/material.dart';

/// Metode pembayaran non-tunai yang diproses lewat payment gateway (Xendit).
/// Dipakai untuk pembayaran awal maupun pelunasan biaya perbaikan.
enum MetodeBayar {
  qris('QRIS', 'Bayar dari e-wallet atau m-banking apa pun', Icons.qr_code_2),
  eWallet(
    'E-Wallet',
    'DANA, OVO, ShopeePay',
    Icons.account_balance_wallet_outlined,
  ),
  virtualAccount(
    'Virtual Account',
    'BCA, BNI, BRI, Mandiri',
    Icons.account_balance_outlined,
  );

  final String label;
  final String keterangan;
  final IconData ikon;

  const MetodeBayar(this.label, this.keterangan, this.ikon);
}
