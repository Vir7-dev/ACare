import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/layanan.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/peta_lokasi.dart';
import 'pengerjaan_servis_page.dart';

/// Beranda teknisi: status ketersediaan, ringkasan hari ini, peta, dan
/// kartu tawaran pesanan masuk (UC-19, UC-20).
class BerandaTeknisiPage extends StatelessWidget {
  const BerandaTeknisiPage({super.key});

  TeknisiService get _layanan => TeknisiService.instance;

  void _ubahOnline(BuildContext context, bool nilai) {
    if (!_layanan.aturOnline(nilai)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Selesaikan pesanan aktif terlebih dahulu'),
          ),
        );
    }
  }

  void _bukaPekerjaan(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PengerjaanServisPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: Stack(
        children: [
          const Positioned.fill(child: PetaLokasi()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _layanan.online,
                    builder: (context, online, _) => _KartuStatus(
                      online: online,
                      onUbah: (v) => _ubahOnline(context, v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<List<RiwayatLayanan>>(
                    valueListenable: _layanan.riwayat,
                    builder: (context, _, _) =>
                        _KartuRingkasan(pendapatan: _layanan.pendapatanHariIni),
                  ),
                  const Spacer(),
                  _BagianBawah(onBukaPekerjaan: () => _bukaPekerjaan(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuStatus extends StatelessWidget {
  final bool online;
  final ValueChanged<bool> onUbah;

  const _KartuStatus({required this.online, required this.onUbah});

  @override
  Widget build(BuildContext context) {
    return _Kartu(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: online ? AppColors.hijauMuda : AppColors.garisLembut,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color: online ? AppColors.hijau : AppColors.teksSamar,
                ),
                const SizedBox(width: 6),
                Text(
                  online ? 'ONLINE' : 'OFFLINE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: online ? AppColors.hijau : AppColors.teksSamar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              online ? 'Siap menerima pesanan' : 'Tidak menerima pesanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.teksSamar,
              ),
            ),
          ),
          Switch(
            value: online,
            onChanged: onUbah,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.hijau,
          ),
        ],
      ),
    );
  }
}

class _KartuRingkasan extends StatelessWidget {
  final int pendapatan;

  const _KartuRingkasan({required this.pendapatan});

  @override
  Widget build(BuildContext context) {
    return _Kartu(
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppColors.biruTua),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendapatan Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.teksSamar,
                  ),
                ),
                Text(
                  rupiah(pendapatan),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.biruTua,
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

/// Kartu di bawah layar: pesanan berjalan, tawaran masuk, menunggu tawaran,
/// atau ajakan untuk online.
class _BagianBawah extends StatelessWidget {
  final VoidCallback onBukaPekerjaan;

  const _BagianBawah({required this.onBukaPekerjaan});

  @override
  Widget build(BuildContext context) {
    final layanan = TeknisiService.instance;
    return ValueListenableBuilder<PekerjaanTeknisi?>(
      valueListenable: layanan.pekerjaan,
      builder: (context, pekerjaan, _) {
        if (pekerjaan != null) {
          return _KartuPekerjaanBerjalan(
            pekerjaan: pekerjaan,
            onTap: onBukaPekerjaan,
          );
        }
        return ValueListenableBuilder<TawaranPesanan?>(
          valueListenable: layanan.tawaran,
          builder: (context, tawaran, _) {
            if (tawaran != null) {
              return KartuTawaran(
                key: ValueKey(tawaran.kode),
                tawaran: tawaran,
                batas: layanan.batasAktif,
                onTerima: () {
                  layanan.terimaTawaran();
                  onBukaPekerjaan();
                },
                onTolak: (sisa) {
                  layanan.tolakTawaran(sisaDetik: sisa);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: const Text('Tawaran ditolak'),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Batalkan',
                          onPressed: layanan.batalkanTolak,
                        ),
                      ),
                    );
                },
                onLewat: () {
                  layanan.tolakTawaran();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Waktu habis, tawaran diteruskan ke teknisi lain',
                        ),
                      ),
                    );
                },
              );
            }
            return ValueListenableBuilder<bool>(
              valueListenable: layanan.online,
              builder: (context, online, _) => _Kartu(
                child: Row(
                  children: [
                    Icon(
                      online
                          ? Icons.check_circle_outline
                          : Icons.power_settings_new,
                      color: online ? AppColors.hijau : AppColors.teksSamar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        online
                            ? 'Kamu sedang online. Pesanan baru akan muncul '
                                  'di sini.'
                            : 'Kamu sedang offline. Aktifkan status untuk '
                                  'menerima pesanan.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _KartuPekerjaanBerjalan extends StatelessWidget {
  final PekerjaanTeknisi pekerjaan;
  final VoidCallback onTap;

  const _KartuPekerjaanBerjalan({required this.pekerjaan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pekerjaan.pesanan;
    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesanan Berjalan • ${pekerjaan.tahap.label}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.hijau,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${p.layanan} • ${p.namaPelanggan}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            p.alamat,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.teksSamar,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
              child: const Text('Lanjutkan Pengerjaan'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu tawaran pesanan dengan hitung mundur. Bila waktu habis, [onLewat]
/// dipanggil dan tawaran diteruskan ke teknisi lain.
class KartuTawaran extends StatefulWidget {
  final TawaranPesanan tawaran;
  final Duration batas;
  final VoidCallback onTerima;

  /// Dipanggil dengan sisa waktu (detik) agar tawaran bisa dipulihkan.
  final ValueChanged<int> onTolak;
  final VoidCallback onLewat;

  const KartuTawaran({
    super.key,
    required this.tawaran,
    required this.batas,
    required this.onTerima,
    required this.onTolak,
    required this.onLewat,
  });

  @override
  State<KartuTawaran> createState() => _KartuTawaranState();
}

class _KartuTawaranState extends State<KartuTawaran> {
  late int _sisa = widget.batas.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_sisa <= 1) {
        t.cancel();
        widget.onLewat();
        return;
      }
      setState(() => _sisa--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tawaran;
    final kecil = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      color: AppColors.teksSamar,
    );

    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.merah),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pesanan Masuk!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.kuningMuda,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_sisa}s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kuning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.biruMuda,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.layanan,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Ongkos Awal', style: kecil),
                        Text(
                          rupiah(t.ongkosAwal),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.biruTua,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(t.unitAc, style: kecil),
                if (t.bisaBiayaTambahan) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Bisa tambah biaya perbaikan setelah pengecekan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.hijau,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.namaPelanggan,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t.alamat}\n${t.jarakKm} km • ${t.menitTempuh} mnt',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                ),
              ),
            ],
          ),
          if (t.catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.kuningMuda,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: "${t.catatan}"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.kuning,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onTolak(_sisa),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.merah,
                    side: const BorderSide(color: AppColors.merah),
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Tolak', maxLines: 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: widget.onTerima,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Terima Pesanan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.biru,
                    minimumSize: const Size(0, 46),
                  ),
                ),
              ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
