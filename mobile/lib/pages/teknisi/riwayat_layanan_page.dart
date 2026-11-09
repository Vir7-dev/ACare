import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/pesanan_teknisi.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';
import 'pesanan_teknisi_page.dart' show tanggalPendek;

enum _Saring {
  semua('Semua'),
  dinilai('Sudah dinilai'),
  belum('Belum dinilai');

  final String label;
  const _Saring(this.label);
}

/// Riwayat layanan yang sudah diselesaikan Teknisi beserta rating dari
/// Pelanggan (UC-24).
class RiwayatLayananTab extends StatefulWidget {
  const RiwayatLayananTab({super.key, required this.daftar});

  final List<PesananTeknisi> daftar;

  @override
  State<RiwayatLayananTab> createState() => _RiwayatLayananTabState();
}

class _RiwayatLayananTabState extends State<RiwayatLayananTab> {
  _Saring _saring = _Saring.semua;

  List<PesananTeknisi> get _tampil => switch (_saring) {
    _Saring.semua => widget.daftar,
    _Saring.dinilai =>
      widget.daftar.where((p) => p.ratingDiterima != null).toList(),
    _Saring.belum =>
      widget.daftar.where((p) => p.ratingDiterima == null).toList(),
  };

  double? get _ratingRata {
    final nilai = [
      for (final p in widget.daftar)
        if (p.ratingDiterima != null) p.ratingDiterima!,
    ];
    if (nilai.isEmpty) return null;
    return nilai.reduce((a, b) => a + b) / nilai.length;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.daftar.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.biruMuda,
                child: Icon(
                  Icons.history,
                  size: 30,
                  color: AppColors.biruAksen,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Belum ada riwayat layanan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                'Order yang sudah Anda selesaikan akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final daftar = _tampil;
    final total = widget.daftar.fold(0, (a, p) => a + p.pendapatanBersih);
    final rata = _ratingRata;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KartuTeknisi(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              _Angka('${widget.daftar.length}', 'Order selesai'),
              _Pemisah(),
              _Angka(
                rata == null ? '-' : rata.toStringAsFixed(1),
                'Rating rata-rata',
                ikon: rata == null ? null : Icons.star,
              ),
              _Pemisah(),
              _Angka(rupiah(total), 'Total diterima'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final s in _Saring.values)
              ChoiceChip(
                label: Text(s.label),
                selected: _saring == s,
                onSelected: (_) => setState(() => _saring = s),
                showCheckmark: false,
                selectedColor: AppColors.biruMuda,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _saring == s ? AppColors.biruAksen : Colors.black87,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (daftar.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Tidak ada riwayat yang cocok.',
              textAlign: TextAlign.center,
              style: gayaSamar(ukuran: 13),
            ),
          )
        else
          for (final p in daftar) ...[
            _KartuRiwayat(
              pesanan: p,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailRiwayatPage(pesanan: p)),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka(this.nilai, this.label, {this.ikon});

  final String nilai;
  final String label;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ikon != null) ...[
                Icon(ikon, size: 16, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  nilai,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: gayaSamar(ukuran: 10.5)),
        ],
      ),
    );
  }
}

class _Pemisah extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: garisKartu);
}

/// Bintang rating 1-5.
class BintangRating extends StatelessWidget {
  const BintangRating(this.nilai, {super.key, this.ukuran = 15});

  final int nilai;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= nilai ? Icons.star : Icons.star_border,
            size: ukuran,
            color: const Color(0xFFF59E0B),
          ),
      ],
    );
  }
}

class _KartuRiwayat extends StatelessWidget {
  const _KartuRiwayat({required this.pesanan, required this.onTap});

  final PesananTeknisi pesanan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final waktu = p.selesaiPada;
    return KartuTeknisi(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.id, style: gayaSamar(ukuran: 11))),
              if (waktu != null)
                Text(tanggalPendek(waktu), style: gayaSamar(ukuran: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(p.layanan, style: gayaJudul(ukuran: 14)),
          const SizedBox(height: 2),
          Text('${p.pelanggan}  •  ${p.wilayah}', style: gayaSamar()),
          const SizedBox(height: 10),
          Row(
            children: [
              if (p.ratingDiterima != null)
                BintangRating(p.ratingDiterima!)
              else
                const ChipStatus(
                  'Belum dinilai',
                  warna: Color(0xFF6B7280),
                  latar: Color(0xFFF1F3F5),
                ),
              const Spacer(),
              Text('Diterima', style: gayaSamar(ukuran: 11)),
              const SizedBox(width: 6),
              Text(
                rupiah(p.pendapatanBersih),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.biruAksen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rincian satu layanan yang sudah selesai: pelanggan, biaya, rating, dan
/// catatan pengerjaan.
class DetailRiwayatPage extends StatelessWidget {
  const DetailRiwayatPage({super.key, required this.pesanan});

  final PesananTeknisi pesanan;

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final waktu = p.selesaiPada;
    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      appBar: appBarTeknisi('Detail riwayat'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('#${p.id}', style: gayaSamar())),
                    p.biayaDitolak
                        ? const ChipStatus(
                            'Selesai tanpa perbaikan',
                            warna: Color(0xFFB45309),
                            latar: Color(0xFFFFF4DB),
                          )
                        : const ChipStatus('Selesai'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.layanan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (waktu != null)
                  Text(
                    'Selesai ${tanggalPendek(waktu)}',
                    style: gayaSamar(ukuran: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pelanggan', style: gayaJudul()),
                const SizedBox(height: 8),
                _Info(Icons.person_outline, p.pelanggan),
                _Info(
                  Icons.location_on_outlined,
                  '${p.alamat}, ${p.wilayah}',
                ),
                _Info(Icons.ac_unit, p.unitAc),
                if (p.catatanMasalah.isNotEmpty)
                  _Info(Icons.report_problem_outlined, p.catatanMasalah),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rincian biaya', style: gayaJudul()),
                const SizedBox(height: 8),
                BarisNilai('Biaya pengecekan awal', rupiah(p.ongkosAwal)),
                for (final i in p.itemBiaya)
                  BarisNilai(i.nama, rupiah(i.harga)),
                const Divider(height: 18),
                BarisNilai(
                  'Total tagihan',
                  rupiah(p.totalTagihan),
                  tebal: true,
                ),
                BarisNilai(
                  'Potongan platform ($komisiPlatformPersen%)',
                  '- ${rupiah(p.potonganPlatform)}',
                  samar: true,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.hijauMuda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pendapatan diterima',
                          style: gayaJudul(ukuran: 13),
                        ),
                      ),
                      Text(
                        rupiah(p.pendapatanBersih),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.hijau,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rating dari Pelanggan', style: gayaJudul()),
                const SizedBox(height: 8),
                if (p.ratingDiterima == null)
                  Text(
                    'Pelanggan belum memberi penilaian.',
                    style: gayaSamar(ukuran: 12.5),
                  )
                else ...[
                  Row(
                    children: [
                      BintangRating(p.ratingDiterima!, ukuran: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${p.ratingDiterima}/5',
                        style: gayaJudul(ukuran: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.ulasanDiterima.isEmpty
                        ? 'Pelanggan tidak menulis ulasan.'
                        : '"${p.ulasanDiterima}"',
                    style: gayaSamar(ukuran: 12.5),
                  ),
                ],
              ],
            ),
          ),
          if (p.ringkasanPekerjaan.isNotEmpty) ...[
            const SizedBox(height: 12),
            KartuTeknisi(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan pengerjaan', style: gayaJudul()),
                  const SizedBox(height: 8),
                  Text(p.ringkasanPekerjaan, style: gayaSamar(ukuran: 12.5)),
                  if (p.jumlahFotoBukti > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < p.jumlahFotoBukti; i++)
                          Container(
                            width: 56,
                            height: 56,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.latarBeranda,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.biruMuda),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.biruAksen,
                            ),
                          ),
                        Text(
                          '${p.jumlahFotoBukti} foto bukti',
                          style: gayaSamar(ukuran: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.ikon, this.teks);

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(teks, style: gayaSamar(ukuran: 12.5))),
        ],
      ),
    );
  }
}
