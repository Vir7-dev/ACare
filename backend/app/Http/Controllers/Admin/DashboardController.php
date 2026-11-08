<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Carbon\CarbonInterface;
use Illuminate\Contracts\View\View;

class DashboardController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    /**
     * Format tanggal pendek berbahasa Indonesia, contoh: 8 Nov 2026.
     */
    private function tanggalIndonesia(CarbonInterface $tanggal): string
    {
        return $tanggal->day.' '.self::BULAN[$tanggal->month - 1].' '.$tanggal->year;
    }

    /** Rata-rata nilai satu pesanan selesai pada data contoh (Rp). */
    private const RATA_RATA_NILAI = 132000;

    /**
     * Data ringkasan dan grafik untuk tiap pilihan periode (data contoh).
     * Total pesanan, pesanan selesai, dan nilai transaksi dihitung dari seri grafik
     * sehingga angka kartu selalu sama dengan jumlah di grafik.
     *
     * @return array<string, array<string, mixed>>
     */
    private function dataPeriode(): array
    {
        $hariIni = now();

        $dasar = [
            'hari' => [
                'rentang' => $this->tanggalIndonesia($hariIni),
                'teknisi' => 6,
                'labels' => ['06.00–09.00', '09.00–12.00', '12.00–15.00', '15.00–18.00', '18.00–21.00'],
                'selesai' => [1, 3, 2, 2, 1],
                'berlangsung' => [0, 0, 0, 1, 0],
                'dibatalkan' => [0, 0, 1, 0, 0],
            ],
            '7hari' => [
                'rentang' => $this->tanggalIndonesia($hariIni->copy()->subDays(6)).' – '.$this->tanggalIndonesia($hariIni),
                'teknisi' => 24,
                'labels' => collect(range(6, 0))->map(fn (int $mundur): string => $hariIni->copy()->subDays($mundur)->day.' '.self::BULAN[$hariIni->copy()->subDays($mundur)->month - 1])->all(),
                'selesai' => [7, 9, 8, 12, 9, 6, 7],
                'berlangsung' => [0, 0, 0, 0, 0, 1, 1],
                'dibatalkan' => [1, 0, 1, 0, 0, 0, 0],
            ],
            '30hari' => [
                'rentang' => $this->tanggalIndonesia($hariIni->copy()->subDays(29)).' – '.$this->tanggalIndonesia($hariIni),
                'teknisi' => 48,
                'labels' => ['Minggu 1', 'Minggu 2', 'Minggu 3', 'Minggu 4', 'Minggu 5'],
                'selesai' => [26, 31, 27, 35, 20],
                'berlangsung' => [0, 0, 0, 1, 3],
                'dibatalkan' => [1, 2, 0, 1, 1],
            ],
        ];

        $hasil = [];
        foreach ($dasar as $kunci => $data) {
            $selesai = array_sum($data['selesai']);
            $hasil[$kunci] = [
                'rentang' => $data['rentang'],
                'ringkasan' => [
                    'pesanan' => $selesai + array_sum($data['berlangsung']) + array_sum($data['dibatalkan']),
                    'selesai' => $selesai,
                    'nilai' => $selesai * self::RATA_RATA_NILAI,
                    'teknisi' => $data['teknisi'],
                ],
                'grafik' => [
                    'labels' => $data['labels'],
                    'selesai' => $data['selesai'],
                    'berlangsung' => $data['berlangsung'],
                    'dibatalkan' => $data['dibatalkan'],
                ],
            ];
        }

        return $hasil;
    }

    public function index(): View
    {
        // Transaksi terbaru: memakai sumber data yang sama dengan halaman Kelola Transaksi
        $transaksi = array_map(
            fn (array $trx): array => [
                'id' => $trx['id'],
                'tanggal' => $trx['tanggal'],
                'jam' => str_replace(' WIB', '', $trx['jam']),
                'pelanggan' => $trx['pelanggan'],
                'layanan' => $trx['layanan'],
                'teknisi' => $trx['teknisi'],
                'harga' => $trx['total_biaya'],
                'status' => $trx['status'],
            ],
            array_slice(TransaksiController::daftarTransaksi(), 0, 8)
        );

        // Teknisi yang butuh verifikasi segera: memakai data Kelola Pengguna
        $teknisiMenungguVerifikasi = PenggunaController::teknisiMenunggu();

        return view('admin.dashboard', [
            'periode' => $this->dataPeriode(),
            'transaksi' => $transaksi,
            'teknisiMenungguVerifikasi' => $teknisiMenungguVerifikasi,
            'jumlahPengaduanBaru' => PengaduanController::jumlahBaru(),
        ]);
    }
}
