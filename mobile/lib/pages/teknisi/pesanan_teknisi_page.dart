import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import 'pengerjaan_servis_page.dart';

/// Tab pesanan teknisi: pesanan aktif dan riwayat layanan (UC-24).
class PesananTeknisiPage extends StatelessWidget {
  const PesananTeknisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.latar,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
            'Pesanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: const TabBarView(children: [_TabAktif(), _TabRiwayat()]),
      ),
    );
  }
}

class _TabAktif extends StatelessWidget {
  const _TabAktif();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PekerjaanTeknisi?>(
      valueListenable: TeknisiService.instance.pekerjaan,
      builder: (context, kerja, _) {
        if (kerja == null) {
          return Center(
            child: Text(
              'Belum ada pesanan aktif.\nAktifkan status Online di Beranda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.teksSamar,
              ),
            ),
          );
        }
        final p = kerja.pesanan;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                title: Text(
                  '#${p.kode} • ${p.layanan}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${p.namaPelanggan}\n${p.alamat}\nTahap: ${kerja.tahap.label}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PengerjaanServisPage(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _FilterRiwayat { semua, sudahDinilai, belumDinilai }

class _TabRiwayat extends StatefulWidget {
  const _TabRiwayat();

  @override
  State<_TabRiwayat> createState() => _TabRiwayatState();
}

class _TabRiwayatState extends State<_TabRiwayat> {
  _FilterRiwayat _filter = _FilterRiwayat.semua;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RiwayatLayanan>>(
      valueListenable: TeknisiService.instance.riwayat,
      builder: (context, semua, _) {
        final dinilai = semua.where((r) => r.rating != null).toList();
        final rataRating = dinilai.isEmpty
            ? '-'
            : (dinilai.fold(0, (a, r) => a + r.rating!) / dinilai.length)
                  .toStringAsFixed(1);
        final total = semua.fold(0, (a, r) => a + r.diterima);
        final tampil = switch (_filter) {
          _FilterRiwayat.semua => semua,
          _FilterRiwayat.sudahDinilai => dinilai,
          _FilterRiwayat.belumDinilai =>
            semua.where((r) => r.rating == null).toList(),
        };

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _Ringkasan('Order Selesai', '${semua.length}'),
                const SizedBox(width: 8),
                _Ringkasan('Rating', rataRating),
                const SizedBox(width: 8),
                _Ringkasan('Pendapatan', rupiah(total)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final f in _FilterRiwayat.values) ...[
                  if (f != _FilterRiwayat.values.first)
                    const SizedBox(width: 8),
                  Expanded(
                    child: _PilihanFilter(
                      label: switch (f) {
                        _FilterRiwayat.semua => 'Semua',
                        _FilterRiwayat.sudahDinilai => 'Sudah dinilai',
                        _FilterRiwayat.belumDinilai => 'Belum dinilai',
                      },
                      dipilih: _filter == f,
                      onTap: () => setState(() => _filter = f),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (tampil.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'Belum ada riwayat layanan',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.teksSamar,
                    ),
                  ),
                ),
              ),
            for (final r in tampil) _KartuRiwayat(riwayat: r),
          ],
        );
      },
    );
  }
}

class _Ringkasan extends StatelessWidget {
  final String label;
  final String nilai;

  const _Ringkasan(this.label, this.nilai);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              nilai,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.biruTua,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.teksSamar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuRiwayat extends StatelessWidget {
  final RiwayatLayanan riwayat;

  const _KartuRiwayat({required this.riwayat});

  @override
  Widget build(BuildContext context) {
    final r = riwayat;
    final kecil = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      color: AppColors.teksSamar,
    );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${r.kode} • ${r.layanan}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('${r.namaPelanggan} • ${r.wilayah}', style: kecil),
                Text(
                  DateFormat(
                    'd MMM yyyy, HH:mm',
                    'id_ID',
                  ).format(r.selesaiPada),
                  style: kecil,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rupiah(r.diterima),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.hijau,
                ),
              ),
              Text(
                r.rating == null ? 'Belum dinilai' : '★ ${r.rating}',
                style: kecil,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filter riwayat berbentuk pil dengan lebar sama dalam satu baris.
class _PilihanFilter extends StatelessWidget {
  final String label;
  final bool dipilih;
  final VoidCallback onTap;

  const _PilihanFilter({
    required this.label,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dipilih ? AppColors.biru : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: dipilih ? AppColors.biru : AppColors.garis),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dipilih ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
