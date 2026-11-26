/// Cara membayar tagihan yang sedang berjalan di Xendit.
class InstruksiBayar {
  /// channel_code Xendit, misal `QRIS` atau `BNI_VIRTUAL_ACCOUNT`.
  final String metode;
  final String namaMetode;

  /// `qr`, `va`, atau `ewallet`.
  final String jenis;

  /// Isi kode QRIS atau nomor Virtual Account.
  final String? kode;

  /// Tautan pembayaran e-wallet.
  final String? url;
  final DateTime kedaluwarsaPada;

  const InstruksiBayar({
    required this.metode,
    required this.namaMetode,
    required this.jenis,
    this.kode,
    this.url,
    required this.kedaluwarsaPada,
  });

  factory InstruksiBayar.dariJson(Map<String, dynamic> j) => InstruksiBayar(
    metode: j['metode'] as String,
    namaMetode: j['nama_metode'] as String? ?? j['metode'] as String,
    jenis: j['jenis'] as String? ?? 'qr',
    kode: j['kode'] as String?,
    url: j['url'] as String?,
    kedaluwarsaPada: DateTime.parse(j['kedaluwarsa_pada'] as String).toLocal(),
  );
}

/// Keadaan satu tagihan (biaya awal atau pelunasan) dari server.
class StatusTagihan {
  final int id;

  /// menunggu, berhasil, kedaluwarsa, tertahan, ...
  final String status;
  final int jumlah;

  /// Null bila tagihan belum dibuat di Xendit atau sudah lewat batasnya.
  final InstruksiBayar? instruksi;

  /// Server mengizinkan tombol simulasi (hanya mode pengembangan).
  final bool bisaSimulasi;

  const StatusTagihan({
    required this.id,
    required this.status,
    required this.jumlah,
    this.instruksi,
    this.bisaSimulasi = false,
  });

  bool get lunas => status == 'berhasil';
  bool get menunggu => status == 'menunggu';

  /// Ambil tagihan [idPembayaran] dari data pesanan (respons API).
  static StatusTagihan dariPesanan(
    Map<String, dynamic> data,
    int idPembayaran,
  ) {
    final daftar = (data['pembayaran'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final p = daftar.firstWhere(
      (x) => x['id'] == idPembayaran,
      orElse: () => {'id': idPembayaran, 'status': 'tidak_ada', 'jumlah': 0},
    );
    final instruksi = p['instruksi'];
    return StatusTagihan(
      id: idPembayaran,
      status: p['status'] as String,
      jumlah: (p['jumlah'] as num? ?? 0).toInt(),
      instruksi: instruksi is Map<String, dynamic>
          ? InstruksiBayar.dariJson(instruksi)
          : null,
      bisaSimulasi: data['bisa_simulasi_bayar'] == true,
    );
  }
}
