import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/teknisi.dart';
import '../../theme/app_colors.dart';

class _Pesan {
  final String teks;
  final bool dariSaya;
  final String jam;

  const _Pesan(this.teks, {required this.dariSaya, required this.jam});
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

  /// Balasan otomatis teknisi (dummy) setelah pesan pelanggan terkirim.
  // TODO(backend): ganti dengan chat realtime dari API.
  static const _balasanTeknisi =
      'Baik, terima kasih atas informasinya. Saya catat dan segera saya tindak '
      'lanjuti ya. Kalau ada yang perlu ditanyakan, silakan disampaikan.';

  // Data dummy, nanti diganti chat realtime dari API.
  static const List<_Pesan> _pesanAwal = [
    _Pesan(
      'Selamat siang, Bapak/Ibu. Saya GanAnWo, teknisi ACare yang akan '
      'menangani servis AC di rumah Anda.',
      dariSaya: false,
      jam: '12.20',
    ),
    _Pesan(
      'Selamat siang, Pak. Baik, terima kasih sudah menghubungi saya.',
      dariSaya: true,
      jam: '12.21',
    ),
    _Pesan(
      'Saya sedang menuju ke lokasi dan perkiraan tiba sekitar 15 menit lagi. '
      'Mohon pastikan akses ke unit AC sudah bisa dibuka ya, Pak.',
      dariSaya: false,
      jam: '12.22',
    ),
    _Pesan(
      'Baik, Pak. Unit AC sudah siap diperiksa. Saya tunggu kedatangannya, '
      'hati-hati di jalan.',
      dariSaya: true,
      jam: '12.23',
    ),
  ];

  late final List<_Pesan> _pesan = List.of(_pesanAwal);

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Jam sekarang dengan format 24 jam, mis. "12.24".
  String get _jamSekarang {
    final sekarang = DateTime.now();
    final jam = sekarang.hour.toString().padLeft(2, '0');
    final menit = sekarang.minute.toString().padLeft(2, '0');
    return '$jam.$menit';
  }

  void _kirim([String? teks]) {
    final isi = (teks ?? _input.text).trim();
    if (isi.isEmpty) return;
    final jam = _jamSekarang;
    setState(() {
      _pesan.add(_Pesan(isi, dariSaya: true, jam: jam));
      _pesan.add(_Pesan(_balasanTeknisi, dariSaya: false, jam: jam));
    });
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _gulirKeBawah());
  }

  void _gulirKeBawah() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.teknisi.nama,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Teknisi ACare â€¢ Online',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE4E6EA)),
                    ),
                    child: Text(
                      'Hari ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: AppColors.teksSamar,
                      ),
                    ),
                  ),
                ),
                for (final pesan in _pesan) _Gelembung(pesan: pesan),
              ],
            ),
          ),
          _KolomInput(controller: _input, onKirim: _kirim),
        ],
      ),
    );
  }
}

/// Kolom tulis pesan + tombol kirim.
class _KolomInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function([String? teks]) onKirim;

  const _KolomInput({required this.controller, required this.onKirim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E6EA))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (teks) => onKirim(teks),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan yang sopan dan jelas...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.teksSamar,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F8FF),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: _garisInput(),
                    enabledBorder: _garisInput(),
                    focusedBorder: _garisInput(color: AppColors.biru),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: ElevatedButton(
                  onPressed: onKirim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.biru,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.send, size: 19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _garisInput({Color color = const Color(0xFFCBD0D8)}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: color),
    );

class _Gelembung extends StatelessWidget {
  final _Pesan pesan;

  const _Gelembung({required this.pesan});

  @override
  Widget build(BuildContext context) {
    final dariSaya = pesan.dariSaya;

    return Align(
      alignment: dariSaya ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
        decoration: BoxDecoration(
          color: dariSaya ? AppColors.biru : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(dariSaya ? 12 : 2),
            bottomRight: Radius.circular(dariSaya ? 2 : 12),
          ),
          border: dariSaya ? null : Border.all(color: const Color(0xFFE4E6EA)),
        ),
        child: Column(
          crossAxisAlignment: dariSaya
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              pesan.teks,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                color: dariSaya ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              pesan.jam,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                color: dariSaya ? Colors.white70 : AppColors.teksSamar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
