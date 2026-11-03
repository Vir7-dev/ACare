import 'package:flutter/material.dart';

class PesananTeknisiPage extends StatelessWidget {
  const PesananTeknisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // TODO: daftar pesanan aktif -> detail + stepper status
            // (menuju lokasi, tiba, diagnosis, pengerjaan, selesai)
            Center(child: Text('Belum ada pesanan aktif')),
            // TODO: riwayat pesanan selesai/dibatalkan
            Center(child: Text('Belum ada riwayat')),
          ],
        ),
      ),
    );
  }
}
