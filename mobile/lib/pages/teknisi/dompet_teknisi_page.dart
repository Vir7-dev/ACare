import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../widgets/format_ribuan.dart';
import '../../models/layanan.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';

/// Dompet teknisi: saldo, pengajuan pencairan (UC-25), dan riwayatnya.
///
/// Versi sederhana: satu rekening dari data registrasi, tanpa PIN.
/// Pencairan ditransfer manual oleh Admin, jadi hasilnya berupa pengajuan
/// yang menunggu diproses, bukan transfer instan.
class DompetTeknisiPage extends StatefulWidget {
  const DompetTeknisiPage({super.key});

  @override
  State<DompetTeknisiPage> createState() => _DompetTeknisiPageState();
}

class _DompetTeknisiPageState extends State<DompetTeknisiPage> {
  final _nominal = TextEditingController();
  TeknisiService get _layanan => TeknisiService.instance;

  @override
  void dispose() {
    _nominal.dispose();
    super.dispose();
  }

  void _isiCepat(int nilai) => setState(() => _nominal.text = ribuan(nilai));

  Future<void> _ajukan() async {
    final nominal = angkaDari(_nominal.text);
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajukan pencairan?'),
        content: Text(
          '${rupiah(nominal)} akan ditransfer Admin ke\n'
          '${TeknisiService.rekeningTujuan}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ajukan'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;

    final galat = _layanan.ajukanPencairan(nominal);
    if (galat != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(galat)));
      return;
    }
    _nominal.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.schedule, color: AppColors.biruTua, size: 40),
        title: const Text('Pengajuan terkirim'),
        content: Text(
          'Pengajuan pencairan ${rupiah(nominal)} menunggu diproses Admin. '
          'Kamu akan menerima notifikasi setelah dana ditransfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Dompet',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_layanan.riwayat, _layanan.pencairan]),
        builder: (context, _) {
          final saldo = _layanan.saldo;
          final nominal = angkaDari(_nominal.text);
          final valid =
              nominal >= TeknisiService.minimumPencairan && nominal <= saldo;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradienAtas, AppColors.gradienBawah],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Siap Ditarik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      rupiah(saldo),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Nominal Penarikan', style: _judul),
                        ),
                        Text('Min. Rp50.000', style: _kecil),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nominal,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [FormatRibuan()],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final n in const [100000, 250000, 500000]) ...[
                          Expanded(
                            child: _TombolNominal(
                              label: rupiah(n),
                              onTap: () => _isiCepat(n),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: _TombolNominal(
                            label: 'Semua',
                            onTap: saldo > 0 ? () => _isiCepat(saldo) : null,
                          ),
                        ),
                      ],
                    ),
                    if (nominal > saldo)
                      Text(
                        'Nominal melebihi saldo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.merah,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Kartu(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: AppColors.biruTua),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rekening Tujuan', style: _kecil),
                          Text(
                            TeknisiService.rekeningTujuan,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Untuk mengganti rekening, hubungi Pusat Bantuan',
                            style: _kecil,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: valid ? _ajukan : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.biru,
                  ),
                  child: const Text('Ajukan Pencairan'),
                ),
              ),
              const SizedBox(height: 20),
              if (_layanan.pencairan.value.isNotEmpty) ...[
                Text('Riwayat Pencairan', style: _judul),
                for (final p in _layanan.pencairan.value)
                  _BarisRiwayat(
                    judul: 'Pencairan #${p.kode}',
                    sub: DateFormat(
                      'd MMM yyyy, HH:mm',
                      'id_ID',
                    ).format(p.diajukanPada),
                    nilai: '-${rupiah(p.nominal)}',
                    status: p.status,
                    warna: AppColors.merah,
                  ),
                const SizedBox(height: 16),
              ],
              Text('Pendapatan Masuk', style: _judul),
              for (final r in _layanan.riwayat.value)
                _BarisRiwayat(
                  judul: '#${r.kode} • ${r.layanan}',
                  sub: DateFormat(
                    'd MMM yyyy, HH:mm',
                    'id_ID',
                  ).format(r.selesaiPada),
                  nilai: '+${rupiah(r.diterima)}',
                  warna: AppColors.hijau,
                ),
            ],
          );
        },
      ),
    );
  }
}

final _kecil = GoogleFonts.plusJakartaSans(
  fontSize: 11,
  color: AppColors.teksSamar,
);
final _judul = GoogleFonts.plusJakartaSans(
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class _BarisRiwayat extends StatelessWidget {
  final String judul;
  final String sub;
  final String nilai;
  final String? status;
  final Color warna;

  const _BarisRiwayat({
    required this.judul,
    required this.sub,
    required this.nilai,
    required this.warna,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
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
                  judul,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(sub, style: _kecil),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nilai,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: warna,
                ),
              ),
              if (status != null) Text(status!, style: _kecil),
            ],
          ),
        ],
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
      ),
      child: child,
    );
  }
}

/// Tombol isi cepat nominal; lebarnya dibagi rata dalam satu baris.
class _TombolNominal extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _TombolNominal({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.biru,
        side: const BorderSide(color: AppColors.garis),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
