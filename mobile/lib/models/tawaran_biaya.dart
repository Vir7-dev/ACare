/// Status tanggapan Pelanggan atas biaya perbaikan (`status_persetujuan`).
enum StatusTawaran {
  menunggu('Menunggu persetujuan'),
  disetujui('Disetujui'),
  ditolak('Ditolak'),
  kedaluwarsa('Kedaluwarsa');

  final String label;
  const StatusTawaran(this.label);
}

/// Satu baris rincian biaya perbaikan yang diisi Teknisi.
class ItemTawaran {
  final String nama;
  final int harga;

  /// true = jasa perbaikan, false = suku cadang atau material.
  final bool jasa;

  const ItemTawaran({
    required this.nama,
    required this.harga,
    required this.jasa,
  });
}

/// Biaya perbaikan yang diajukan Teknisi setelah pengecekan awal dan perlu
/// ditanggapi Pelanggan (UC-14). Padanan `detail_pesanan` yang diajukan
/// Teknisi di SKPPL.
class TawaranBiaya {
  final List<ItemTawaran> item;
  final String catatan;
  final int biayaAwal;
  final DateTime batasWaktu;
  final StatusTawaran status;

  const TawaranBiaya({
    required this.item,
    required this.catatan,
    required this.biayaAwal,
    required this.batasWaktu,
    this.status = StatusTawaran.menunggu,
  });

  int get biayaPerbaikan => item.fold(0, (a, i) => a + i.harga);

  /// Biaya awal + biaya perbaikan.
  int get totalTagihan => biayaAwal + biayaPerbaikan;

  bool get menunggu => status == StatusTawaran.menunggu;

  Duration sisaWaktu([DateTime? sekarang]) {
    final sisa = batasWaktu.difference(sekarang ?? DateTime.now());
    return sisa.isNegative ? Duration.zero : sisa;
  }

  TawaranBiaya denganStatus(StatusTawaran baru) => TawaranBiaya(
    item: item,
    catatan: catatan,
    biayaAwal: biayaAwal,
    batasWaktu: batasWaktu,
    status: baru,
  );
}
