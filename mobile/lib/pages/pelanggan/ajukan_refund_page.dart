import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../models/pesanan.dart';
import '../../services/refund_service.dart';
import '../../theme/app_colors.dart';

/// Pelanggan mengajukan pengembalian biaya awal yang tertahan karena
/// pesanan dibatalkan (UC-17). Dana ditransfer manual oleh Admin ke
/// rekening bank atau e-wallet, bukan ke saldo aplikasi.
class AjukanRefundPage extends StatefulWidget {
  final Pesanan pesanan;

  const AjukanRefundPage({super.key, required this.pesanan});

  @override
  State<AjukanRefundPage> createState() => _AjukanRefundPageState();
}

class _AjukanRefundPageState extends State<AjukanRefundPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomor = TextEditingController();
  final _atasNama = TextEditingController();
  TujuanRefund _tujuan = TujuanRefund.rekening;
  String? _bank;

  List<String> get _pilihan => _tujuan == TujuanRefund.rekening
      ? RefundService.daftarBank
      : RefundService.daftarEWallet;

  @override
  void dispose() {
    _nomor.dispose();
    _atasNama.dispose();
    super.dispose();
  }

  void _kirim() {
    if (!_formKey.currentState!.validate()) return;
    final galat = RefundService.instance.ajukan(
      PengajuanRefund(
        kodePesanan: widget.pesanan.kode,
        nominal: widget.pesanan.totalBiaya,
        tujuan: _tujuan,
        namaBank: _bank!,
        nomor: _nomor.text.trim(),
        atasNama: _atasNama.text.trim(),
        diajukanPada: DateTime.now(),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(galat ?? 'Pengajuan refund berhasil dikirim')),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pesanan;
    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Ajukan Refund',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.kode} • ${p.namaLayanan}', style: _kecil),
                  const SizedBox(height: 6),
                  Text('Dana yang dikembalikan', style: _kecil),
                  Text(
                    rupiah(p.totalBiaya),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.biruTua,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Alasan: ${p.alasanBatal ?? '-'}', style: _kecil),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tujuan Refund', style: _judul),
                  const SizedBox(height: 8),
                  SegmentedButton<TujuanRefund>(
                    segments: [
                      for (final t in TujuanRefund.values)
                        ButtonSegment(value: t, label: Text(t.label)),
                    ],
                    selected: {_tujuan},
                    onSelectionChanged: (s) => setState(() {
                      _tujuan = s.first;
                      _bank = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_tujuan),
                    initialValue: _bank,
                    decoration: InputDecoration(
                      labelText: _tujuan == TujuanRefund.rekening
                          ? 'Nama bank'
                          : 'Nama e-wallet',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final b in _pilihan)
                        DropdownMenuItem(value: b, child: Text(b)),
                    ],
                    onChanged: (v) => setState(() => _bank = v),
                    validator: (v) =>
                        v == null ? 'Kolom ini wajib diisi.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomor,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: _tujuan == TujuanRefund.rekening
                          ? 'Nomor rekening'
                          : 'Nomor e-wallet',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _wajib,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _atasNama,
                    decoration: const InputDecoration(
                      labelText: 'Nama pemilik',
                      border: OutlineInputBorder(),
                    ),
                    validator: _wajib,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Refund diproses manual oleh Admin ke tujuan di atas, bukan ke '
              'saldo aplikasi. Kamu akan menerima notifikasi setelah dana '
              'ditransfer.',
              style: _kecil,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _kirim,
            style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
            child: const Text('Kirim Pengajuan'),
          ),
        ),
      ),
    );
  }

  static String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Kolom ini wajib diisi.' : null;
}

final _kecil = GoogleFonts.plusJakartaSans(
  fontSize: 11,
  color: AppColors.teksSamar,
);
final _judul = GoogleFonts.plusJakartaSans(
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

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
