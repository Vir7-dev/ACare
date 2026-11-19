import 'package:flutter/foundation.dart';

enum TujuanRefund {
  rekening('Rekening Bank'),
  eWallet('E-Wallet');

  final String label;
  const TujuanRefund(this.label);
}

enum StatusRefund {
  menunggu('Menunggu diproses Admin'),
  disetujui('Disetujui, menunggu transfer'),
  ditolak('Ditolak'),
  selesai('Dana sudah ditransfer');

  final String label;
  const StatusRefund(this.label);
}

/// Pengajuan refund pelanggan untuk pesanan yang dibatalkan (UC-17).
/// Dana dikembalikan manual oleh Admin ke rekening/e-wallet tujuan.
class PengajuanRefund {
  final String kodePesanan;
  final int nominal;
  final TujuanRefund tujuan;
  final String namaBank;
  final String nomor;
  final String atasNama;
  final StatusRefund status;
  final DateTime diajukanPada;

  const PengajuanRefund({
    required this.kodePesanan,
    required this.nominal,
    required this.tujuan,
    required this.namaBank,
    required this.nomor,
    required this.atasNama,
    required this.diajukanPada,
    this.status = StatusRefund.menunggu,
  });

  /// Nomor tujuan yang disamarkan, misal "•••• 7890".
  String get nomorSamar =>
      nomor.length <= 4 ? nomor : '•••• ${nomor.substring(nomor.length - 4)}';
}

/// Sumber tunggal pengajuan refund pelanggan (data tiruan).
// TODO(backend): ganti dengan API pengajuan_dana (jenis refund).
class RefundService {
  RefundService._();

  static final RefundService instance = RefundService._();

  static const daftarBank = ['BCA', 'BNI', 'BRI', 'Mandiri'];
  static const daftarEWallet = ['DANA', 'OVO', 'ShopeePay', 'GoPay'];

  /// Pengajuan per kode pesanan.
  final ValueNotifier<Map<String, PengajuanRefund>> pengajuan = ValueNotifier(
    _awal,
  );

  PengajuanRefund? untuk(String kodePesanan) => pengajuan.value[kodePesanan];

  /// Mengembalikan pesan galat bila refund untuk pesanan ini sudah diajukan.
  String? ajukan(PengajuanRefund refund) {
    if (pengajuan.value.containsKey(refund.kodePesanan)) {
      return 'Refund untuk pesanan ini sudah diajukan';
    }
    pengajuan.value = {...pengajuan.value, refund.kodePesanan: refund};
    return null;
  }

  void reset() => pengajuan.value = _awal;

  static final _awal = {
    '#AC-6712': PengajuanRefund(
      kodePesanan: '#AC-6712',
      nominal: 100000,
      tujuan: TujuanRefund.eWallet,
      namaBank: 'DANA',
      nomor: '081234567890',
      atasNama: 'Pelanggan Contoh',
      diajukanPada: DateTime(2026, 8, 15, 18, 0),
      status: StatusRefund.selesai,
    ),
  };
}
