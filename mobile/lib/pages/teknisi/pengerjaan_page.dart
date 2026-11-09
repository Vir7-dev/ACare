import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/layanan.dart';
import '../../models/pesanan_teknisi.dart';
import '../../services/perangkat.dart';
import '../../services/teknisi_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/teknisi_ui.dart';
import 'input_biaya_page.dart';
import 'upload_bukti_page.dart';

/// Layar utama saat teknisi mengerjakan satu pesanan: peta titik pelanggan,
/// tahap pengerjaan, info pelanggan, dan satu tombol aksi sesuai tahap.
class PengerjaanPage extends StatelessWidget {
  const PengerjaanPage({super.key});

  static const _lokasiPelanggan = LatLng(1.0455, 103.9790);

  @override
  Widget build(BuildContext context) {
    final service = TeknisiService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final p = service.pesananAktif;
        if (p == null) return const Scaffold();
        return Scaffold(
          backgroundColor: AppColors.latarBeranda,
          appBar: appBarTeknisi('Pengerjaan servis'),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _PetaTitik(pesanan: p),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BarisTiket(pesanan: p),
                    const SizedBox(height: 12),
                    _KartuTahap(pesanan: p),
                    const SizedBox(height: 12),
                    _KartuPelanggan(pesanan: p),
                    if (p.tahap == TahapKerja.diagnosis) ...[
                      const SizedBox(height: 12),
                      const _KartuFotoPemeriksaan(),
                    ],
                    if (p.itemBiaya.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _KartuBiaya(pesanan: p),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: p.tahap == TahapKerja.selesai
              ? null
              : BilahBawah(child: _aksi(context, service, p)),
        );
      },
    );
  }

  Widget _aksi(BuildContext context, TeknisiService service, PesananTeknisi p) {
    switch (p.tahap) {
      case TahapKerja.menujuLokasi:
        return TombolUtama('Saya sudah tiba', service.majukanTahap);
      case TahapKerja.tiba:
        return TombolUtama('Mulai diagnosis', service.majukanTahap);
      case TahapKerja.diagnosis:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Biaya cek standar', style: gayaSamar(ukuran: 13)),
                ),
                Text(
                  rupiah(p.ongkosAwal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.biruAksen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TombolUtama('Selesai cek & input estimasi biaya', () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InputBiayaPage()),
              );
            }, ikon: Icons.arrow_forward),
          ],
        );
      case TahapKerja.menungguPersetujuan:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rincian biaya sudah dikirim. Pengerjaan dimulai setelah '
              'pelanggan menyetujui.',
              textAlign: TextAlign.center,
              style: gayaSamar(),
            ),
            const SizedBox(height: 8),
            // TODO(backend): persetujuan datang dari aplikasi pelanggan.
            TombolSekunder(
              'Pelanggan menyetujui (simulasi)',
              service.biayaDisetujui,
            ),
          ],
        );
      case TahapKerja.pengerjaan:
        return TombolUtama('Unggah bukti kerja', () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const UploadBuktiPage()));
        });
      case TahapKerja.selesai:
        return const SizedBox.shrink();
    }
  }
}

/// Peta titik pelanggan dengan status di kiri atas dan kartu alamat + Rute.
class _PetaTitik extends StatelessWidget {
  const _PetaTitik({required this.pesanan});

  final PesananTeknisi pesanan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: PengerjaanPage._lokasiPelanggan,
                initialZoom: 15,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.acare_mobile',
                ),
                const MarkerLayer(
                  markers: [
                    Marker(
                      point: PengerjaanPage._lokasiPelanggan,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        size: 38,
                        color: AppColors.merah,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.hijau),
                  const SizedBox(width: 6),
                  Text(
                    pesanan.tahap.label,
                    style: gayaJudul(ukuran: 12),
                    key: const Key('status-tahap'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                tooltip: 'Pusatkan peta',
                onPressed: () {},
                icon: const Icon(Icons.my_location, size: 20),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.biruAksen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Titik pelanggan', style: gayaSamar(ukuran: 10)),
                          Text(
                            '${pesanan.alamat}, ${pesanan.wilayah}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: gayaJudul(ukuran: 13),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      // TODO(backend): buka navigasi ke titik pelanggan.
                      onPressed: () {},
                      icon: const Icon(Icons.turn_right, size: 16),
                      label: const Text('Rute'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.biruAksen,
                        side: const BorderSide(color: AppColors.biruMuda),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisTiket extends StatelessWidget {
  const _BarisTiket({required this.pesanan});

  final PesananTeknisi pesanan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor tiket servis', style: gayaSamar(ukuran: 11)),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '#${pesanan.id}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin nomor tiket',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: pesanan.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nomor tiket disalin.')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined, size: 17),
                  ),
                ],
              ),
            ],
          ),
        ),
        const ChipStatus(
          'Layanan Cek AC',
          warna: AppColors.biruAksen,
          latar: Color(0xFFE0ECFF),
        ),
      ],
    );
  }
}

class _KartuTahap extends StatelessWidget {
  const _KartuTahap({required this.pesanan});

  final PesananTeknisi pesanan;

  static const _nama = ['Menuju', 'Tiba', 'Pengecekan', 'Perbaikan', 'Selesai'];
  static const _ikon = [
    Icons.two_wheeler,
    Icons.location_on_outlined,
    Icons.search,
    Icons.build_outlined,
    Icons.check_circle_outline,
  ];
  static const _tahap = [
    TahapKerja.menujuLokasi,
    TahapKerja.tiba,
    TahapKerja.diagnosis,
    TahapKerja.pengerjaan,
    TahapKerja.selesai,
  ];

  int get _aktif => switch (pesanan.tahap) {
    TahapKerja.menujuLokasi => 0,
    TahapKerja.tiba => 1,
    TahapKerja.diagnosis => 2,
    TahapKerja.menungguPersetujuan => 2,
    TahapKerja.pengerjaan => 3,
    TahapKerja.selesai => 4,
  };

  @override
  Widget build(BuildContext context) {
    final aktif = _aktif;
    final jam = DateFormat('HH.mm');
    return KartuTeknisi(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Status pelaksanaan kerja',
                    style: gayaJudul(ukuran: 13),
                  ),
                ),
                ChipStatus(
                  'Tahap ${aktif + 1} dari 5',
                  warna: AppColors.biruAksen,
                  latar: const Color(0xFFE0ECFF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: _Langkah(
                    nama: _nama[i],
                    ikon: _ikon[i],
                    selesai: i < aktif,
                    aktif: i == aktif,
                    pertama: i == 0,
                    terakhir: i == 4,
                    keterangan: pesanan.waktuTahap[_tahap[i]] == null
                        ? 'Menunggu'
                        : jam.format(pesanan.waktuTahap[_tahap[i]]!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({
    required this.nama,
    required this.ikon,
    required this.selesai,
    required this.aktif,
    required this.pertama,
    required this.terakhir,
    required this.keterangan,
  });

  final String nama;
  final IconData ikon;
  final bool selesai;
  final bool aktif;
  final bool pertama;
  final bool terakhir;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final nyala = selesai || aktif;
    final garisKiri = nyala ? AppColors.biruAksen : const Color(0xFFD1D5DB);
    final garisKanan = selesai ? AppColors.biruAksen : const Color(0xFFD1D5DB);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 2,
                color: pertama ? Colors.transparent : garisKiri,
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: nyala ? AppColors.biruAksen : const Color(0xFFE5E7EB),
              ),
              child: Icon(
                selesai ? Icons.check : ikon,
                size: 16,
                color: nyala ? Colors.white : Colors.black38,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: terakhir ? Colors.transparent : garisKanan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          nama,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
            color: aktif ? AppColors.biruAksen : Colors.black87,
          ),
        ),
        Text(keterangan, style: gayaSamar(ukuran: 9)),
      ],
    );
  }
}

class _KartuPelanggan extends StatelessWidget {
  const _KartuPelanggan({required this.pesanan});

  final PesananTeknisi pesanan;

  @override
  Widget build(BuildContext context) {
    return KartuTeknisi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.biruMuda,
                child: Icon(Icons.person, color: AppColors.biruAksen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.pelanggan,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${pesanan.ratingPelanggan}  •  Pelanggan terverifikasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: gayaSamar(ukuran: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Telepon pelanggan',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.hijau,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => teleponKe(context, pesanan.telepon),
                icon: const Icon(Icons.call, size: 20),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: 'Chat pelanggan',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFE0ECFF),
                  foregroundColor: AppColors.biruAksen,
                ),
                // TODO(backend): layar chat dengan pelanggan.
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Unit AC', style: gayaSamar(ukuran: 11)),
          Text(pesanan.unitAc, style: gayaJudul(ukuran: 13)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keluhan utama pelanggan',
                        style: gayaJudul(ukuran: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '"${pesanan.catatanMasalah}"',
                        style: gayaSamar(ukuran: 12),
                      ),
                    ],
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

/// Foto bukti pemeriksaan di tahap diagnosis. Tampilan saja; belum ada
/// pengambilan foto.
class _KartuFotoPemeriksaan extends StatelessWidget {
  const _KartuFotoPemeriksaan();

  @override
  Widget build(BuildContext context) {
    return KartuTeknisi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto bukti pemeriksaan AC',
                      style: gayaJudul(ukuran: 13),
                    ),
                    Text(
                      'Dokumentasikan kondisi unit sebelum perbaikan',
                      style: gayaSamar(ukuran: 11),
                    ),
                  ],
                ),
              ),
              const ChipStatus(
                '0/3 diunggah',
                warna: AppColors.biruAksen,
                latar: Color(0xFFE0ECFF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _SlotFoto('Ambil foto 1', 'Evaporator')),
              SizedBox(width: 8),
              Expanded(child: _SlotFoto('Ambil foto 2', 'Tekanan freon')),
              SizedBox(width: 8),
              Expanded(child: _SlotFoto('Foto tambahan', 'Opsional')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotFoto extends StatelessWidget {
  const _SlotFoto(this.judul, this.keterangan);

  final String judul;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.latarBeranda,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.biruMuda),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_camera_outlined,
            size: 22,
            color: AppColors.biruAksen,
          ),
          const SizedBox(height: 6),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.biruAksen,
            ),
          ),
          Text(keterangan, style: gayaSamar(ukuran: 9)),
        ],
      ),
    );
  }
}

class _KartuBiaya extends StatelessWidget {
  const _KartuBiaya({required this.pesanan});

  final PesananTeknisi pesanan;

  @override
  Widget build(BuildContext context) {
    return KartuTeknisi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian biaya terkirim', style: gayaJudul()),
          const SizedBox(height: 8),
          BarisNilai('Cek awal', rupiah(pesanan.ongkosAwal)),
          for (final i in pesanan.itemBiaya)
            BarisNilai(i.nama, rupiah(i.harga)),
          const Divider(height: 18),
          BarisNilai('Total tagihan', rupiah(pesanan.totalTagihan), tebal: true),
        ],
      ),
    );
  }
}
