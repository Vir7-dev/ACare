/// Tahapan pekerjaan teknisi yang tampil di halaman detail pesanan.
///
/// [menungguPembayaran] sengaja tidak dimasukkan ke [langkahTampil] karena
/// alur pembayaran masih disembunyikan; nilainya tetap ada supaya
/// `DetailPesananPage` masih bisa dibuka dengan status itu.
enum StatusLayanan {
  pengecekanAwal('Pengecekan Awal'),
  melakukanPerbaikan('Melakukan Perbaikan'),
  menungguPembayaran('Menunggu Pembayaran'),
  selesai('Selesai');

  /// Status yang ditampilkan di timeline (tanpa "Menunggu Pembayaran").
  static const langkahTampil = [pengecekanAwal, melakukanPerbaikan, selesai];

  final String label;
  const StatusLayanan(this.label);
}
