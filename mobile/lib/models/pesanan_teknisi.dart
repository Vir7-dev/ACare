/// Potongan platform dari total tagihan. Sisanya masuk ke dompet teknisi.
const int komisiPlatformPersen = 15;

/// Tahap pengerjaan dari sisi teknisi, berurutan.
enum TahapKerja {
  menujuLokasi('Menuju lokasi'),
  tiba('Tiba di lokasi'),
  diagnosis('Diagnosis'),
  menungguPersetujuan('Menunggu persetujuan biaya'),
  pengerjaan('Pengerjaan'),
  selesai('Selesai');

  final String label;
  const TahapKerja(this.label);
}

enum JenisItemBiaya { jasa, sparepart }

class ItemBiaya {
  final JenisItemBiaya jenis;
  final String nama;
  final int harga;

  const ItemBiaya({
    required this.jenis,
    required this.nama,
    required this.harga,
  });
}

class PesananTeknisi {
  final String id;
  final String layanan;
  final String deskripsiLayanan;
  final int ongkosAwal;
  final String pelanggan;
  final String ratingPelanggan;
  final String telepon;
  final String alamat;
  final String wilayah;
  final double jarakKm;
  final int estimasiMenit;
  final String unitAc;
  final String catatanMasalah;

  TahapKerja tahap;
  List<ItemBiaya> itemBiaya;
  String catatanUntukPelanggan;
  String ringkasanPekerjaan;
  int jumlahFotoBukti;

  /// Kapan order diselesaikan.
  DateTime? selesaiPada;

  /// Rating 1-5 dari Pelanggan; `null` bila belum dinilai.
  // TODO(backend): dari tabel rating_ulasan setelah Pelanggan memberi ulasan.
  int? ratingDiterima;
  String ulasanDiterima;

  /// Pelanggan menolak biaya perbaikan: pesanan selesai hanya dengan biaya
  /// awal.
  bool biayaDitolak;

  /// Kapan tiap tahap dimulai, untuk jam di stepper pengerjaan.
  final Map<TahapKerja, DateTime> waktuTahap = {};

  PesananTeknisi({
    required this.id,
    required this.layanan,
    required this.deskripsiLayanan,
    required this.ongkosAwal,
    required this.pelanggan,
    required this.ratingPelanggan,
    required this.telepon,
    required this.alamat,
    required this.wilayah,
    required this.jarakKm,
    required this.estimasiMenit,
    required this.unitAc,
    required this.catatanMasalah,
    this.tahap = TahapKerja.menujuLokasi,
    this.itemBiaya = const [],
    this.catatanUntukPelanggan = '',
    this.ringkasanPekerjaan = '',
    this.jumlahFotoBukti = 0,
    this.selesaiPada,
    this.ratingDiterima,
    this.ulasanDiterima = '',
    this.biayaDitolak = false,
  });

  int get biayaTambahan => itemBiaya.fold(0, (a, b) => a + b.harga);

  int get totalTagihan => ongkosAwal + biayaTambahan;

  int get potonganPlatform => totalTagihan * komisiPlatformPersen ~/ 100;

  /// Yang diterima teknisi setelah potongan platform.
  int get pendapatanBersih => totalTagihan - potonganPlatform;
}

class RekeningTujuan {
  final String bank;
  final String nomor;
  final String atasNama;
  final bool eWallet;
  final bool utama;

  const RekeningTujuan({
    required this.bank,
    required this.nomor,
    required this.atasNama,
    this.eWallet = false,
    this.utama = false,
  });

  /// Nomor disamarkan, hanya empat digit terakhir yang terlihat.
  String get nomorSamar {
    final akhir = nomor.length <= 4 ? nomor : nomor.substring(nomor.length - 4);
    return '$bank  ••••  $akhir';
  }
}

class TransaksiDompet {
  final String judul;
  final DateTime waktu;

  /// Positif untuk pemasukan, negatif untuk penarikan.
  final int nominal;

  const TransaksiDompet({
    required this.judul,
    required this.waktu,
    required this.nominal,
  });
}

class BuktiPencairan {
  final String id;
  final int nominal;
  final RekeningTujuan rekening;
  final DateTime waktu;

  const BuktiPencairan({
    required this.id,
    required this.nominal,
    required this.rekening,
    required this.waktu,
  });
}
