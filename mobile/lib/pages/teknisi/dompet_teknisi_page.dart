import 'package:flutter/material.dart';

class DompetTeknisiPage extends StatelessWidget {
  const DompetTeknisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo'),
                  SizedBox(height: 4),
                  Text(
                    'Rp 0',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              // TODO: tarik dana ke rekening dari registrasi
            },
            child: const Text('Tarik dana'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Riwayat transaksi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Belum ada transaksi'), // TODO: list transaksi
        ],
      ),
    );
  }
}
