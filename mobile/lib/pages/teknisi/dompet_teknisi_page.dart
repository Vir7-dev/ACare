import 'package:flutter/material.dart';

import '../../models/layanan.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';
import 'pencairan_page.dart';
import 'pesanan_teknisi_page.dart' show tanggalPendek;

class DompetTeknisiPage extends StatelessWidget {
  const DompetTeknisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TeknisiService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final transaksi = service.transaksi;
        return Scaffold(
          appBar: appBarTeknisi('Dompet'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              KartuTeknisi(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo', style: gayaSamar(ukuran: 11.5)),
                    const SizedBox(height: 4),
                    Text(
                      rupiah(service.saldo),
                      key: const Key('saldo-dompet'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.biruAksen,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TombolUtama(
                      'Tarik dana',
                      service.saldo < TeknisiService.minimalPencairan
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PencairanPage(),
                              ),
                            ),
                    ),
                    if (service.saldo < TeknisiService.minimalPencairan)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Minimal penarikan '
                          '${rupiah(TeknisiService.minimalPencairan)}.',
                          style: gayaSamar(ukuran: 11),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Riwayat Transaksi', style: gayaJudul()),
              const SizedBox(height: 12),
              if (transaksi.isEmpty)
                KartuTeknisi(
                  child: Text(
                    'Belum ada transaksi.',
                    style: gayaSamar(ukuran: 11.5),
                  ),
                ),
              for (final t in transaksi)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: KartuTeknisi(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.judul),
                      subtitle: Text(tanggalPendek(t.waktu)),
                      trailing: Text(
                        '${t.nominal < 0 ? '-' : '+'} ${rupiah(t.nominal.abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.nominal < 0
                              ? Colors.black87
                              : AppColors.hijau,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
