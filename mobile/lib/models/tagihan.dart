class KomponenTagihan {
  final String nama;
  final int harga;

  const KomponenTagihan(this.nama, this.harga);
}

/// Tagihan sebuah pesanan.
///
/// [pemeriksaan] adalah biaya awal yang sudah dibayar saat memesan.
/// [komponen] adalah rincian biaya perbaikan yang diajukan teknisi setelah
/// pengecekan; kosong berarti tidak ada biaya tambahan.
class Tagihan {
  final int pemeriksaan;
  final List<KomponenTagihan> komponen;

  /// Catatan teknisi untuk pelanggan pada rincian biaya perbaikan.
  final String catatanTeknisi;

  const Tagihan({
    required this.pemeriksaan,
    required this.komponen,
    this.catatanTeknisi = '',
  });

  bool get adaBiayaPerbaikan => komponen.isNotEmpty;

  int get totalKomponen => komponen.fold(0, (a, k) => a + k.harga);

  /// Yang dibayar saat pelunasan (biaya awal sudah dibayar di muka).
  int get sisaTagihan => totalKomponen;

  int get total => pemeriksaan + totalKomponen;
}

// Data dummy, nanti diganti data dari API Laravel
const tagihanDummy = Tagihan(
  pemeriksaan: 50000,
  komponen: [
    KomponenTagihan('Filter', 20000),
    KomponenTagihan('Blower', 30000),
  ],
  catatanTeknisi:
      'Filter sudah rusak dan blower kotor, perlu diganti agar AC '
      'kembali dingin.',
);

/// Batas waktu pelanggan menanggapi rincian biaya perbaikan. Bila lewat,
/// biaya dianggap ditolak dan pesanan selesai dengan biaya awal saja.
/// Harus sama dengan Pesanan::BATAS_PERSETUJUAN_MENIT di backend.
const batasPersetujuanBiaya = Duration(minutes: 5);
