class Teknisi {
  final String nama;
  final String rating;
  final int jumlahUlasan;
  final String kendaraan;
  final String plat;
  final String telepon;
  final String testimoni;
  final bool terverifikasi;

  const Teknisi({
    required this.nama,
    required this.rating,
    required this.jumlahUlasan,
    required this.kendaraan,
    required this.plat,
    required this.telepon,
    required this.testimoni,
    this.terverifikasi = true,
  });
}

// Data dummy, nanti diganti data dari API Laravel
const teknisiDummy = Teknisi(
  nama: 'GanAnWo',
  rating: '4.9',
  jumlahUlasan: 67,
  kendaraan: 'Honda Beat',
  plat: 'BP 4892 QL',
  telepon: '081234567890',
  testimoni: 'Teknisi yang hebat mantep pokoknya',
);
