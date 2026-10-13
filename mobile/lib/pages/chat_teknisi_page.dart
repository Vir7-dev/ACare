import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/teknisi.dart';
import '../theme/app_colors.dart';

class _Pesan {
  final String teks;
  final bool dariSaya;

  const _Pesan(this.teks, {required this.dariSaya});
}

class ChatTeknisiPage extends StatefulWidget {
  final Teknisi teknisi;

  const ChatTeknisiPage({super.key, required this.teknisi});

  @override
  State<ChatTeknisiPage> createState() => _ChatTeknisiPageState();
}

class _ChatTeknisiPageState extends State<ChatTeknisiPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  // Data dummy, nanti diganti chat realtime dari API
  final List<_Pesan> _pesan = [
    const _Pesan('Halo Mas', dariSaya: false),
    const _Pesan('Halo dek', dariSaya: true),
    const _Pesan('Udah siap belum', dariSaya: false),
    const _Pesan('jalan jalan dengan', dariSaya: true),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _kirim(String teks) {
    final isi = teks.trim();
    if (isi.isEmpty) return;
    setState(() => _pesan.add(_Pesan(isi, dariSaya: true)));
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.biru,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFD9DDE3),
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              widget.teknisi.nama,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              itemCount: _pesan.length,
              itemBuilder: (_, i) => _Gelembung(pesan: _pesan[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: _kirim,
                decoration: InputDecoration(
                  hintText: 'Tulis Pesan',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.teksSamar,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  suffixIcon: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined, size: 20),
                      SizedBox(width: 10),
                      Icon(Icons.sentiment_satisfied_alt_outlined, size: 20),
                      SizedBox(width: 12),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD0D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD0D8)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gelembung extends StatelessWidget {
  final _Pesan pesan;

  const _Gelembung({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: pesan.dariSaya ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E6EA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          pesan.teks,
          style: GoogleFonts.plusJakartaSans(fontSize: 10.5),
        ),
      ),
    );
  }
}
