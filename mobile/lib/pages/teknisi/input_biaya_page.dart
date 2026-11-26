import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/format_ribuan.dart';
import '../../models/layanan.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';

/// Teknisi mengisi rincian biaya perbaikan setelah pengecekan (UC-22).
/// Rincian dikirim ke pelanggan untuk disetujui sebelum perbaikan dimulai.
class InputBiayaPage extends StatefulWidget {
  const InputBiayaPage({super.key});

  @override
  State<InputBiayaPage> createState() => _InputBiayaPageState();
}

class _BarisItem {
  final nama = TextEditingController();
  final harga = TextEditingController();
  JenisItemBiaya jenis;

  _BarisItem(this.jenis);

  int get nilai => angkaDari(harga.text);

  void dispose() {
    nama.dispose();
    harga.dispose();
  }
}

class _InputBiayaPageState extends State<InputBiayaPage> {
  final _formKey = GlobalKey<FormState>();
  final _catatan = TextEditingController();
  final List<_BarisItem> _item = [
    _BarisItem(JenisItemBiaya.jasa),
    _BarisItem(JenisItemBiaya.sukuCadang),
  ];

  PekerjaanTeknisi? get _kerja => TeknisiService.instance.pekerjaan.value;

  @override
  void dispose() {
    _catatan.dispose();
    for (final i in _item) {
      i.dispose();
    }
    super.dispose();
  }

  int get _subtotal => _item.fold(0, (a, i) => a + i.nilai);

  void _tambah() =>
      setState(() => _item.add(_BarisItem(JenisItemBiaya.sukuCadang)));

  void _hapus(int i) {
    setState(() {
      _item[i].dispose();
      _item.removeAt(i);
    });
  }

  bool _mengirim = false;

  Future<void> _kirim() async {
    if (_mengirim) return;
    if (_item.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tambahkan minimal satu item biaya')),
        );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _mengirim = true);
    final galat = await TeknisiService.instance.ajukanBiaya([
      for (final i in _item)
        ItemBiaya(nama: i.nama.text.trim(), jenis: i.jenis, harga: i.nilai),
    ], _catatan.text.trim());
    if (!mounted) return;
    setState(() => _mengirim = false);
    if (galat != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(galat)));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Rincian biaya dikirim, menunggu persetujuan pelanggan',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final kerja = _kerja;
    final ongkosAwal = kerja?.pesanan.ongkosAwal ?? 0;
    final total = ongkosAwal + _subtotal;
    final komisi = TeknisiService.hitungKomisi(total);

    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Input Biaya Perbaikan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (kerja != null)
              _Kartu(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kerja.pesanan.namaPelanggan,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(kerja.pesanan.unitAc, style: _kecil),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rincian Komponen Biaya', style: _judul),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.biruMuda,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Biaya awal (sudah dibayar)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                        ),
                        Text(
                          rupiah(ongkosAwal),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _item.length; i++)
                    _FormItem(
                      key: ObjectKey(_item[i]),
                      nomor: i + 1,
                      item: _item[i],
                      onUbah: () => setState(() {}),
                      onHapus: () => _hapus(i),
                    ),
                  OutlinedButton.icon(
                    onPressed: _tambah,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Tambah Item Tindakan / Suku Cadang'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan untuk Pelanggan', style: _judul),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _catatan,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: perlu las pipa dan tambah freon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Kartu(
              child: Column(
                children: [
                  _Baris('Biaya awal', rupiah(ongkosAwal)),
                  _Baris('Biaya perbaikan', rupiah(_subtotal)),
                  const Divider(),
                  _Baris('Total tagihan pelanggan', rupiah(total), tebal: true),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.hijauMuda,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _Baris(
                      'Estimasi komisi kamu (potongan platform '
                      '${TeknisiService.persentasePlatform}%)',
                      rupiah(komisi),
                      tebal: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rincian dikirim ke pelanggan untuk disetujui sebelum kamu '
              'mulai melakukan perbaikan.',
              style: _kecil,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _kirim,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Kirim Rincian Biaya'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
          ),
        ),
      ),
    );
  }
}

final _kecil = GoogleFonts.plusJakartaSans(
  fontSize: 11,
  color: AppColors.teksSamar,
);
final _judul = GoogleFonts.plusJakartaSans(
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class _FormItem extends StatelessWidget {
  final int nomor;
  final _BarisItem item;
  final VoidCallback onUbah;
  final VoidCallback onHapus;

  const _FormItem({
    super.key,
    required this.nomor,
    required this.item,
    required this.onUbah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.garisLembut),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<JenisItemBiaya>(
                  value: item.jenis,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  items: [
                    for (final j in JenisItemBiaya.values)
                      DropdownMenuItem(
                        value: j,
                        child: Text('Item $nomor: ${j.label}'),
                      ),
                  ],
                  onChanged: (j) {
                    if (j == null) return;
                    item.jenis = j;
                    onUbah();
                  },
                ),
              ),
              TextButton.icon(
                onPressed: onHapus,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(foregroundColor: AppColors.merah),
              ),
            ],
          ),
          TextFormField(
            controller: item.nama,
            decoration: InputDecoration(
              labelText: item.jenis == JenisItemBiaya.jasa
                  ? 'Nama tindakan'
                  : 'Nama suku cadang / material',
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: item.harga,
            keyboardType: TextInputType.number,
            inputFormatters: const [FormatRibuan()],
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              isDense: true,
            ),
            onChanged: (_) => onUbah(),
            validator: (v) {
              final n = angkaDari(v ?? '');
              return n <= 0 ? 'Format biaya tidak valid' : null;
            },
          ),
        ],
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  final String kiri;
  final String kanan;
  final bool tebal;

  const _Baris(this.kiri, this.kanan, {this.tebal = false});

  @override
  Widget build(BuildContext context) {
    final gaya = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(kiri, style: gaya)),
          const SizedBox(width: 8),
          Text(kanan, style: gaya),
        ],
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  final Widget child;

  const _Kartu({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
