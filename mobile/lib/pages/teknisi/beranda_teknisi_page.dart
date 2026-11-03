import 'package:flutter/material.dart';

class BerandaTeknisiPage extends StatefulWidget {
  const BerandaTeknisiPage({super.key});

  @override
  State<BerandaTeknisiPage> createState() => _BerandaTeknisiPageState();
}

class _BerandaTeknisiPageState extends State<BerandaTeknisiPage> {
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Satu toggle saja (gantikan badge ONLINE + tombol Siap Kerja)
          Card(
            child: SwitchListTile(
              title: Text(_online ? 'Online' : 'Offline'),
              subtitle: Text(
                _online ? 'Siap menerima pesanan' : 'Tidak menerima pesanan',
              ),
              value: _online,
              onChanged: (v) => setState(() => _online = v),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: 'Pendapatan hari ini',
                  value: 'Rp 250.000',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InfoCard(label: 'Target order', value: '2 / 5'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text('TODO: peta lokasi teknisi'),
          ),
          const SizedBox(height: 12),
          // TODO: panel pesanan masuk (bottom sheet + timer, Terima/Tolak)
          // TODO: banner "Lanjutkan pesanan" kalau ada pesanan aktif
          // TODO: banner status verifikasi akun
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
