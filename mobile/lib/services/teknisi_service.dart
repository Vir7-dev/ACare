import 'package:flutter/foundation.dart';

import '../models/pesanan_teknisi.dart';

/// Status kerja teknisi: online/offline, pesanan masuk, pesanan aktif, dan
/// dompet. Semua data masih tiruan di memori.
///
/// TODO(backend): ganti dengan API dan push notification untuk pesanan masuk,
/// pembaruan tahap, penyelesaian order, dan pencairan saldo.
class TeknisiService extends ChangeNotifier {
  TeknisiService._();
  static final TeknisiService instance = TeknisiService._();

  /// Batas waktu teknisi menjawab pesanan masuk.
  static const Duration batasTerima = Duration(seconds: 30);
  static const int minimalPencairan = 50000;
  static const int batasHarianPencairan = 2000000;

  /// TODO(backend): ID mitra berasal dari akun teknisi.
  static const String idMitra = 'TK-8802';

  bool _online = true;
  PesananTeknisi? _masuk;
  DateTime? _batasMasuk;
  PesananTeknisi? _aktif;
  final List<PesananTeknisi> _riwayat = _riwayatContoh();

  int _saldo = 850000;
  int _pendapatanHariIni = 250000;
  int _orderSelesaiHariIni = 2;
  int targetOrder = 5;
  int _nomor = 42;

  final List<RekeningTujuan> _rekening = [
    const RekeningTujuan(
      bank: 'BCA',
      nomor: '1234567890',
      atasNama: 'GanAnWo',
      utama: true,
    ),
  ];

  final List<TransaksiDompet> _transaksi = _transaksiContoh();

  bool get online => _online;
  PesananTeknisi? get pesananMasuk => _masuk;
  DateTime? get batasMasuk => _batasMasuk;
  PesananTeknisi? get pesananAktif => _aktif;
  List<PesananTeknisi> get riwayat => List.unmodifiable(_riwayat);
  int get saldo => _saldo;
  int get pendapatanHariIni => _pendapatanHariIni;
  int get orderSelesaiHariIni => _orderSelesaiHariIni;

  /// Pendapatan dari order yang masih berjalan, belum bisa ditarik.
  int get saldoTertahan => _aktif?.pendapatanBersih ?? 0;
  int get jumlahOrderTertahan => _aktif == null ? 0 : 1;
  List<RekeningTujuan> get rekening => List.unmodifiable(_rekening);
  List<TransaksiDompet> get transaksi => List.unmodifiable(_transaksi);

  /// Menghapus riwayat, untuk menguji kondisi "belum ada riwayat".
  @visibleForTesting
  void kosongkanRiwayat() {
    _riwayat.clear();
    notifyListeners();
  }

  /// Mengembalikan semua data ke kondisi awal (dipakai test).
  void reset() {
    _online = true;
    _masuk = null;
    _batasMasuk = null;
    _aktif = null;
    _riwayat
      ..clear()
      ..addAll(_riwayatContoh());
    _saldo = 850000;
    _pendapatanHariIni = 250000;
    _orderSelesaiHariIni = 2;
    _nomor = 42;
    _rekening
      ..clear()
      ..add(const RekeningTujuan(
        bank: 'BCA',
        nomor: '1234567890',
        atasNama: 'GanAnWo',
        utama: true,
      ));
    _transaksi
      ..clear()
      ..addAll(_transaksiContoh());
    notifyListeners();
  }

  void setOnline(bool nilai) {
    if (_online == nilai) return;
    _online = nilai;
    if (!nilai) {
      _masuk = null;
      _batasMasuk = null;
    }
    notifyListeners();
  }

  /// Menyiapkan satu pesanan masuk tiruan bila teknisi online dan sedang
  /// tidak ada pesanan masuk maupun aktif.
  void periksaPesananMasuk() {
    if (!_online || _masuk != null || _aktif != null) return;
    _nomor++;
    _masuk = PesananTeknisi(
      id: 'ORD-20240518-0$_nomor',
      layanan: 'Cek AC (Diagnosis Kerusakan)',
      deskripsiLayanan: 'Pemeriksaan unit indoor dan outdoor',
      ongkosAwal: 50000,
      pelanggan: 'Bpk. Hendra Gunawan',
      ratingPelanggan: '4.9',
      telepon: '081234567890',
      alamat: 'Jl. Engku Putri No. 12',
      wilayah: 'Batam Centre, Kota Batam',
      jarakKm: 2.1,
      estimasiMenit: 7,
      unitAc: 'Split Wall 1 PK Daikin Inverter',
      catatanMasalah:
          'AC kamar utama netes air dan tidak dingin, tolong dicek dulu '
          'kerusakannya.',
    );
    _batasMasuk = DateTime.now().add(batasTerima);
    notifyListeners();
  }

  /// Pesanan masuk habis waktu atau ditolak: kembali menunggu.
  void tolakPesanan() {
    _masuk = null;
    _batasMasuk = null;
    notifyListeners();
  }

  /// Menerima pesanan masuk. Mengembalikan false bila sudah tidak tersedia.
  bool terimaPesanan() {
    final p = _masuk;
    if (p == null || _aktif != null) return false;
    _aktif = p;
    p.waktuTahap[TahapKerja.menujuLokasi] = DateTime.now();
    _masuk = null;
    _batasMasuk = null;
    notifyListeners();
    return true;
  }

  /// Memajukan pesanan aktif ke tahap berikutnya (selain persetujuan biaya
  /// dan penyelesaian, yang punya layar sendiri).
  void majukanTahap() {
    final p = _aktif;
    if (p == null) return;
    switch (p.tahap) {
      case TahapKerja.menujuLokasi:
        p.tahap = TahapKerja.tiba;
      case TahapKerja.tiba:
        p.tahap = TahapKerja.diagnosis;
      default:
        return;
    }
    p.waktuTahap[p.tahap] = DateTime.now();
    notifyListeners();
  }

  /// Mengirim rincian biaya ke pelanggan.
  void kirimRincianBiaya(List<ItemBiaya> item, String catatan) {
    final p = _aktif;
    if (p == null) return;
    p.itemBiaya = List.unmodifiable(item);
    p.catatanUntukPelanggan = catatan.trim();
    p.tahap = TahapKerja.menungguPersetujuan;
    p.waktuTahap[p.tahap] = DateTime.now();
    notifyListeners();
  }

  /// Pelanggan menyetujui biaya.
  /// TODO(backend): dipicu oleh respons pelanggan, bukan tombol di sini.
  void biayaDisetujui() {
    final p = _aktif;
    if (p == null || p.tahap != TahapKerja.menungguPersetujuan) return;
    p.tahap = TahapKerja.pengerjaan;
    p.waktuTahap[p.tahap] = DateTime.now();
    notifyListeners();
  }

  /// Menyelesaikan order: pendapatan bersih masuk ke saldo dompet.
  void selesaikanOrder({
    required String ringkasan,
    required int jumlahFoto,
  }) {
    final p = _aktif;
    if (p == null) return;
    p.ringkasanPekerjaan = ringkasan.trim();
    p.jumlahFotoBukti = jumlahFoto;
    p.tahap = TahapKerja.selesai;
    p.selesaiPada = DateTime.now();
    p.waktuTahap[p.tahap] = p.selesaiPada!;
    _saldo += p.pendapatanBersih;
    _pendapatanHariIni += p.pendapatanBersih;
    _orderSelesaiHariIni++;
    _transaksi.insert(
      0,
      TransaksiDompet(
        judul: 'Order ${p.id}',
        waktu: DateTime.now(),
        nominal: p.pendapatanBersih,
      ),
    );
    _riwayat.insert(0, p);
    _aktif = null;
    notifyListeners();
  }

  void tambahRekening(RekeningTujuan r) {
    _rekening.add(r);
    notifyListeners();
  }

  /// Mencairkan saldo. Mengembalikan bukti, atau null bila nominal tidak sah.
  BuktiPencairan? cairkan(int nominal, RekeningTujuan tujuan) {
    if (nominal < minimalPencairan || nominal > _saldo) return null;
    _saldo -= nominal;
    final waktu = DateTime.now();
    _transaksi.insert(
      0,
      TransaksiDompet(
        judul: 'Pencairan ke ${tujuan.bank}',
        waktu: waktu,
        nominal: -nominal,
      ),
    );
    notifyListeners();
    return BuktiPencairan(
      id: '#WD-${waktu.year}${waktu.month.toString().padLeft(2, '0')}'
          '${waktu.day.toString().padLeft(2, '0')}-'
          '${(waktu.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}',
      nominal: nominal,
      rekening: tujuan,
      waktu: waktu,
    );
  }
}


PesananTeknisi _riwayatItem({
  required String id,
  required String layanan,
  required String pelanggan,
  required String alamat,
  required String wilayah,
  required String unitAc,
  required String keluhan,
  required DateTime selesai,
  required List<ItemBiaya> biaya,
  required String ringkasan,
  int ongkosAwal = 50000,
  int? rating,
  String ulasan = '',
  bool biayaDitolak = false,
  int foto = 2,
}) {
  final p = PesananTeknisi(
    id: id,
    layanan: layanan,
    deskripsiLayanan: '',
    ongkosAwal: ongkosAwal,
    pelanggan: pelanggan,
    ratingPelanggan: '-',
    telepon: '081200000000',
    alamat: alamat,
    wilayah: wilayah,
    jarakKm: 0,
    estimasiMenit: 0,
    unitAc: unitAc,
    catatanMasalah: keluhan,
    tahap: TahapKerja.selesai,
    itemBiaya: biaya,
    ringkasanPekerjaan: ringkasan,
    jumlahFotoBukti: foto,
    selesaiPada: selesai,
    ratingDiterima: rating,
    ulasanDiterima: ulasan,
    biayaDitolak: biayaDitolak,
  );
  return p;
}

/// Riwayat contoh, terbaru di atas.
// TODO(backend): ganti dengan riwayat layanan dari API.
List<PesananTeknisi> _riwayatContoh() => [
  _riwayatItem(
    id: 'ORD-20240518-041',
    layanan: 'Service AC',
    pelanggan: 'Ibu Sari Wulandari',
    alamat: 'Jl. Ahmad Yani Blok C No. 5',
    wilayah: 'Batam Centre',
    unitAc: 'Split Wall 1 PK Panasonic',
    keluhan: 'AC tidak dingin dan berbunyi berisik.',
    selesai: DateTime(2024, 5, 18, 14, 20),
    biaya: const [
      ItemBiaya(
        jenis: JenisItemBiaya.jasa,
        nama: 'Jasa perbaikan unit outdoor',
        harga: 100000,
      ),
      ItemBiaya(
        jenis: JenisItemBiaya.sparepart,
        nama: 'Kapasitor 35 uF',
        harga: 50000,
      ),
    ],
    ringkasan:
        'Kapasitor outdoor diganti, tekanan freon dicek normal. Unit '
        'dingin dan tidak berisik lagi.',
    rating: 5,
    ulasan: 'Teknisinya ramah dan pengerjaannya rapi. AC kembali dingin.',
    foto: 3,
  ),
  _riwayatItem(
    id: 'ORD-20240518-039',
    layanan: 'Cuci AC',
    pelanggan: 'Bpk. Andi Pratama',
    alamat: 'Perumahan Tiban Indah Blok F No. 8',
    wilayah: 'Sekupang',
    unitAc: 'Split Wall 1.5 PK Daikin',
    keluhan: 'Sudah lama tidak dicuci, hembusan angin berbau.',
    selesai: DateTime(2024, 5, 18, 10, 5),
    biaya: const [
      ItemBiaya(
        jenis: JenisItemBiaya.jasa,
        nama: 'Cuci indoor dan outdoor',
        harga: 50000,
      ),
    ],
    ringkasan: 'Indoor dan outdoor dicuci bersih, filter dibersihkan.',
    rating: 4,
  ),
  _riwayatItem(
    id: 'ORD-20240517-036',
    layanan: 'Isi Freon',
    pelanggan: 'Ibu Rina Marlina',
    alamat: 'Jl. Raja Ali Haji No. 21',
    wilayah: 'Batu Aji',
    unitAc: 'Split Wall 1 PK LG',
    keluhan: 'Dingin tidak maksimal, diduga freon berkurang.',
    selesai: DateTime(2024, 5, 17, 16, 40),
    ongkosAwal: 150000,
    biaya: const [],
    ringkasan: 'Freon R32 diisi penuh, tidak ditemukan kebocoran.',
  ),
  _riwayatItem(
    id: 'ORD-20240516-031',
    layanan: 'Cek AC (Diagnosis Kerusakan)',
    pelanggan: 'Bpk. Dedi Kurniawan',
    alamat: 'Jl. Imam Bonjol No. 3',
    wilayah: 'Nagoya',
    unitAc: 'Split Cassette 2 PK Sharp',
    keluhan: 'AC mati total.',
    selesai: DateTime(2024, 5, 16, 11, 15),
    biaya: const [],
    ringkasan:
        'Kerusakan pada modul PCB. Pelanggan menolak biaya perbaikan, '
        'pesanan selesai dengan biaya pengecekan.',
    rating: 3,
    ulasan: 'Cukup, tapi teknisi datang agak terlambat.',
    biayaDitolak: true,
    foto: 1,
  ),
];

List<TransaksiDompet> _transaksiContoh() => [
  TransaksiDompet(
    judul: 'Order ORD-20240518-041',
    waktu: DateTime(2024, 5, 18, 14, 20),
    nominal: 170000,
  ),
  TransaksiDompet(
    judul: 'Order ORD-20240518-039',
    waktu: DateTime(2024, 5, 18, 10, 5),
    nominal: 85000,
  ),
  TransaksiDompet(
    judul: 'Order ORD-20240517-036',
    waktu: DateTime(2024, 5, 17, 16, 40),
    nominal: 127500,
  ),
  TransaksiDompet(
    judul: 'Order ORD-20240516-031',
    waktu: DateTime(2024, 5, 16, 11, 15),
    nominal: 42500,
  ),
];
