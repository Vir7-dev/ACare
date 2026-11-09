import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/pesanan_teknisi.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';

class _Baris {
  _Baris(this.jenis);

  final JenisItemBiaya jenis;
  final nama = TextEditingController();
  final harga = TextEditingController();

  int get nominal => int.tryParse(harga.text) ?? 0;
  bool get kosong => nama.text.trim().isEmpty && harga.text.isEmpty;
  bool get lengkap => nama.text.trim().isNotEmpty && nominal > 0;

  void dispose() {
    nama.dispose();
    harga.dispose();
  }
}

/// Teknisi mengisi biaya perbaikan setelah diagnosis, lalu mengirimnya ke
/// pelanggan untuk disetujui.
class InputBiayaPage extends StatefulWidget {
  const InputBiayaPage({super.key});

  @override
  State<InputBiayaPage> createState() => _InputBiayaPageState();
}

class _InputBiayaPageState extends State<InputBiayaPage> {
  final _service = TeknisiService.instance;
  final _catatan = TextEditingController();
  final List<_Baris> _baris = [
    _Baris(JenisItemBiaya.jasa),
    _Baris(JenisItemBiaya.sparepart),
  ];
  bool _dicoba = false;

  PesananTeknisi get _pesanan => _service.pesananAktif!;

  @override
  void dispose() {
    _catatan.dispose();
    for (final b in _baris) {
      b.dispose();
    }
    super.dispose();
  }

  List<_Baris> get _terisi => _baris.where((b) => !b.kosong).toList();

  int get _biayaPerbaikan =>
      _terisi.where((b) => b.lengkap).fold(0, (a, b) => a + b.nominal);

  int get _total => _pesanan.ongkosAwal + _biayaPerbaikan;

  void _tambah(JenisItemBiaya jenis) =>
      setState(() => _baris.add(_Baris(jenis)));

  void _hapus(_Baris b) {
    setState(() => _baris.remove(b));
    b.dispose();
  }

  void _kirim() {
    setState(() => _dicoba = true);
    final terisi = _terisi;
    if (terisi.isEmpty || terisi.any((b) => !b.lengkap)) return;

    _service.kirimRincianBiaya([
      for (final b in terisi)
        ItemBiaya(jenis: b.jenis, nama: b.nama.text.trim(), harga: b.nominal),
    ], _catatan.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pesanan = _pesanan;
    final potongan = _total * komisiPlatformPersen ~/ 100;
    final adaKosongSemua = _dicoba && _terisi.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      appBar: appBarTeknisi('Rincian biaya'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.biruMuda,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.biruAksen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nama pelanggan', style: gayaSamar(ukuran: 11)),
                          Text(pesanan.pelanggan, style: gayaJudul()),
                        ],
                      ),
                    ),
                    Text('#${pesanan.id}', style: gayaSamar(ukuran: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.latarBeranda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.ac_unit,
                        size: 18,
                        color: AppColors.biruAksen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unit terpasang', style: gayaSamar(ukuran: 10)),
                            Text(pesanan.unitAc, style: gayaJudul(ukuran: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Bagian(
            judul: 'Rincian komponen biaya',
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.latarBeranda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.biruAksen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Biaya jasa pengecekan awal',
                              style: gayaJudul(ukuran: 13),
                            ),
                            Text(
                              'Layanan dasar standar',
                              style: gayaSamar(ukuran: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            rupiah(pesanan.ongkosAwal),
                            style: gayaJudul(ukuran: 13),
                          ),
                          Text('Otomatis', style: gayaSamar(ukuran: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _baris.length; i++) ...[
                  _FormBaris(
                    nomor: i + 2,
                    baris: _baris[i],
                    tampilkanError: _dicoba,
                    bisaDihapus: _baris.length > 1,
                    onHapus: () => _hapus(_baris[i]),
                    onUbah: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                ],
                if (adaKosongSemua)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Isi minimal satu biaya perbaikan.',
                      style: TextStyle(fontSize: 12, color: AppColors.merah),
                    ),
                  ),
                PopupMenuButton<JenisItemBiaya>(
                  onSelected: _tambah,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: JenisItemBiaya.jasa,
                      child: Text('Jasa perbaikan'),
                    ),
                    PopupMenuItem(
                      value: JenisItemBiaya.sparepart,
                      child: Text('Suku cadang / material'),
                    ),
                  ],
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.biruMuda),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.biruAksen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tambah item tindakan / sparepart lainnya',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.biruAksen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Bagian(
            judul: 'Catatan untuk pelanggan',
            keterangan: 'Terlihat di invoice',
            anak: TextField(
              controller: _catatan,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Jelaskan kerusakan dan tindakan yang diperlukan',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Bagian(
            judul: 'Kalkulasi tagihan & komisi',
            anak: Column(
              children: [
                BarisNilai(
                  'Subtotal cek awal',
                  rupiah(pesanan.ongkosAwal),
                  samar: true,
                ),
                BarisNilai(
                  'Biaya perbaikan & sparepart',
                  rupiah(_biayaPerbaikan),
                  samar: true,
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total tagihan pelanggan',
                        style: gayaJudul(ukuran: 13),
                      ),
                    ),
                    Text(
                      rupiah(_total),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.biruAksen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.hijauMuda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: AppColors.hijau,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimasi komisi masuk dompet',
                              style: gayaSamar(ukuran: 11),
                            ),
                            Text(
                              rupiah(_total - potongan),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.hijau,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Potongan platform\n$komisiPlatformPersen%  (- ${rupiah(potongan)})',
                        textAlign: TextAlign.right,
                        style: gayaSamar(ukuran: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0ECFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.biruAksen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rincian biaya ini akan dikirimkan ke aplikasi pelanggan '
                    'untuk konfirmasi persetujuan sebelum Anda mulai '
                    'melakukan perbaikan.',
                    style: gayaSamar(ukuran: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BilahBawah(
        child: TombolUtama(
          'Kirim rincian biaya & lanjut perbaikan',
          _kirim,
          ikon: Icons.send_outlined,
        ),
      ),
    );
  }
}

class _Bagian extends StatelessWidget {
  const _Bagian({required this.judul, required this.anak, this.keterangan});

  final String judul;
  final String? keterangan;
  final Widget anak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: garisKartu),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(judul, style: gayaJudul())),
              if (keterangan != null)
                Text(keterangan!, style: gayaSamar(ukuran: 11)),
            ],
          ),
          const SizedBox(height: 10),
          anak,
        ],
      ),
    );
  }
}

class _FormBaris extends StatelessWidget {
  const _FormBaris({
    required this.nomor,
    required this.baris,
    required this.tampilkanError,
    required this.bisaDihapus,
    required this.onHapus,
    required this.onUbah,
  });

  final int nomor;
  final _Baris baris;
  final bool tampilkanError;
  final bool bisaDihapus;
  final VoidCallback onHapus;
  final VoidCallback onUbah;

  @override
  Widget build(BuildContext context) {
    final jasa = baris.jenis == JenisItemBiaya.jasa;
    final salahNama =
        tampilkanError && !baris.kosong && baris.nama.text.trim().isEmpty;
    final salahHarga = tampilkanError && !baris.kosong && baris.nominal <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ITEM $nomor: ${jasa ? 'JASA PERBAIKAN' : 'SUKU CADANG / MATERIAL'}',
                style: gayaSamar(ukuran: 11),
              ),
            ),
            if (bisaDihapus)
              InkWell(
                onTap: onHapus,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    'Hapus',
                    style: TextStyle(fontSize: 12, color: AppColors.merah),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: baris.nama,
          onChanged: (_) => onUbah(),
          decoration: InputDecoration(
            hintText: jasa ? 'Nama tindakan' : 'Nama suku cadang',
            errorText: salahNama ? 'Nama wajib diisi' : null,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: baris.harga,
          onChanged: (_) => onUbah(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Nominal',
            prefixText: 'Rp ',
            errorText: salahHarga ? 'Nominal harus lebih dari 0' : null,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
