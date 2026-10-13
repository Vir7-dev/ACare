class KomponenTagihan {
  final String nama;
  final int harga;

  const KomponenTagihan(this.nama, this.harga);
}

class Tagihan {
  final int pemeriksaan;
  final List<KomponenTagihan> komponen;

  const Tagihan({required this.pemeriksaan, required this.komponen});

  int get totalKomponen => komponen.fold(0, (a, k) => a + k.harga);
  int get total => pemeriksaan + totalKomponen;
}

// Data dummy, nanti diganti data dari API Laravel
const tagihanDummy = Tagihan(
  pemeriksaan: 50000,
  komponen: [KomponenTagihan('Filter', 20000), KomponenTagihan('Blower', 30000)],
);
