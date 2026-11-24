import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/pesanan.dart';
import '../../theme/app_colors.dart';
import 'pengaduan_page.dart';

class BeriUlasanPage extends StatefulWidget {
  final Pesanan pesanan;

  const BeriUlasanPage({super.key, required this.pesanan});

  @override
  State<BeriUlasanPage> createState() => _BeriUlasanPageState();
}

class _BeriUlasanPageState extends State<BeriUlasanPage> {
  static const _maks = 500;
  static const _label = {
    1: 'Sangat Kecewa',
    2: 'Kurang Puas',
    3: 'Cukup Baik',
    4: 'Puas',
    5: 'Luar Biasa Memuaskan!',
  };
  static const _pilihan = [
    'Pengerjaan Bersih & Rapi',
    'Tepat Waktu',
    'Penjelasan Sangat Jelas',
    'Sopan & Ramah',
    'AC Kembali Dingin Maksimal',
    'Alat Kerja Lengkap',
  ];

  int _nilai = 5;
  final Set<String> _dipilih = {};
  final _ulasan = TextEditingController();

  @override
  void dispose() {
    _ulasan.dispose();
    super.dispose();
  }

  void _kirim() {
    // TODO: kirim ulasan ke API Laravel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih, ulasanmu sudah terkirim')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pesanan;

    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Tutup',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Beri Ulasan Servis',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Bantuan',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PengaduanPage(pesanan: p)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ringkasan pesanan + teknisi
          _Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.biruTua,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.kode,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.biruTua,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.biruMuda,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '• Selesai Hari Ini',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.biruTua,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.garis,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.namaTeknisi,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.biruTua,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.biruMuda,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Teknisi Tersertifikasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.biruTua,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kuningMuda,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.bintang,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '4.9 ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '(120+)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.teksSamar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.biruMuda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.biruMuda,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.ac_unit,
                          size: 18,
                          color: AppColors.biruTua,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.namaLayanan,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              p.detailUnit,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bintang
          _Kartu(
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  'Bagaimana kepuasanmu terhadap\nhasil servis teknisi?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ketuk bintang untuk memberikan nilai pelayanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: 'Beri $i bintang',
                        onPressed: () => setState(() => _nilai = i),
                        iconSize: 38,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: Icon(
                          i <= _nilai ? Icons.star : Icons.star_border,
                          color: AppColors.bintang,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kuningMuda,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.kuningGaris),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt_outlined,
                        size: 14,
                        color: AppColors.kuning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _label[_nilai]!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kuning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Hal yang disukai
          _Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Apa yang paling kamu sukai?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Pilihan ganda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.teksSamar,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _pilihan)
                      _ChipPilihan(
                        label: t,
                        dipilih: _dipilih.contains(t),
                        onTap: () => setState(() {
                          if (!_dipilih.remove(t)) _dipilih.add(t);
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Ulasan teks
          _Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tulis Ulasan & Masukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ulasan,
                  maxLines: 4,
                  maxLength: _maks,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ceritakan pengalamanmu...',
                    hintStyle: const TextStyle(fontSize: 12),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.biruMuda,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.garis),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.garis),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_ulasan.text.length} / $_maks karakter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.teksSamar,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _kirim,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: const Text('Kirim Ulasan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biru,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ulasanmu membantu teknisi kami berkembang & meningkatkan kualitas layanan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.teksSamar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  final Widget child;

  const _Kartu({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.garisLembut),
      ),
      child: child,
    );
  }
}

class _ChipPilihan extends StatelessWidget {
  final String label;
  final bool dipilih;
  final VoidCallback onTap;

  const _ChipPilihan({
    required this.label,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = dipilih ? AppColors.biruTua : Colors.black54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: dipilih ? AppColors.biruMuda : AppColors.latar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dipilih ? AppColors.biruTua : AppColors.garisLembut,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dipilih ? Icons.check_circle : Icons.add,
              size: 13,
              color: warna,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: warna,
                fontWeight: dipilih ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
