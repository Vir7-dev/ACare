enum StatusLayanan {
  pengecekanAwal('Pengecekan Awal'),
  melakukanPerbaikan('Melakukan Perbaikan'),
  menungguPembayaran('Menunggu Pembayaran'),
  selesai('Selesai');

  final String label;
  const StatusLayanan(this.label);
}
