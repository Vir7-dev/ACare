/// Data akun dari `GET /api/saya` (pelanggan atau teknisi).
class Akun {
  final int id;
  final String nama;
  final String email;
  final String noTelepon;

  /// `pelanggan` atau `teknisi`.
  final String role;
  final String? fotoProfil;

  /// Hanya terisi untuk teknisi.
  final DataTeknisi? teknisi;

  const Akun({
    required this.id,
    required this.nama,
    required this.email,
    required this.noTelepon,
    required this.role,
    this.fotoProfil,
    this.teknisi,
  });

  factory Akun.dariJson(Map<String, dynamic> j) => Akun(
    id: j['id'] as int,
    nama: j['nama'] as String? ?? '',
    email: j['email'] as String? ?? '',
    noTelepon: j['no_telepon'] as String? ?? '',
    role: j['role'] as String? ?? 'pelanggan',
    fotoProfil: j['foto_profil'] as String?,
    teknisi: j['teknisi'] is Map<String, dynamic>
        ? DataTeknisi.dariJson(j['teknisi'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> keJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'no_telepon': noTelepon,
    'role': role,
    'foto_profil': fotoProfil,
    if (teknisi != null) 'teknisi': teknisi!.keJson(),
  };
}

class DataTeknisi {
  final String statusVerifikasi;
  final String jenisKendaraan;
  final String platNomor;
  final String deskripsi;
  final String namaBank;
  final String noRekening;
  final String atasNama;

  const DataTeknisi({
    required this.statusVerifikasi,
    required this.jenisKendaraan,
    required this.platNomor,
    required this.deskripsi,
    required this.namaBank,
    required this.noRekening,
    required this.atasNama,
  });

  factory DataTeknisi.dariJson(Map<String, dynamic> j) => DataTeknisi(
    statusVerifikasi: j['status_verifikasi'] as String? ?? 'menunggu',
    jenisKendaraan: j['jenis_kendaraan'] as String? ?? '',
    platNomor: j['plat_nomor'] as String? ?? '',
    deskripsi: j['deskripsi'] as String? ?? '',
    namaBank: j['nama_bank'] as String? ?? '',
    noRekening: j['no_rekening'] as String? ?? '',
    atasNama: j['atas_nama'] as String? ?? '',
  );

  Map<String, dynamic> keJson() => {
    'status_verifikasi': statusVerifikasi,
    'jenis_kendaraan': jenisKendaraan,
    'plat_nomor': platNomor,
    'deskripsi': deskripsi,
    'nama_bank': namaBank,
    'no_rekening': noRekening,
    'atas_nama': atasNama,
  };
}
