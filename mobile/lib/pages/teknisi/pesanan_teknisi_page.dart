import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/pesanan_teknisi.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';
import 'pengerjaan_page.dart';
import 'riwayat_layanan_page.dart';

class PesananTeknisiPage extends StatelessWidget {
  const PesananTeknisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TeknisiService.instance;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.latarBeranda,
        appBar: appBarTeknisi(
          'Pesanan',
          tampilkanKembali: false,
          bawah: const TabBar(
            labelColor: AppColors.biruAksen,
            indicatorColor: AppColors.biruAksen,
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            return TabBarView(
              children: [
                _Aktif(pesanan: service.pesananAktif),
                RiwayatLayananTab(daftar: service.riwayat),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Aktif extends StatelessWidget {
  const _Aktif({required this.pesanan});

  final PesananTeknisi? pesanan;

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    if (p == null) {
      return const _Kosong(
        'Belum ada pesanan aktif.\nPesanan yang Anda terima akan muncul di sini.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        KartuTeknisi(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const PengerjaanPage())),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.id, style: gayaSamar(ukuran: 11.5))),
                  ChipStatus(p.tahap.label),
                ],
              ),
              const SizedBox(height: 6),
              Text(p.pelanggan, style: gayaJudul(ukuran: 15)),
              const SizedBox(height: 2),
              Text('${p.layanan}  •  ${p.alamat}', style: gayaSamar()),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lanjutkan pesanan',
                      style: TextStyle(
                        color: AppColors.biruAksen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.biruAksen),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          teks,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

/// Format tanggal pendek untuk daftar transaksi.
String tanggalPendek(DateTime t) =>
    DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(t);
