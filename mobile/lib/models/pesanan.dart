enum StatusPesanan { selesai, dibatalkan }

class Pesanan {
  final String kode;
  final DateTime tanggal;
  final String namaLayanan;
  final String detailUnit;
  final String namaTeknisi;
  final int totalBiaya;
  final StatusPesanan status;
  final String? alasanBatal;

  const Pesanan({
    required this.kode,
    required this.tanggal,
    required this.namaLayanan,
    required this.detailUnit,
    required this.namaTeknisi,
    required this.totalBiaya,
    required this.status,
    this.alasanBatal,
  });
}

// Data dummy, nanti diganti data dari API Laravel
final List<Pesanan> dummyPesanan = [
  Pesanan(
    kode: '#AC-7710',
    tanggal: DateTime(2026, 10, 8, 10, 30),
    namaLayanan: 'Servis Berkala & Tambah Freon R32',
    detailUnit: '1 Unit AC Daikin 1.5 PK • Ruang Keluarga',
    namaTeknisi: 'Budi Santoso',
    totalBiaya: 310000,
    status: StatusPesanan.selesai,
  ),
  Pesanan(
    kode: '#AC-7634',
    tanggal: DateTime(2026, 10, 2, 14, 15),
    namaLayanan: 'Cuci AC',
    detailUnit: '2 Unit AC Panasonic 1 PK • Kamar Tidur',
    namaTeknisi: 'Rudi Hartono',
    totalBiaya: 175000,
    status: StatusPesanan.selesai,
  ),
  Pesanan(
    kode: '#AC-7421',
    tanggal: DateTime(2026, 9, 21, 9, 0),
    namaLayanan: 'Servis AC',
    detailUnit: '1 Unit AC LG 1 PK • Ruang Kerja',
    namaTeknisi: 'Andi Wijaya',
    totalBiaya: 487500,
    status: StatusPesanan.selesai,
  ),
  Pesanan(
    kode: '#AC-7188',
    tanggal: DateTime(2026, 9, 9, 16, 20),
    namaLayanan: 'Isi Freon R410A',
    detailUnit: '1 Unit AC Sharp 2 PK • Ruang Tamu',
    // Dibatalkan saat mencari teknisi: biaya awal tertahan, belum refund.
    namaTeknisi: '-',
    totalBiaya: 150000,
    status: StatusPesanan.dibatalkan,
    alasanBatal: 'Dibatalkan oleh pelanggan saat mencari teknisi',
  ),
  Pesanan(
    kode: '#AC-6950',
    tanggal: DateTime(2026, 8, 27, 11, 45),
    namaLayanan: 'Bongkar Pasang AC',
    detailUnit: '1 Unit AC Daikin 1 PK • Kamar Anak',
    namaTeknisi: 'Joko Susilo',
    totalBiaya: 450000,
    status: StatusPesanan.selesai,
  ),
  Pesanan(
    kode: '#AC-6712',
    tanggal: DateTime(2026, 8, 15, 16, 45),
    namaLayanan: 'Perbaikan Modul PCB & Sensor Suhu',
    detailUnit: '1 Unit AC Sharp 1 PK • Kamar Tidur',
    // Refund-nya sudah ditransfer (lihat RefundService).
    namaTeknisi: '-',
    totalBiaya: 100000,
    status: StatusPesanan.dibatalkan,
    alasanBatal: 'Tidak ada teknisi yang menerima dalam batas waktu',
  ),
  Pesanan(
    kode: '#AC-6403',
    tanggal: DateTime(2026, 7, 30, 8, 30),
    namaLayanan: 'Cuci AC',
    detailUnit: '3 Unit AC Gree 1 PK • Kantor',
    namaTeknisi: 'Budi Santoso',
    totalBiaya: 255000,
    status: StatusPesanan.selesai,
  ),
  Pesanan(
    kode: '#AC-6127',
    tanggal: DateTime(2026, 7, 12, 13, 10),
    namaLayanan: 'Servis AC',
    detailUnit: '1 Unit AC Midea 0.5 PK • Kamar Tidur',
    namaTeknisi: 'Andi Wijaya',
    // Biaya perbaikan ditolak: pesanan selesai dengan biaya awal saja.
    totalBiaya: 100000,
    status: StatusPesanan.selesai,
  ),
];
