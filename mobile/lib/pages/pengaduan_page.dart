import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/pesanan.dart';
import '../services/perangkat.dart';
import '../theme/app_colors.dart';

class PengaduanPage extends StatefulWidget {
  final Pesanan? pesanan;

  const PengaduanPage({super.key, this.pesanan});

  @override
  State<PengaduanPage> createState() => _PengaduanPageState();
}

class _PengaduanPageState extends State<PengaduanPage> {
  static const _maks = 500;
  static const _jenis = [
    'Teknisi Datang Terlambat',
    'Hasil Servis Kurang Dingin',
    'Selisih Tagihan Biaya',
    'Sikap Kurang Sopan',
    'Lainnya',
  ];

  bool _layananTeknisi = true;
  late Pesanan _pesanan = widget.pesanan ?? dummyPesanan.first;
  String? _jenisDipilih;
  final _kronologi = TextEditingController();
  static const _maksBukti = 3;
  static const _maksUkuranByte = 5 * 1024 * 1024;
  final List<_Bukti> _bukti = [];

  @override
  void dispose() {
    _kronologi.dispose();
    super.dispose();
  }

  void _ubahPesanan() async {
    final dipilih = await showModalBottomSheet<Pesanan>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          for (final p in dummyPesanan)
            ListTile(
              title: Text('${p.kode} • ${p.namaLayanan}'),
              subtitle: Text('Teknisi: ${p.namaTeknisi}'),
              onTap: () => Navigator.of(context).pop(p),
            ),
        ],
      ),
    );
    if (dipilih != null) setState(() => _pesanan = dipilih);
  }

  Future<void> _tambahBukti() async {
    if (_bukti.length >= _maksBukti) return;
    try {
      final foto = await Perangkat.ambilFoto();
      if (foto == null) return;
      final data = await foto.readAsBytes();
      if (!mounted) return;
      if (data.length > _maksUkuranByte) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran foto maksimal 5MB')),
        );
        return;
      }
      setState(() {
        final nama = foto.name.isEmpty ? 'foto_bukti' : foto.name;
        _bukti.add(_Bukti(nama, data));
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gagal memilih foto')));
    }
  }

  void _kirim() {
    if (_jenisDipilih == null || _kronologi.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis masalah dan isi kronologi kendala'),
        ),
      );
      return;
    }
    // TODO: kirim laporan ke API Laravel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan terkirim, kami respon < 24 jam')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final judul = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pusat Bantuan & Pengaduan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.help_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kategori Masalah', style: judul),
              Text(
                'Pilih jalur aduan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.teksSamar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _KategoriAduan(
                    ikon: Icons.engineering_outlined,
                    judul: 'Layanan Teknisi',
                    keterangan: 'Pengerjaan bocor, teknisi terlambat, tagihan',
                    dipilih: _layananTeknisi,
                    onTap: () => setState(() => _layananTeknisi = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KategoriAduan(
                    ikon: Icons.smartphone_outlined,
                    judul: 'Sistem & Aplikasi',
                    keterangan: 'Gagal bayar, bug voucher, force close',
                    dipilih: !_layananTeknisi,
                    onTap: () => setState(() => _layananTeknisi = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (_layananTeknisi) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.biruAksen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TERKAIT PESANAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _ubahPesanan,
                  child: Row(
                    children: [
                      Text(
                        'Ubah Pesanan ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.biruAksen,
                        ),
                      ),
                      const Icon(
                        Icons.swap_horiz,
                        size: 14,
                        color: AppColors.biruAksen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _KartuPesananTerkait(pesanan: _pesanan),
            const SizedBox(height: 18),
          ],

          Text('Jenis Masalah Utama', style: judul),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final j in _jenis)
                _ChipJenis(
                  label: j,
                  dipilih: _jenisDipilih == j,
                  onTap: () => setState(() => _jenisDipilih = j),
                ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jelaskan Kronologi Kendala', style: judul),
              Text(
                '${_kronologi.text.length}/$_maks',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColors.teksSamar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _kronologi,
            maxLines: 5,
            maxLength: _maks,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Ceritakan apa yang terjadi...',
              hintStyle: const TextStyle(fontSize: 12),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD5DCEB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD5DCEB)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text.rich(
            TextSpan(
              style: judul,
              children: [
                const TextSpan(text: 'Unggah Bukti Pendukung '),
                TextSpan(
                  text: '(Opsional)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.teksSamar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _SlotBukti(
                    berkas: i < _bukti.length ? _bukti[i] : null,
                    kosong: i > _bukti.length,
                    onTambah: _tambahBukti,
                    onHapus: () => setState(() => _bukti.removeAt(i)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.hijau,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Jaminan Respon < 24 Jam ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.hijauMuda,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SLA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8,
                                color: AppColors.hijau,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tim Acare akan memproses aduanmu, memverifikasi riwayat GPS & rekaman kerja.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _kirim,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Kirim Laporan Pengaduan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biru,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Laporanmu terlindungi dan ditangani secara rahasia oleh Tim Acare.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppColors.teksSamar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KategoriAduan extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String keterangan;
  final bool dipilih;
  final VoidCallback onTap;

  const _KategoriAduan({
    required this.ikon,
    required this.judul,
    required this.keterangan,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dipilih ? const Color(0xFFEFF4FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dipilih ? AppColors.biruAksen : const Color(0xFFE0E3EA),
            width: dipilih ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: dipilih
                    ? const Color(0xFFDDE8FA)
                    : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                ikon,
                size: 18,
                color: dipilih ? AppColors.biruAksen : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              judul,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: dipilih ? AppColors.biruAksen : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              keterangan,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuPesananTerkait extends StatelessWidget {
  final Pesanan pesanan;

  const _KartuPesananTerkait({required this.pesanan});

  @override
  Widget build(BuildContext context) {
    final tanggal = DateFormat(
      'd MMM yyyy • HH:mm',
      'id_ID',
    ).format(pesanan.tanggal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      pesanan.kode,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE8FA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$tanggal WIB',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          color: AppColors.biruAksen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pesanan.namaLayanan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: AppColors.hijau,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Teknisi: ${pesanan.namaTeknisi} (Rating 4.9)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.ac_unit,
              size: 18,
              color: AppColors.biruAksen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipJenis extends StatelessWidget {
  final String label;
  final bool dipilih;
  final VoidCallback onTap;

  const _ChipJenis({
    required this.label,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: dipilih ? AppColors.biruAksen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dipilih ? AppColors.biruAksen : const Color(0xFFD5DCEB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dipilih) ...[
              const Icon(Icons.check_circle, size: 13, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: dipilih ? Colors.white : Colors.black87,
                fontWeight: dipilih ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bukti {
  final String nama;
  final Uint8List data;

  const _Bukti(this.nama, this.data);

  String get ukuranLabel {
    final kb = data.length / 1024;
    return kb < 1024
        ? '${kb.toStringAsFixed(0)} KB'
        : '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

class _SlotBukti extends StatelessWidget {
  final _Bukti? berkas;
  final bool kosong;
  final VoidCallback onTambah;
  final VoidCallback onHapus;

  const _SlotBukti({
    required this.berkas,
    required this.kosong,
    required this.onTambah,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    const tinggi = 86.0;

    if (berkas != null) {
      return Container(
        height: tinggi,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD5DCEB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              berkas!.data,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.image_outlined, color: AppColors.biruAksen),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  '${berkas!.nama}\n${berkas!.ukuranLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: InkWell(
                onTap: onHapus,
                child: const CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.black87,
                  child: Icon(Icons.close, size: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (kosong) {
      return Container(
        height: tinggi,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_outlined,
                size: 18,
                color: Color(0xFFBFC4CC),
              ),
              const SizedBox(height: 4),
              Text(
                'Slot 2 Kosong',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  color: const Color(0xFFBFC4CC),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTambah,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: tinggi,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_a_photo_outlined,
                size: 20,
                color: AppColors.biruAksen,
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih Foto',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.biruAksen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Maks 5MB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppColors.teksSamar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
