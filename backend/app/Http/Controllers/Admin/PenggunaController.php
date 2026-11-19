<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Support\StatusAdmin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PenggunaController extends Controller
{
    /**
     * Daftar pengguna contoh (sumber tunggal untuk Kelola Pengguna dan badge sidebar).
     *
     * @return array<int, array<string, mixed>>
     */
    public static function dataDasar(): array
    {
        return [
            // 1. GanAnWo - Teknisi Menunggu Verifikasi (Default selected sesuai Figma)
            [
                'id' => 'PAW3311',
                'nama' => 'GanAnWo',
                'email' => 'gananwo@acare.id',
                'telepon' => '0812676767',
                'alamat' => 'Mataram Barat, Mataram',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'menunggu',
                'tanggal_daftar' => '27 Sept 2026 12:25',
                'sejak_tanggal' => '12 Sept 2026 12:25',
                'kendaraan' => 'Honda Beat (BP 4892 QL)',
                'keahlian' => 'Servis AC Split, Cuci AC, Tambah Freon R32',
                'pengalaman' => '3 Tahun Teknisi Pendingin',
                'alasan_penolakan' => null,
                'dokumen' => [
                    [
                        'id' => 'ktp',
                        'nama' => 'KTP',
                        'file' => 'Ktp_gananwo.jpg',
                        'deskripsi' => 'Kartu Tanda Penduduk Asli (NIK & Foto)',
                        'status' => 'menunggu',
                        'catatan' => 'Menunggu pengecekan kelayakan identitas',
                    ],
                    [
                        'id' => 'ijazah',
                        'nama' => 'Ijazah / Sertifikat',
                        'file' => 'Ijazah_gananwo.pdf',
                        'deskripsi' => 'Sertifikat Kompetensi BNSP Teknisi AC',
                        'status' => 'menunggu',
                        'catatan' => 'Sertifikat Badan Nasional Sertifikasi Profesi',
                    ],
                    [
                        'id' => 'foto',
                        'nama' => 'Foto diri',
                        'file' => 'Foto_gananwo.jpg',
                        'deskripsi' => 'Pas Foto Resmi Teknisi Latar Polos',
                        'status' => 'menunggu',
                        'catatan' => 'Wajah terlihat jelas tanpa kacamata hitam',
                    ],
                    [
                        'id' => 'surat_kerja',
                        'nama' => 'Surat Keterangan Kerja',
                        'file' => 'Surat_pengalaman.pdf',
                        'deskripsi' => 'Surat Rekomendasi Kerja dari Vendor AC',
                        'status' => 'menunggu',
                        'catatan' => 'Masa kerja 3 tahun di CV Berkah Dingin Teknik',
                    ],
                ],
            ],

            // 2. Rendi Kurniawan - Teknisi Menunggu Verifikasi
            [
                'id' => 'TEK2021',
                'nama' => 'Rendi Kurniawan',
                'email' => 'rendi.k@acare.id',
                'telepon' => '081377889900',
                'alamat' => 'Batu Aji, Batam',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'menunggu',
                'tanggal_daftar' => '28 Sept 2026 09:15',
                'sejak_tanggal' => '15 Sept 2026 09:10',
                'kendaraan' => 'Yamaha Jupiter (BP 2341 AB)',
                'keahlian' => 'Pemasangan AC Baru & Bongkar Pasang',
                'pengalaman' => '2 Tahun Bengkel Sejuk Mandiri',
                'alasan_penolakan' => null,
                'dokumen' => [
                    [
                        'id' => 'ktp',
                        'nama' => 'KTP',
                        'file' => 'KTP_Rendi_K.jpg',
                        'deskripsi' => 'KTP Batam Elektronik',
                        'status' => 'menunggu',
                        'catatan' => 'NIK 2171012304950002',
                    ],
                    [
                        'id' => 'ijazah',
                        'nama' => 'Ijazah / Sertifikat',
                        'file' => 'Ijazah_SMK_Pendingin.pdf',
                        'deskripsi' => 'Ijazah SMK Jurusan Teknik Pendingin & Tata Udara',
                        'status' => 'menunggu',
                        'catatan' => 'SMK Negeri 1 Batam',
                    ],
                    [
                        'id' => 'foto',
                        'nama' => 'Foto diri',
                        'file' => 'PasFoto_Rendi.jpg',
                        'deskripsi' => 'Pas Foto 4x6 Latar Merah',
                        'status' => 'menunggu',
                        'catatan' => 'Sesuai format resmi identitas ACare',
                    ],
                    [
                        'id' => 'surat_kerja',
                        'nama' => 'Surat Keterangan Kerja',
                        'file' => 'Surat_Rekomendasi_CV_Dingin.pdf',
                        'deskripsi' => 'Surat Referensi Teknisi AC Batam',
                        'status' => 'menunggu',
                        'catatan' => 'CV Batam Dingin Sejahtera',
                    ],
                ],
            ],

            // 3. Dian Pratama - Teknisi Menunggu Verifikasi
            [
                'id' => 'TEK2022',
                'nama' => 'Dian Pratama',
                'email' => 'dian.pratama@acare.id',
                'telepon' => '082155667788',
                'alamat' => 'Bengkong Laut, Batam',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'menunggu',
                'tanggal_daftar' => '29 Sept 2026 14:00',
                'sejak_tanggal' => '18 Sept 2026 14:30',
                'kendaraan' => 'Honda Vario 125 (BP 5544 CD)',
                'keahlian' => 'Pembersihan AC Inverter & Ganti Kompresor',
                'pengalaman' => '4 Tahun Service AC Multi-brand',
                'alasan_penolakan' => null,
                'dokumen' => [
                    [
                        'id' => 'ktp',
                        'nama' => 'KTP',
                        'file' => 'KTP_Dian_Pratama.jpg',
                        'deskripsi' => 'e-KTP Kepulauan Riau',
                        'status' => 'menunggu',
                        'catatan' => 'Data identitas lengkap',
                    ],
                    [
                        'id' => 'ijazah',
                        'nama' => 'Ijazah / Sertifikat',
                        'file' => 'Sertifikat_Pelatihan_Daikin.pdf',
                        'deskripsi' => 'Sertifikat Pelatihan Authorized Daikin',
                        'status' => 'menunggu',
                        'catatan' => 'Keahlian Multi-Split & Inverter',
                    ],
                    [
                        'id' => 'foto',
                        'nama' => 'Foto diri',
                        'file' => 'Foto_Dian.jpg',
                        'deskripsi' => 'Foto Diri Bersama KTP',
                        'status' => 'menunggu',
                        'catatan' => 'Verifikasi keaslian dokumen',
                    ],
                    [
                        'id' => 'surat_kerja',
                        'nama' => 'Surat Keterangan Kerja',
                        'file' => 'Surat_Pengalaman_Dian.pdf',
                        'deskripsi' => 'Surat Pengalaman PT Sentosa Jaya',
                        'status' => 'menunggu',
                        'catatan' => 'Pengalaman instalasi gedung komersial',
                    ],
                ],
            ],

            // 4. Virgiawan Aziz L - Teknisi Terverifikasi (Sesuai Figma)
            [
                'id' => 'PAW3312',
                'nama' => 'Virgiawan Aziz L',
                'email' => 'virgiawan@acare.id',
                'telepon' => '081267676767',
                'alamat' => 'Batu Aji, Batam',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'terverifikasi',
                'tanggal_daftar' => '27 Sept 2026 12:25',
                'sejak_tanggal' => '05 Agu 2026 10:00',
                'kendaraan' => 'Yamaha NMAX (BP 3456 XY)',
                'keahlian' => 'Semua Jenis AC Split, Cassette, Standing',
                'pengalaman' => '5 Tahun Teknisi Senior',
                'alasan_penolakan' => null,
                'dokumen' => [
                    ['id' => 'ktp', 'nama' => 'KTP', 'file' => 'KTP_Virgiawan.jpg', 'deskripsi' => 'KTP Batam Asli Terverifikasi', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'ijazah', 'nama' => 'Ijazah / Sertifikat', 'file' => 'Sertifikat_BNSP_Virgi.pdf', 'deskripsi' => 'Sertifikat Kompetensi BNSP AC Grade A', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'foto', 'nama' => 'Foto diri', 'file' => 'Foto_Virgiawan.jpg', 'deskripsi' => 'Pas Foto Resmi Seragam ACare', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'surat_kerja', 'nama' => 'Surat Keterangan Kerja', 'file' => 'Rekomendasi_Kerja_Virgi.pdf', 'deskripsi' => 'Surat Pengalaman 5 Tahun', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                ],
            ],

            // 5. Achmal Feb - Teknisi Terverifikasi (Sesuai Figma)
            [
                'id' => 'PAW3313',
                'nama' => 'Achmal Feb',
                'email' => 'achmal@acare.id',
                'telepon' => '081267676767',
                'alamat' => 'Nagoya, Batam',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'terverifikasi',
                'tanggal_daftar' => '27 Sept 2026 12:25',
                'sejak_tanggal' => '12 Agu 2026 11:30',
                'kendaraan' => 'Honda Vario (BP 1122 ZZ)',
                'keahlian' => 'Cuci Kimia, Pengisian Freon, Servis PCB',
                'pengalaman' => '3 Tahun Teknisi AC Batam',
                'alasan_penolakan' => null,
                'dokumen' => [
                    ['id' => 'ktp', 'nama' => 'KTP', 'file' => 'KTP_Achmal.jpg', 'deskripsi' => 'KTP Terverifikasi', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'ijazah', 'nama' => 'Ijazah / Sertifikat', 'file' => 'Ijazah_SMK_Achmal.pdf', 'deskripsi' => 'SMK Teknik Pendingin', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'foto', 'nama' => 'Foto diri', 'file' => 'Foto_Achmal.jpg', 'deskripsi' => 'Foto Diri Resmi', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'surat_kerja', 'nama' => 'Surat Keterangan Kerja', 'file' => 'Surat_Achmal.pdf', 'deskripsi' => 'Surat Referensi Kerja', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                ],
            ],

            // 6. Ahmad Fauzi - Teknisi Terverifikasi
            [
                'id' => 'PAW3314',
                'nama' => 'Ahmad Fauzi',
                'email' => 'ahmad.fauzi@acare.id',
                'telepon' => '081399887766',
                'alamat' => 'Batam Center, Batam',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'terverifikasi',
                'tanggal_daftar' => '26 Sept 2026 10:15',
                'sejak_tanggal' => '20 Agu 2026 09:00',
                'kendaraan' => 'Honda Beat Street (BP 3322 YY)',
                'keahlian' => 'Cuci AC & Service Rutin',
                'pengalaman' => '2 Tahun Teknisi Lapangan',
                'alasan_penolakan' => null,
                'dokumen' => [
                    ['id' => 'ktp', 'nama' => 'KTP', 'file' => 'KTP_Ahmad.jpg', 'deskripsi' => 'KTP Batam Terverifikasi', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'ijazah', 'nama' => 'Ijazah / Sertifikat', 'file' => 'Sertifikat_Ahmad.pdf', 'deskripsi' => 'Sertifikat Kursus Teknisi AC', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'foto', 'nama' => 'Foto diri', 'file' => 'Foto_Ahmad.jpg', 'deskripsi' => 'Pas Foto Teknisi', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                    ['id' => 'surat_kerja', 'nama' => 'Surat Keterangan Kerja', 'file' => 'Surat_Ahmad.pdf', 'deskripsi' => 'Surat Keterangan Bengkel', 'status' => 'valid', 'catatan' => 'Telah terverifikasi oleh Admin'],
                ],
            ],

            // 7. Fajar Nugroho - Teknisi Ditolak
            [
                'id' => 'TEK3001',
                'nama' => 'Fajar Nugroho',
                'email' => 'fajar.n@acare.id',
                'telepon' => '085211223344',
                'alamat' => 'Tiban Baru, Batam',
                'peran' => 'Teknisi',
                'status_verifikasi' => 'ditolak',
                'tanggal_daftar' => '25 Sept 2026 15:45',
                'sejak_tanggal' => '10 Sept 2026 14:00',
                'kendaraan' => 'Suzuki Smash (BP 4433 MN)',
                'keahlian' => 'Pembersihan AC Sederhana',
                'pengalaman' => '1 Tahun Asisten Teknisi',
                'alasan_penolakan' => 'Foto KTP buram dan terpotong. Sertifikat keahlian teknik pendingin belum dilampirkan.',
                'dokumen' => [
                    ['id' => 'ktp', 'nama' => 'KTP', 'file' => 'KTP_Buram_Fajar.jpg', 'deskripsi' => 'Foto KTP Tidak Terbaca Jelas', 'status' => 'tidak_valid', 'catatan' => 'NIK tidak terlihat, sudut terpotong'],
                    ['id' => 'ijazah', 'nama' => 'Ijazah / Sertifikat', 'file' => 'Ijazah_SMA_Umum.pdf', 'deskripsi' => 'Ijazah SMA (Bukan Kejuruan/Kompetensi)', 'status' => 'tidak_valid', 'catatan' => 'Wajib sertifikat keahlian teknik AC'],
                    ['id' => 'foto', 'nama' => 'Foto diri', 'file' => 'Selfie_Fajar.jpg', 'deskripsi' => 'Selfie Menggunakan Topi & Kacamata', 'status' => 'tidak_valid', 'catatan' => 'Wajah tidak boleh tertutup aksesoris'],
                    ['id' => 'surat_kerja', 'nama' => 'Surat Keterangan Kerja', 'file' => 'Surat_Fajar.pdf', 'deskripsi' => 'Surat Tanpa Stempel Resmi', 'status' => 'tidak_valid', 'catatan' => 'Tidak ada legalitas dari perusahaan'],
                ],
            ],

            // 8. Nadya Almira - Pengguna / Pelanggan Biasa
            [
                'id' => 'USR1011',
                'nama' => 'Nadya Almira',
                'email' => 'nadya.almira@gmail.com',
                'telepon' => '081298765432',
                'alamat' => 'Sekupang, Batam',
                'peran' => 'Pengguna',
                'status_verifikasi' => 'terverifikasi',
                'tanggal_daftar' => '26 Sept 2026 14:10',
                'kendaraan' => null,
                'total_order' => 5,
                'riwayat_order' => [
                    ['id' => 'ORD-101', 'layanan' => 'Cuci AC Split (1 PK)', 'tgl' => '18 Okt 2026', 'biaya' => 'Rp 80.000', 'teknisi' => 'Virgiawan Aziz L', 'status' => 'Selesai'],
                    ['id' => 'ORD-092', 'layanan' => 'Tambah Freon R32', 'tgl' => '05 Sep 2026', 'biaya' => 'Rp 150.000', 'teknisi' => 'Achmal Feb', 'status' => 'Selesai'],
                ],
                'dokumen' => [],
            ],

            // 9. Thoriq H - Pengguna / Pelanggan Biasa
            [
                'id' => 'USR1012',
                'nama' => 'Thoriq H',
                'email' => 'thoriq.h@gmail.com',
                'telepon' => '085712345678',
                'alamat' => 'Tiban Indah, Batam',
                'peran' => 'Pengguna',
                'status_verifikasi' => 'terverifikasi',
                'tanggal_daftar' => '25 Sept 2026 10:05',
                'kendaraan' => null,
                'total_order' => 3,
                'riwayat_order' => [
                    ['id' => 'ORD-103', 'layanan' => 'Service AC Tidak Dingin', 'tgl' => '12 Okt 2026', 'biaya' => 'Rp 120.000', 'teknisi' => 'Ahmad Fauzi', 'status' => 'Selesai'],
                ],
                'dokumen' => [],
            ],

            // 10. Siti Rahayu - Pengguna / Pelanggan Biasa
            [
                'id' => 'USR1013',
                'nama' => 'Siti Rahayu',
                'email' => 'siti.rahayu@gmail.com',
                'telepon' => '081344556677',
                'alamat' => 'Bengkong Polisi, Batam',
                'peran' => 'Pengguna',
                'status_verifikasi' => 'terverifikasi',
                'tanggal_daftar' => '24 Sept 2026 08:30',
                'kendaraan' => null,
                'total_order' => 2,
                'riwayat_order' => [
                    ['id' => 'ORD-104', 'layanan' => 'Cuci AC Inverter', 'tgl' => '20 Okt 2026', 'biaya' => 'Rp 90.000', 'teknisi' => 'Virgiawan Aziz L', 'status' => 'Berlangsung'],
                ],
                'dokumen' => [],
            ],
        ];
    }

    /**
     * Daftar pengguna dengan perubahan status dari session sudah diterapkan.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarPengguna(): array
    {
        $statusTersimpan = StatusAdmin::ambil('pengguna') ?? [];
        $dokumenTersimpan = StatusAdmin::ambil('dokumen') ?? [];

        return array_map(function (array $pengguna) use ($statusTersimpan, $dokumenTersimpan): array {
            $ubah = $statusTersimpan[$pengguna['id']] ?? null;
            if ($ubah !== null) {
                $pengguna['status_verifikasi'] = $ubah['status'];
                $pengguna['alasan_penolakan'] = $ubah['alasan'];
            }

            foreach ($pengguna['dokumen'] as $i => $dokumen) {
                $status = $dokumenTersimpan[$pengguna['id'].':'.$dokumen['id']] ?? null;
                if ($status !== null) {
                    $pengguna['dokumen'][$i]['status'] = $status;
                    $pengguna['dokumen'][$i]['catatan'] = $status === 'valid'
                        ? 'Telah diperiksa: berkas asli dan valid'
                        : ($status === 'tidak_valid' ? 'Telah diperiksa: perlu perbaikan atau buram' : $dokumen['catatan']);
                } elseif ($ubah !== null && $ubah['status'] === 'terverifikasi') {
                    $pengguna['dokumen'][$i]['status'] = 'valid';
                    $pengguna['dokumen'][$i]['catatan'] = 'Diverifikasi oleh Admin Operasional';
                }
            }

            return $pengguna;
        }, self::dataDasar());
    }

    /**
     * Ubah status verifikasi satu atau beberapa teknisi (juga dipakai untuk membatalkan).
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required', 'string'],
            'perubahan.*.status' => ['required', 'in:menunggu,terverifikasi,ditolak'],
            'perubahan.*.alasan' => ['nullable', 'string', 'max:1000'],
            'massal' => ['sometimes', 'boolean'],
        ]);

        $daftar = collect(self::daftarPengguna())->keyBy('id');

        foreach ($data['perubahan'] as $ubah) {
            $pengguna = $daftar->get($ubah['id']);
            if ($pengguna === null || $pengguna['peran'] !== 'Teknisi') {
                return response()->json(['pesan' => 'Hanya teknisi yang memiliki status verifikasi.'], 422);
            }
            if ($ubah['status'] === 'ditolak' && trim((string) ($ubah['alasan'] ?? '')) === '') {
                return response()->json(['pesan' => 'Alasan penolakan wajib diisi.'], 422);
            }
            if (($data['massal'] ?? false) && $ubah['status'] === 'terverifikasi') {
                $belumValid = collect($pengguna['dokumen'])->contains(fn (array $d): bool => $d['status'] !== 'valid');
                if ($belumValid) {
                    return response()->json([
                        'pesan' => $pengguna['nama'].' belum memiliki semua dokumen berstatus valid. Tinjau satu per satu.',
                    ], 422);
                }
            }
        }

        foreach ($data['perubahan'] as $ubah) {
            StatusAdmin::simpan('pengguna', $ubah['id'], [
                'status' => $ubah['status'],
                'alasan' => $ubah['status'] === 'ditolak' ? trim($ubah['alasan']) : null,
            ]);
        }

        return response()->json(['ok' => true, 'menunggu' => count(self::teknisiMenunggu())]);
    }

    /**
     * Tandai hasil pemeriksaan satu dokumen teknisi.
     */
    public function ubahDokumen(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => ['required', 'string'],
            'dokumen_id' => ['required', 'string'],
            'status' => ['required', 'in:menunggu,valid,tidak_valid'],
        ]);

        $pengguna = collect(self::dataDasar())->firstWhere('id', $data['id']);
        $ada = $pengguna !== null && collect($pengguna['dokumen'])->contains('id', $data['dokumen_id']);
        if (! $ada) {
            return response()->json(['pesan' => 'Dokumen tidak ditemukan.'], 404);
        }

        StatusAdmin::simpan('dokumen', $data['id'].':'.$data['dokumen_id'], $data['status']);

        return response()->json(['ok' => true]);
    }

    public function index(Request $request)
    {
        $penggunaList = self::daftarPengguna();

        // Default pengguna terpilih adalah GanAnWo (Teknisi pending yang ada di Figma)
        $selectedPengguna = $penggunaList[0];

        $statusAwal = in_array($request->query('status'), ['menunggu', 'terverifikasi', 'ditolak'], true)
            ? $request->query('status')
            : 'semua';

        return view('admin.kelola-pengguna', [
            'penggunaList' => $penggunaList,
            'selectedPengguna' => $selectedPengguna,
            'statusAwal' => $statusAwal,
        ]);
    }

    /**
     * Teknisi yang masih menunggu verifikasi (id dan nama).
     *
     * @return array<int, array{id: string, nama: string}>
     */
    public static function teknisiMenunggu(): array
    {
        $menunggu = array_filter(
            self::daftarPengguna(),
            fn (array $pengguna): bool => $pengguna['peran'] === 'Teknisi' && $pengguna['status_verifikasi'] === 'menunggu'
        );

        return array_values(array_map(
            fn (array $pengguna): array => ['id' => $pengguna['id'], 'nama' => $pengguna['nama']],
            $menunggu
        ));
    }
}
