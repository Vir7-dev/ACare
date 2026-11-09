import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/layanan.dart';
import '../../models/pesanan_teknisi.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';

const _daftarBank = [
  ('BCA', 'Bank BCA'),
  ('Mandiri', 'Bank Mandiri'),
  ('BRI', 'Bank BRI'),
  ('BNI', 'Bank BNI'),
  ('BSI', 'Bank Syariah'),
  ('CIMB', 'CIMB Niaga'),
];

const _daftarEWallet = [
  ('GoPay', 'GoPay'),
  ('OVO', 'OVO'),
  ('DANA', 'DANA'),
  ('ShopeePay', 'ShopeePay'),
];

const _biruSoft = Color(0xFFE0ECFF);

String _akhirNomor(RekeningTujuan r) =>
    r.nomor.length <= 4 ? r.nomor : r.nomor.substring(r.nomor.length - 4);

String _waktuWib(DateTime t) =>
    '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(t)} WIB';

/// Mengisi nominal dan memilih rekening tujuan untuk menarik saldo.
class PencairanPage extends StatefulWidget {
  const PencairanPage({super.key});

  @override
  State<PencairanPage> createState() => _PencairanPageState();
}

class _PencairanPageState extends State<PencairanPage> {
  final _service = TeknisiService.instance;
  final _nominal = TextEditingController();
  RekeningTujuan? _dipilih;
  bool _dicoba = false;

  @override
  void initState() {
    super.initState();
    final daftar = _service.rekening;
    if (daftar.isNotEmpty) {
      _dipilih = daftar.firstWhere((r) => r.utama, orElse: () => daftar.first);
    }
  }

  @override
  void dispose() {
    _nominal.dispose();
    super.dispose();
  }

  int get _jumlah => int.tryParse(_nominal.text) ?? 0;

  String? get _pesanError {
    if (!_dicoba) return null;
    if (_jumlah < TeknisiService.minimalPencairan) {
      return 'Minimal ${rupiah(TeknisiService.minimalPencairan)}';
    }
    if (_jumlah > _service.saldo) return 'Melebihi saldo yang tersedia';
    if (_jumlah > TeknisiService.batasHarianPencairan) {
      return 'Melebihi batas harian';
    }
    return null;
  }

  void _isi(int nilai) => setState(() => _nominal.text = '$nilai');

  Future<void> _tambahRekening() async {
    final baru = await showModalBottomSheet<RekeningTujuan>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const FormRekeningSheet(),
    );
    if (baru == null) return;
    _service.tambahRekening(baru);
    setState(() => _dipilih = baru);
  }

  Future<void> _ajukan() async {
    setState(() => _dicoba = true);
    final tujuan = _dipilih;
    if (_pesanError != null || tujuan == null) return;
    final lolos = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SheetPin(nominal: _jumlah, rekening: tujuan),
    );
    if (lolos != true || !mounted) return;
    final bukti = _service.cairkan(_jumlah, tujuan);
    if (bukti == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BuktiPencairanPage(bukti: bukti)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saldo = _service.saldo;
    final rekening = _service.rekening;

    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      appBar: appBarTeknisi('Pencairan saldo'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KartuSaldo(service: _service),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Nominal penarikan', style: gayaJudul()),
                    ),
                    Text(
                      'Min. ${rupiah(TeknisiService.minimalPencairan)}',
                      style: gayaSamar(ukuran: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nominal,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ketik nominal',
                    prefixText: 'Rp ',
                    hintText: '0',
                    errorText: _pesanError,
                    filled: true,
                    fillColor: AppColors.latarBeranda,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final n in [100000, 250000, 500000]) ...[
                      Expanded(
                        child: _ChipNominal(
                          label: '${n ~/ 1000} Rb',
                          aktif: _jumlah == n,
                          aktifkan: n <= saldo,
                          onTap: () => _isi(n),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _ChipNominal(
                        label: 'Semua',
                        aktif: _jumlah == saldo && saldo > 0,
                        aktifkan: saldo > 0,
                        onTap: () => _isi(saldo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Batas harian penarikan',
                        style: gayaSamar(ukuran: 11),
                      ),
                    ),
                    Text(
                      '${rupiah(TeknisiService.batasHarianPencairan)} / hari',
                      style: gayaJudul(ukuran: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Rekening tujuan', style: gayaJudul()),
                    ),
                    const ChipStatus('Tersimpan'),
                  ],
                ),
                const SizedBox(height: 10),
                for (final r in rekening) ...[
                  _BarisRekening(
                    rekening: r,
                    dipilih: identical(r, _dipilih),
                    onTap: () => setState(() => _dipilih = r),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_dicoba && _dipilih == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Pilih rekening tujuan.',
                      style: TextStyle(fontSize: 12, color: AppColors.merah),
                    ),
                  ),
                InkWell(
                  onTap: _tambahRekening,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _biruSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.biruAksen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tambah rekening',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.biruAksen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rincian pencairan', style: gayaJudul()),
                const SizedBox(height: 8),
                BarisNilai('Jumlah ditarik', rupiah(_jumlah), tebal: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.latarBeranda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total diterima', style: gayaJudul()),
                            Text(
                              _dipilih == null
                                  ? 'Pilih rekening tujuan'
                                  : 'Langsung ke ${_dipilih!.bank}',
                              style: gayaSamar(ukuran: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        rupiah(_jumlah),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.biruAksen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _biruSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.biruAksen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pencairan saldo hasil pekerjaan servis AC Anda '
                    'diverifikasi dan diamankan langsung oleh sistem ACare. '
                    'Pastikan nomor rekening dan nama penerima sudah sesuai.',
                    style: gayaSamar(ukuran: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BilahBawah(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TombolUtama(
              'Ajukan pencairan',
              _ajukan,
              ikon: Icons.check_circle_outline,
              warna: AppColors.hijau,
            ),
            TextButton.icon(
              // TODO(backend): halaman riwayat pencairan.
              onPressed: () {},
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Lihat riwayat pencairan'),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuSaldo extends StatelessWidget {
  const _KartuSaldo({required this.service});

  final TeknisiService service;

  @override
  Widget build(BuildContext context) {
    final putih = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      color: Colors.white70,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.biru,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text('Saldo dompet mitra', style: putih)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ID mitra: ${TeknisiService.idMitra}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Saldo siap ditarik', style: putih),
          Text(
            rupiah(service.saldo),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock_outlined, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tertahan (order berjalan)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        rupiah(service.saldoTertahan),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${service.jumlahOrderTertahan} order',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipNominal extends StatelessWidget {
  const _ChipNominal({
    required this.label,
    required this.aktif,
    required this.aktifkan,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final bool aktifkan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aktifkan ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? AppColors.biru : _biruSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: aktif
                ? Colors.white
                : aktifkan
                ? AppColors.biruAksen
                : Colors.black26,
          ),
        ),
      ),
    );
  }
}

class _LogoBank extends StatelessWidget {
  const _LogoBank(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: garisKartu),
      ),
      child: Text(
        teks.length > 5 ? teks.substring(0, 4) : teks,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.biruAksen,
        ),
      ),
    );
  }
}

class _BarisRekening extends StatelessWidget {
  const _BarisRekening({
    required this.rekening,
    required this.dipilih,
    required this.onTap,
  });

  final RekeningTujuan rekening;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = rekening;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.latarBeranda,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dipilih ? AppColors.biru : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            _LogoBank(r.bank),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.eWallet ? r.bank : 'Bank ${r.bank}',
                          style: gayaJudul(ukuran: 13),
                        ),
                      ),
                      if (r.utama) ...[
                        const SizedBox(width: 6),
                        const ChipStatus(
                          'UTAMA',
                          warna: AppColors.biruAksen,
                          latar: _biruSoft,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '••••  ${_akhirNomor(r)}  •  a.n ${r.atasNama}',
                    style: gayaSamar(ukuran: 11),
                  ),
                ],
              ),
            ),
            Icon(
              dipilih ? Icons.check_circle : Icons.radio_button_unchecked,
              color: dipilih ? AppColors.biru : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet konfirmasi PIN 6 digit sebelum dana dicairkan. Mengembalikan
/// true bila dikonfirmasi.
///
/// TODO(backend): verifikasi PIN ke server. Sekarang semua PIN 6 digit lolos.
class SheetPin extends StatefulWidget {
  const SheetPin({super.key, required this.nominal, required this.rekening});

  final int nominal;
  final RekeningTujuan rekening;

  @override
  State<SheetPin> createState() => _SheetPinState();
}

class _SheetPinState extends State<SheetPin> {
  String _pin = '';

  void _tekan(String d) {
    if (_pin.length < 6) setState(() => _pin += d);
  }

  void _hapus() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rekening;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Konfirmasi PIN keamanan',
                    style: gayaJudul(ukuran: 17),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            Text(
              'Masukkan 6 digit PIN keamanan Mitra ACare untuk memproses '
              'transaksi penarikan saldo.',
              style: gayaSamar(ukuran: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.latarBeranda,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.biruMuda),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Total diterima', style: gayaSamar()),
                      ),
                      Text(
                        rupiah(widget.nominal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.biruAksen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Rekening tujuan', style: gayaSamar()),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${r.bank} ••••  ${_akhirNomor(r)}  a.n ${r.atasNama}',
                          textAlign: TextAlign.right,
                          style: gayaJudul(ukuran: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 6; i++)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _biruSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 12,
                      color: i < _pin.length
                          ? AppColors.biruAksen
                          : Colors.black12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (final baris in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (final d in baris) ...[
                      Expanded(child: _Tombol(d, () => _tekan(d))),
                      if (d != baris.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            Row(
              children: [
                const Expanded(
                  child: Icon(Icons.lock_outline, size: 20, color: Colors.black45),
                ),
                const SizedBox(width: 8),
                Expanded(child: _Tombol('0', () => _tekan('0'))),
                const SizedBox(width: 8),
                Expanded(
                  child: _Tombol(
                    null,
                    _hapus,
                    ikon: Icons.backspace_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TombolUtama(
              'Konfirmasi & cairkan sekarang',
              _pin.length == 6 ? () => Navigator.of(context).pop(true) : null,
              ikon: Icons.arrow_forward,
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tombol extends StatelessWidget {
  const _Tombol(this.teks, this.onTap, {this.ikon});

  final String? teks;
  final IconData? ikon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _biruSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ikon != null
            ? Icon(ikon, size: 20)
            : Text(
                teks!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Bottom sheet tambah rekening tujuan (bank atau e-wallet).
class FormRekeningSheet extends StatefulWidget {
  const FormRekeningSheet({super.key});

  @override
  State<FormRekeningSheet> createState() => _FormRekeningSheetState();
}

class _FormRekeningSheetState extends State<FormRekeningSheet> {
  final _kunci = GlobalKey<FormState>();
  final _nomor = TextEditingController();
  final _nama = TextEditingController();
  bool _eWallet = false;
  String _pilihan = _daftarBank.first.$1;
  bool _simpan = true;

  @override
  void dispose() {
    _nomor.dispose();
    _nama.dispose();
    super.dispose();
  }

  void _ganti(bool eWallet) {
    setState(() {
      _eWallet = eWallet;
      _pilihan = (eWallet ? _daftarEWallet : _daftarBank).first.$1;
    });
  }

  void _simpanRekening() {
    if (!_kunci.currentState!.validate()) return;
    Navigator.of(context).pop(
      RekeningTujuan(
        bank: _pilihan,
        nomor: _nomor.text.trim(),
        atasNama: _nama.text.trim(),
        eWallet: _eWallet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daftar = _eWallet ? _daftarEWallet : _daftarBank;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _kunci,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tambah rekening tujuan',
                    style: gayaJudul(ukuran: 17),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Jenis akun', style: gayaJudul(ukuran: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.latarBeranda,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Segmen(
                      'Bank transfer',
                      Icons.account_balance_outlined,
                      !_eWallet,
                      () => _ganti(false),
                    ),
                  ),
                  Expanded(
                    child: _Segmen(
                      'E-wallet',
                      Icons.account_balance_wallet_outlined,
                      _eWallet,
                      () => _ganti(true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _eWallet ? 'Pilih e-wallet tujuan' : 'Pilih bank tujuan',
              style: gayaJudul(ukuran: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (kode, nama) in daftar)
                  InkWell(
                    onTap: () => setState(() => _pilihan = kode),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 78,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: kode == _pilihan ? _biruSoft : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: kode == _pilihan
                              ? AppColors.biru
                              : garisKartu,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            kode,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.biruAksen,
                            ),
                          ),
                          Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: gayaSamar(ukuran: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _eWallet ? 'Nomor e-wallet' : 'Nomor rekening bank',
              style: gayaJudul(ukuran: 12),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomor,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nomor',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Nomor tidak valid'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    // TODO(backend): cek nama pemilik ke penyedia rekening.
                    onPressed: () {},
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Cek nama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biru,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nama,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama pemilik',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama pemilik wajib diisi'
                  : null,
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _simpan,
              onChanged: (v) => setState(() => _simpan = v ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Simpan rekening ini untuk pencairan berikutnya',
                style: gayaSamar(ukuran: 12),
              ),
            ),
            const SizedBox(height: 6),
            TombolUtama(
              'Simpan & pilih rekening',
              _simpanRekening,
              ikon: Icons.save_alt,
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmen extends StatelessWidget {
  const _Segmen(this.teks, this.ikon, this.aktif, this.onTap);

  final String teks;
  final IconData ikon;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ikon,
              size: 16,
              color: aktif ? AppColors.biruAksen : Colors.black45,
            ),
            const SizedBox(width: 6),
            Text(
              teks,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: aktif ? AppColors.biruAksen : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BuktiPencairanPage extends StatelessWidget {
  const BuktiPencairanPage({super.key, required this.bukti});

  final BuktiPencairan bukti;

  @override
  Widget build(BuildContext context) {
    final r = bukti.rekening;
    return Scaffold(
      backgroundColor: AppColors.latarBeranda,
      appBar: appBarTeknisi('Bukti pencairan', tampilkanKembali: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.hijau,
              child: Icon(Icons.check, size: 34, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pencairan berhasil!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _waktuWib(bukti.waktu),
            textAlign: TextAlign.center,
            style: gayaSamar(),
          ),
          const SizedBox(height: 16),
          KartuTeknisi(
            child: Column(
              children: [
                Text(
                  'TOTAL DANA DICAIRKAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(bukti.nominal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const ChipStatus('Berhasil masuk rekening'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KartuTeknisi(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: AppColors.biruAksen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Rincian pencairan', style: gayaJudul()),
                    ),
                    const ChipStatus('Selesai'),
                  ],
                ),
                const Divider(height: 22),
                _BarisBukti(
                  'ID transaksi',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          bukti.id,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: bukti.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID transaksi disalin.'),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy_outlined, size: 16),
                      ),
                    ],
                  ),
                ),
                _BarisBukti('Waktu', _teks(_waktuWib(bukti.waktu))),
                _BarisBukti(
                  'Metode pencairan',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChipStatus(
                        r.bank,
                        warna: AppColors.biruAksen,
                        latar: _biruSoft,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _teks(
                          r.eWallet ? r.bank : 'Transfer bank ${r.bank}',
                        ),
                      ),
                    ],
                  ),
                ),
                _BarisBukti('Nomor rekening', _teks('••••  ${_akhirNomor(r)}')),
                _BarisBukti('Nama penerima', _teks('${r.atasNama} (Mitra ACare)')),
                const Divider(height: 22),
                Row(
                  children: [
                    Expanded(child: Text('Total ditransfer', style: gayaJudul())),
                    Text(
                      rupiah(bukti.nominal),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.biruAksen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BilahBawah(
        child: TombolUtama('Selesai', () => Navigator.of(context).pop()),
      ),
    );
  }

  static Widget _teks(String t) => Text(
    t,
    textAlign: TextAlign.right,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _BarisBukti extends StatelessWidget {
  const _BarisBukti(this.label, this.nilai);

  final String label;
  final Widget nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gayaSamar(ukuran: 12))),
          const SizedBox(width: 12),
          Flexible(flex: 2, child: Align(alignment: Alignment.centerRight, child: nilai)),
        ],
      ),
    );
  }
}
