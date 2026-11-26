enum StatusPesanan { selesai, dibatalkan }

/// Pesanan yang sudah selesai atau dibatalkan (halaman Riwayat).
class Pesanan {
  /// Id di server; `null` untuk data contoh.
  final int? id;
  final String kode;
  final DateTime tanggal;
  final String namaLayanan;
  final String detailUnit;
  final String namaTeknisi;
  final int totalBiaya;
  final StatusPesanan status;
  final String? alasanBatal;

  /// Pesanan batal yang sudah dibayar: dana menunggu refund. Pesanan batal
  /// yang belum dibayar tidak punya dana untuk dikembalikan.
  final bool danaTertahan;

  const Pesanan({
    this.id,
    required this.kode,
    required this.tanggal,
    required this.namaLayanan,
    required this.detailUnit,
    required this.namaTeknisi,
    required this.totalBiaya,
    required this.status,
    this.alasanBatal,
    this.danaTertahan = true,
  });

  /// Dari `PesananResource` (status `selesai` atau `dibatalkan`).
  factory Pesanan.dariJson(Map<String, dynamic> j) {
    final waktu = j['waktu'] as Map<String, dynamic>? ?? const {};
    final batal = j['status'] == 'dibatalkan';
    final tanggal =
        DateTime.tryParse(
          (batal ? waktu['dibatalkan'] : waktu['selesai']) as String? ??
              waktu['dibuat'] as String? ??
              '',
        )?.toLocal() ??
        DateTime.now();
    final pembayaran = (j['pembayaran'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final tertahan = pembayaran.where((p) => p['status'] == 'tertahan');
    final unit = (j['jumlah_unit'] as num?)?.toInt() ?? 1;
    final pk = (j['pk'] as num?)?.toDouble();
    final merek = (j['merek'] as String?)?.trim();
    return Pesanan(
      id: j['id'] as int?,
      kode: '#${j['kode']}',
      tanggal: tanggal,
      namaLayanan:
          (j['layanan'] as Map<String, dynamic>?)?['nama'] as String? ?? '-',
      detailUnit: [
        '$unit Unit AC',
        if (merek != null && merek.isNotEmpty) merek,
        if (pk != null) '${pk == pk.roundToDouble() ? pk.toInt() : pk} PK',
      ].join(' '),
      namaTeknisi:
          (j['teknisi'] as Map<String, dynamic>?)?['nama'] as String? ?? '-',
      totalBiaya: batal
          ? tertahan.fold(
              0,
              (a, p) => a + ((p['jumlah'] as num?)?.toInt() ?? 0),
            )
          : ((j['biaya'] as Map<String, dynamic>?)?['total'] as num?)
                    ?.toInt() ??
                0,
      status: batal ? StatusPesanan.dibatalkan : StatusPesanan.selesai,
      alasanBatal: j['alasan_pembatalan'] as String?,
      danaTertahan: tertahan.isNotEmpty,
    );
  }
}

// Data dummy, nanti diganti data dari API Laravel
final List<Pesanan> dummyPesanan = [
  Pesanan(
    kode: '#AC-7710',
    tanggal: DateTime(2026, 10, 8, 10, 30),
    namaLayanan: 'Service AC',
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
