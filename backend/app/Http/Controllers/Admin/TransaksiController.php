<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TransaksiController extends Controller
{
    /**
     * Daftar transaksi contoh (sumber tunggal untuk Beranda dan Kelola Transaksi).
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarTransaksi(): array
    {
        return [
            [
                'id' => 'TRX-2410001',
                'tanggal' => '20 Okt 2026',
                'jam' => '14:30 WIB',
                'pelanggan' => 'Budi Santoso',
                'telepon_pelanggan' => '081298765432',
                'alamat' => 'Komp. Orchid Park Blok B No. 12, Batam Center',
                'layanan' => 'Cuci AC',
                'unit_ac' => 'Daikin Inverter 1 PK (Ruang Tamu)',
                'keluhan' => 'AC sudah 4 bulan belum dicuci, hembusan angin pelan dan bau apek.',
                'teknisi' => 'Virgiawan Aziz L',
                'telepon_teknisi' => '081267676767',
                'status' => 'Selesai',
                'metode_bayar' => 'QRIS (Gopay/OVO)',
                'status_bayar' => 'Lunas',
                'durasi' => '75 Menit',
                'rincian' => [
                    ['item' => 'Jasa Cuci AC Split 1 PK Indoor & Outdoor', 'biaya' => 80000],
                    ['item' => 'Disinfektan & Anti Bakteri Evaporator', 'biaya' => 40000],
                ],
                'total_biaya' => 120000,
                'bukti' => [
                    'sebelum' => 'Filter & evaporator tertutup lapisan debu tebal, saluran drainase berlendir.',
                    'proses' => 'Pencucian menggunakan cover plastik pelindung & mesin steam bertekanan tinggi.',
                    'sesudah' => 'Evaporator bersih tuntas, suhu hembusan mencapai 16.2°C, aliran drain lancar.',
                    'catatan_teknisi' => 'Pembersihan tuntas. Tekanan freon R32 normal di 140 PSI. Arus kompresor 2.2 Ampere stabil.',
                    'waktu_selesai' => '20 Okt 2026, 15:45 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410002',
                'tanggal' => '20 Okt 2026',
                'jam' => '11:15 WIB',
                'pelanggan' => 'Siti Rahayu',
                'telepon_pelanggan' => '081344556677',
                'alamat' => 'Perumahan Bengkong Polisi Blok C No. 5, Batam',
                'layanan' => 'Isi Freon AC',
                'unit_ac' => 'Panasonic Eco Tough 1/2 PK (Kamar Utama)',
                'keluhan' => 'AC hanya mengeluarkan angin seperti kipas angin biasa, tidak ada dingin sama sekali.',
                'teknisi' => 'Achmal Feb',
                'telepon_teknisi' => '081267676767',
                'status' => 'Berlangsung',
                'metode_bayar' => 'Transfer Bank BCA',
                'status_bayar' => 'Lunas',
                'durasi' => 'Sedang Dikerjakan (45 Menit)',
                'rincian' => [
                    ['item' => 'Pengecekan Kebocoran Flare Pipa Tembaga', 'biaya' => 50000],
                    ['item' => 'Pengisian Freon R32 Full (Kapasitas 1/2 PK)', 'biaya' => 150000],
                ],
                'total_biaya' => 200000,
                'bukti' => [
                    'sebelum' => 'Tekanan manifold gauge menunjukkan 30 PSI (freon hampir habis akibat nepel longgar).',
                    'proses' => 'Pengencangan sambungan nepel pipa flare dan proses pengisian freon R32 murni.',
                    'sesudah' => 'Proses pengisian menuju tekanan standar 140 PSI (Sedang berjalan).',
                    'catatan_teknisi' => 'Nepel outdoor telah dikencangkan ulang. Freon diisi bertahap untuk menjaga kompresor.',
                    'waktu_selesai' => 'Estimasi selesai: 20 Okt 2026, 12:15 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410003',
                'tanggal' => '19 Okt 2026',
                'jam' => '09:00 WIB',
                'pelanggan' => 'Hendra Wijaya',
                'telepon_pelanggan' => '081922334455',
                'alamat' => 'Ruko Mahkota Raya Blok A No. 8, Batam Center',
                'layanan' => 'Bongkar Pasang AC',
                'unit_ac' => 'Sharp Plasmacluster 1.5 PK (Kantor Lt. 2)',
                'keluhan' => 'Pindahan ruangan kantor dari lantai 1 ke lantai 2, butuh pemindahan unit AC.',
                'teknisi' => 'Ahmad Fauzi',
                'telepon_teknisi' => '081399887766',
                'status' => 'Selesai',
                'metode_bayar' => 'Transfer Bank Mandiri',
                'status_bayar' => 'Lunas',
                'durasi' => '150 Menit',
                'rincian' => [
                    ['item' => 'Jasa Pembongkaran Unit AC Lt. 1', 'biaya' => 120000],
                    ['item' => 'Jasa Pemasangan & Bracket Baru Lt. 2', 'biaya' => 180000],
                    ['item' => 'Penyambungan & Vacuum Pipa Tembaga 3 Meter', 'biaya' => 50000],
                ],
                'total_biaya' => 350000,
                'bukti' => [
                    'sebelum' => 'Unit outdoor lama di lantai 1 dibongkar dengan metode pump down (freon terkunci).',
                    'proses' => 'Instalasi bracket baru di dinding luar Lt. 2, pemvakuman sistem dengan manifold.',
                    'sesudah' => 'Unit terpasang rapi, pipa dibungkus duct tape rapi, uji coba dingin normal.',
                    'catatan_teknisi' => 'Pump down berhasil, tidak ada freon terbuang. Vakum 15 menit mencapai -30 inHg.',
                    'waktu_selesai' => '19 Okt 2026, 11:35 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410004',
                'tanggal' => '19 Okt 2026',
                'jam' => '16:00 WIB',
                'pelanggan' => 'Rina Melati',
                'telepon_pelanggan' => '082188776655',
                'alamat' => 'Perumahan Sukajadi Cluster Beverly Blok D No. 22',
                'layanan' => 'Service AC',
                'unit_ac' => 'LG Dual Inverter 1 PK',
                'keluhan' => 'Air menetes bocor dari indoor membasahi tempat tidur & kasur kamar.',
                'teknisi' => 'Virgiawan Aziz L',
                'telepon_teknisi' => '081267676767',
                'status' => 'Selesai',
                'metode_bayar' => 'QRIS (ShopeePay)',
                'status_bayar' => 'Lunas',
                'durasi' => '90 Menit',
                'rincian' => [
                    ['item' => 'Pembersihan Talang Air & Tembak Sumbatan Drain', 'biaya' => 150000],
                    ['item' => 'Penggantian Selang Pembuangan Fleksibel 2m', 'biaya' => 50000],
                    ['item' => 'Penyetelan Kemiringan Bracket Indoor', 'biaya' => 50000],
                ],
                'total_biaya' => 250000,
                'bukti' => [
                    'sebelum' => 'Talang air indoor penuh lumut hitam tebal, selang pembuangan tersumbat total.',
                    'proses' => 'Penembakan sumbatan selang drainase dengan air bertekanan dan kawat pembersih.',
                    'sesudah' => 'Air pembuangan mengalir deras ke luar tanpa tetesan di dalam kamar.',
                    'catatan_teknisi' => 'Sumbatan lumut telah dibersihkan. Kemiringan talang disesuaikan 2 derajat ke pembuangan.',
                    'waktu_selesai' => '19 Okt 2026, 17:30 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410005',
                'tanggal' => '18 Okt 2026',
                'jam' => '10:00 WIB',
                'pelanggan' => 'Agus Prasetyo',
                'telepon_pelanggan' => '085299881122',
                'alamat' => 'Tiban Asri Blok G No. 14, Batam',
                'layanan' => 'Cek & Diagnosa AC',
                'unit_ac' => 'Gree Standard 1 PK',
                'keluhan' => 'Lampu timer indoor berkedip (blinking) dan outdoor tidak mau menyala.',
                'teknisi' => 'Achmal Feb',
                'telepon_teknisi' => '081267676767',
                'status' => 'Dibatalkan',
                'metode_bayar' => 'Tunai (Cash)',
                'status_bayar' => 'Batal',
                'durasi' => '-',
                'rincian' => [
                    ['item' => 'Biaya Kunjungan & Diagnosa Kerusakan', 'biaya' => 100000],
                ],
                'total_biaya' => 100000,
                'bukti' => [
                    'sebelum' => 'Pelanggan membatalkan pesanan karena harus dinas keluar kota mendadak.',
                    'proses' => 'Teknisi belum sampai ke lokasi ketika pembatalan dikonfirmasi pelanggan.',
                    'sesudah' => 'Status transaksi dibatalkan dengan konfirmasi kedua belah pihak.',
                    'catatan_teknisi' => 'Pelanggan membatalkan pesanan via telepon, dijadwalkan ulang minggu depan.',
                    'waktu_selesai' => '18 Okt 2026, 09:45 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410006',
                'tanggal' => '18 Okt 2026',
                'jam' => '13:30 WIB',
                'pelanggan' => 'Dewi Kusuma',
                'telepon_pelanggan' => '081277112233',
                'alamat' => 'Perumahan Citra Indah Blok H No. 7, Batam Center',
                'layanan' => 'Cuci AC',
                'unit_ac' => 'Panasonic Inverter 1/2 PK',
                'keluhan' => 'Servis berkala rutin 3 bulanan.',
                'teknisi' => 'Ahmad Fauzi',
                'telepon_teknisi' => '081399887766',
                'status' => 'Selesai',
                'metode_bayar' => 'QRIS (BCA Mobile)',
                'status_bayar' => 'Lunas',
                'durasi' => '60 Menit',
                'rincian' => [
                    ['item' => 'Jasa Cuci AC Split 1/2 PK Berkala', 'biaya' => 80000],
                ],
                'total_biaya' => 80000,
                'bukti' => [
                    'sebelum' => 'Debu tipis pada filter dan sirip indoor fan blower.',
                    'proses' => 'Cuci steam indoor dan pembersihan kondensor outdoor.',
                    'sesudah' => 'Unit bersih, embusan udara sejuk dan segar.',
                    'catatan_teknisi' => 'Kondisi unit sangat terawat. Tekanan freon cukup, ampere normal.',
                    'waktu_selesai' => '18 Okt 2026, 14:30 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410007',
                'tanggal' => '17 Okt 2026',
                'jam' => '08:30 WIB',
                'pelanggan' => 'Wahyu Nugroho',
                'telepon_pelanggan' => '081388990011',
                'alamat' => 'Komp. Ruko Nagoya Hill Blok P No. 3',
                'layanan' => 'Pemasangan AC Baru',
                'unit_ac' => 'Daikin Multi-Split 2 PK (Toko Komputer)',
                'keluhan' => 'Pemasangan AC baru untuk ruangan server & toko komputer baru.',
                'teknisi' => 'Virgiawan Aziz L',
                'telepon_teknisi' => '081267676767',
                'status' => 'Selesai',
                'metode_bayar' => 'Transfer Bank BNI',
                'status_bayar' => 'Lunas',
                'durasi' => '210 Menit',
                'rincian' => [
                    ['item' => 'Jasa Instalasi Unit Baru Daikin 2 PK', 'biaya' => 350000],
                    ['item' => 'Pemasangan Bracket Heavy Duty Outdoor', 'biaya' => 75000],
                    ['item' => 'Kabel Power Listrik NYM 3x2.5mm (10m)', 'biaya' => 75000],
                ],
                'total_biaya' => 500000,
                'bukti' => [
                    'sebelum' => 'Ruangan baru belum ada instalasi AC, jalur pipa dibor menembus dinding.',
                    'proses' => 'Pemasangan bracket indoor, flaring pipa tebal, proses vacuum 30 menit.',
                    'sesudah' => 'AC baru terpasang kokoh, dingin merata di ruangan server, garansi instalasi aktif.',
                    'catatan_teknisi' => 'Instalasi sesuai SOP Daikin. Kebocoran freon nihil pada uji sabun bertekanan.',
                    'waktu_selesai' => '17 Okt 2026, 12:00 WIB'
                ]
            ],
            [
                'id' => 'TRX-2410008',
                'tanggal' => '17 Okt 2026',
                'jam' => '15:15 WIB',
                'pelanggan' => 'Indah Permata',
                'telepon_pelanggan' => '085733445566',
                'alamat' => 'Villa Panbil Blok G No. 19, Mukakuning',
                'layanan' => 'Service AC',
                'unit_ac' => 'Mitsubishi Electric 1 PK',
                'keluhan' => 'Kipas outdoor tidak berputar dan terdengar suara dengung keras.',
                'teknisi' => 'Achmal Feb',
                'telepon_teknisi' => '081267676767',
                'status' => 'Selesai',
                'metode_bayar' => 'QRIS (DANA)',
                'status_bayar' => 'Lunas',
                'durasi' => '65 Menit',
                'rincian' => [
                    ['item' => 'Penggantian Kapasitor Outdoor 25 uF Original', 'biaya' => 125000],
                    ['item' => 'Jasa Pengecekan & Pengujian Kelistrikan', 'biaya' => 50000],
                ],
                'total_biaya' => 175000,
                'bukti' => [
                    'sebelum' => 'Kapasitor lama kembung dan rusak (kapasitansi drop ke 5 uF).',
                    'proses' => 'Pelepasan kapasitor rusak dan penggantian part baru original bernilai 25 uF.',
                    'sesudah' => 'Motor fan outdoor langsung berputar kencang, kompresor hidup normal.',
                    'catatan_teknisi' => 'Kapasitor diganti merk Shizuki 25 uF. Tegangan kompresor 224 Volt normal.',
                    'waktu_selesai' => '17 Okt 2026, 16:20 WIB'
                ]
            ],
        ];
    }

    public function index(Request $request)
    {
        return view('admin.kelola-transaksi', [
            'transaksiList' => self::daftarTransaksi(),
        ]);
    }
}
