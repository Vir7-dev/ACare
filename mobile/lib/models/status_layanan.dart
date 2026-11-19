/// Tahapan pekerjaan teknisi yang dilihat pelanggan di halaman detail pesanan.
///
/// Urutan nilai mengikuti alur pesanan. [menungguPersetujuanBiaya] tidak
/// punya langkah sendiri di garis waktu: ia digabung ke langkah
/// [pengecekanAwal] (lihat [langkah]), sesuai pengelompokan status pelanggan.
enum StatusLayanan {
  pengecekanAwal('Pengecekan Awal'),
  menungguPersetujuanBiaya('Menunggu Persetujuan Biaya'),
  melakukanPerbaikan('Melakukan Perbaikan'),
  menungguPembayaran('Menunggu Pembayaran'),
  selesai('Selesai');

  /// Langkah yang tampil di garis waktu pelanggan.
  static const langkahTampil = [
    pengecekanAwal,
    melakukanPerbaikan,
    menungguPembayaran,
    selesai,
  ];

  final String label;
  const StatusLayanan(this.label);

  /// Langkah garis waktu tempat status ini ditampilkan.
  StatusLayanan get langkah =>
      this == menungguPersetujuanBiaya ? pengecekanAwal : this;
}
