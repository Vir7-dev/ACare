import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

import '../models/pesanan.dart';
import '../widgets/pesanan_card.dart';
import 'pengaduan_page.dart';

class RiwayatPesananPage extends StatefulWidget {
  const RiwayatPesananPage({super.key});

  @override
  State<RiwayatPesananPage> createState() => _RiwayatPesananPageState();
}

class _RiwayatPesananPageState extends State<RiwayatPesananPage> {
  static const _biru = Color(0xFF0B6E99);

  String _filter = 'Semua';
  String _query = '';
  bool _terbaru = true;

  List<Pesanan> get _hasil {
    final q = _query.toLowerCase();
    final list = dummyPesanan.where((p) {
      final cocokFilter =
          _filter == 'Semua' ||
          (_filter == 'Selesai' && p.status == StatusPesanan.selesai) ||
          (_filter == 'Dibatalkan' && p.status == StatusPesanan.dibatalkan);
      final cocokCari =
          q.isEmpty ||
          p.kode.toLowerCase().contains(q) ||
          p.namaTeknisi.toLowerCase().contains(q) ||
          p.namaLayanan.toLowerCase().contains(q);
      return cocokFilter && cocokCari;
    }).toList();

    list.sort(
      (a, b) => _terbaru
          ? b.tanggal.compareTo(a.tanggal)
          : a.tanggal.compareTo(b.tanggal),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PengaduanPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari ID, teknisi, atau layanan...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                hintMaxLines: 1,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter chips
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: ['Semua', 'Selesai', 'Dibatalkan'].map((label) {
                final aktif = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: aktif ? _biru : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: aktif ? _biru : const Color(0xFFD5D9DE),
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: aktif ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Judul section + urutkan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Servis Sebelumnya',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _terbaru = !_terbaru),
                  icon: Icon(
                    _terbaru ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: _biru,
                  ),
                  label: Text(
                    _terbaru ? 'Terbaru' : 'Terlama',
                    style: const TextStyle(
                      color: _biru,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: hasil.isEmpty
                ? const Center(child: Text('Tidak ada pesanan'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: hasil.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => PesananCard(pesanan: hasil[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
