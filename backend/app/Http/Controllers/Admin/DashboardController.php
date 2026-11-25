<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Pengaduan;
use App\Models\PengajuanDana;
use App\Models\Pesanan;
use App\Models\Teknisi;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class DashboardController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    private const STATUS_VERIFIKASI_TERVERIFIKASI = 'terverifikasi';

    private const STATUS_VERIFIKASI_MENUNGGU = 'menunggu';

    private const STATUS_PENGADUAN_BARU = 'diajukan';

    private const STATUS_PENGAJUAN_MENUNGGU = 'menunggu';

    private const STATUS_BERLANGSUNG = [
        Pesanan::MENUJU_LOKASI,
        Pesanan::TIBA,
        Pesanan::PENGECEKAN_AWAL,
        Pesanan::MENUNGGU_PERSETUJUAN_BIAYA,
        Pesanan::DIKERJAKAN,
        Pesanan::MENUNGGU_PEMBAYARAN,
    ];

    private function tanggalIndonesia(CarbonInterface $tanggal): string
    {
        return $tanggal->day.' '.self::BULAN[$tanggal->month - 1].' '.$tanggal->year;
    }

    /**
     * @return Collection<int, Teknisi>
     */
    public static function teknisiMenunggu(): Collection
    {
        return Teknisi::query()
            ->with('pengguna')
            ->where('status_verifikasi', self::STATUS_VERIFIKASI_MENUNGGU)
            ->get();
    }

    public static function jumlahPengaduanBaru(): int
    {
        return Pengaduan::query()
            ->where('status_pengaduan', self::STATUS_PENGADUAN_BARU)
            ->count();
    }

    public static function jumlahPengajuanMenunggu(): int
    {
        return PengajuanDana::query()
            ->where('status', self::STATUS_PENGAJUAN_MENUNGGU)
            ->count();
    }

    /**
     * @return array<string, array<string, mixed>>
     */
    private function dataPeriode(): array
    {
        $hariIni = now();
        $teknisiAktif = Teknisi::query()
            ->where('status_verifikasi', self::STATUS_VERIFIKASI_TERVERIFIKASI)
            ->count();

        // 1. HARI INI (slot jam 06.00 - 21.00)
        $mulaiHari = $hariIni->copy()->startOfDay();
        $akhirHari = $hariIni->copy()->endOfDay();
        $pesananHari = Pesanan::query()
            ->whereBetween('dibuat_pada', [$mulaiHari, $akhirHari])
            ->get();

        $slotJam = [
            ['06.00-09.00', 6, 8],
            ['09.00-12.00', 9, 11],
            ['12.00-15.00', 12, 14],
            ['15.00-18.00', 15, 17],
            ['18.00-21.00', 18, 20],
            ['21.00-24.00', 21, 23],
        ];

        $labelsHari = [];
        $selesaiHari = [];
        $berlangsungHari = [];
        $dibatalkanHari = [];

        foreach ($slotJam as [$label, $jamAwal, $jamAkhir]) {
            $labelsHari[] = $label;
            $itemSlot = $pesananHari->filter(function (Pesanan $p) use ($jamAwal, $jamAkhir): bool {
                if (!$p->dibuat_pada) {
                    return false;
                }
                $jam = (int) $p->dibuat_pada->format('H');

                return $jam >= $jamAwal && $jam <= $jamAkhir;
            });

            $selesaiHari[] = $itemSlot->where('status_pesanan', Pesanan::SELESAI)->count();
            $berlangsungHari[] = $itemSlot->whereIn('status_pesanan', self::STATUS_BERLANGSUNG)->count();
            $dibatalkanHari[] = $itemSlot->where('status_pesanan', Pesanan::DIBATALKAN)->count();
        }

        // 2. 7 HARI TERAKHIR
        $mulai7Hari = $hariIni->copy()->subDays(6)->startOfDay();
        $akhir7Hari = $hariIni->copy()->endOfDay();
        $pesanan7Hari = Pesanan::query()
            ->whereBetween('dibuat_pada', [$mulai7Hari, $akhir7Hari])
            ->get();

        $labels7 = [];
        $selesai7 = [];
        $berlangsung7 = [];
        $dibatalkan7 = [];

        foreach (range(6, 0) as $mundur) {
            $tgl = $hariIni->copy()->subDays($mundur);
            $kunciTgl = $tgl->format('Y-m-d');
            $labels7[] = $tgl->day.' '.self::BULAN[$tgl->month - 1];

            $itemHari = $pesanan7Hari->filter(
                fn (Pesanan $p): bool => optional($p->dibuat_pada)->format('Y-m-d') === $kunciTgl
            );

            $selesai7[] = $itemHari->where('status_pesanan', Pesanan::SELESAI)->count();
            $berlangsung7[] = $itemHari->whereIn('status_pesanan', self::STATUS_BERLANGSUNG)->count();
            $dibatalkan7[] = $itemHari->where('status_pesanan', Pesanan::DIBATALKAN)->count();
        }

        // 3. 30 HARI TERAKHIR (5 kelompok masing-masing 6 hari)
        $mulai30Hari = $hariIni->copy()->subDays(29)->startOfDay();
        $akhir30Hari = $hariIni->copy()->endOfDay();
        $pesanan30Hari = Pesanan::query()
            ->whereBetween('dibuat_pada', [$mulai30Hari, $akhir30Hari])
            ->get();

        $labels30 = [];
        $selesai30 = [];
        $berlangsung30 = [];
        $dibatalkan30 = [];

        for ($i = 0; $i < 5; $i++) {
            $awalKelompok = $mulai30Hari->copy()->addDays($i * 6)->startOfDay();
            $akhirKelompok = $awalKelompok->copy()->addDays(5)->endOfDay();
            if ($akhirKelompok->gt($akhir30Hari)) {
                $akhirKelompok = $akhir30Hari->copy();
            }

            $labels30[] = $awalKelompok->day.' '.self::BULAN[$awalKelompok->month - 1] .'-'.$akhirKelompok->day.' '.self::BULAN[$akhirKelompok->month - 1];

            $itemKelompok = $pesanan30Hari->filter(function (Pesanan $p) use ($awalKelompok, $akhirKelompok): bool {
                if (!$p->dibuat_pada) {
                    return false;
                }

                return $p->dibuat_pada->betweenIncluded($awalKelompok, $akhirKelompok);
            });

            $selesai30[] = $itemKelompok->where('status_pesanan', Pesanan::SELESAI)->count();
            $berlangsung30[] = $itemKelompok->whereIn('status_pesanan', self::STATUS_BERLANGSUNG)->count();
            $dibatalkan30[] = $itemKelompok->where('status_pesanan', Pesanan::DIBATALKAN)->count();
        }

        return [
            'hari' => $this->susunPaketPeriode(
                $this->tanggalIndonesia($hariIni),
                $pesananHari,
                $teknisiAktif,
                $labelsHari,
                $selesaiHari,
                $berlangsungHari,
                $dibatalkanHari
            ),
            '7hari' => $this->susunPaketPeriode(
                $this->tanggalIndonesia($hariIni->copy()->subDays(6)).' – '.$this->tanggalIndonesia($hariIni),
                $pesanan7Hari,
                $teknisiAktif,
                $labels7,
                $selesai7,
                $berlangsung7,
                $dibatalkan7
            ),
            '30hari' => $this->susunPaketPeriode(
                $this->tanggalIndonesia($hariIni->copy()->subDays(29)).' – '.$this->tanggalIndonesia($hariIni),
                $pesanan30Hari,
                $teknisiAktif,
                $labels30,
                $selesai30,
                $berlangsung30,
                $dibatalkan30
            ),
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function dataKustom(string $dari, string $sampai, int $teknisiAktif): ?array
    {
        try {
            $mulai = Carbon::createFromFormat('Y-m-d', $dari)->startOfDay();
            $akhir = Carbon::createFromFormat('Y-m-d', $sampai)->endOfDay();
        } catch (\Throwable) {
            return null;
        }

        if ($akhir->lt($mulai)) {
            [$mulai, $akhir] = [$mulai->copy()->startOfDay(), $mulai->copy()->endOfDay()];
        }

        $pesanan = Pesanan::query()
            ->whereBetween('dibuat_pada', [$mulai, $akhir])
            ->get();

        $totalHari = $mulai->copy()->startOfDay()->diffInDays($akhir->copy()->startOfDay()) + 1;
        $jumlahKelompok = min(5, max(1, $totalHari));

        $labels = [];
        $selesai = [];
        $berlangsung = [];
        $dibatalkan = [];

        if ($totalHari <= 5) {
            for ($i = 0; $i < $totalHari; $i++) {
                $tgl = $mulai->copy()->addDays($i);
                $kunciTgl = $tgl->format('Y-m-d');
                $labels[] = $tgl->day.' '.self::BULAN[$tgl->month - 1];

                $item = $pesanan->filter(
                    fn (Pesanan $p): bool => optional($p->dibuat_pada)->format('Y-m-d') === $kunciTgl
                );

                $selesai[] = $item->where('status_pesanan', Pesanan::SELESAI)->count();
                $berlangsung[] = $item->whereIn('status_pesanan', self::STATUS_BERLANGSUNG)->count();
                $dibatalkan[] = $item->where('status_pesanan', Pesanan::DIBATALKAN)->count();
            }
        } else {
            $lebarHari = $totalHari / $jumlahKelompok;
            for ($i = 0; $i < $jumlahKelompok; $i++) {
                $awalKelompok = $mulai->copy()->addDays((int) floor($i * $lebarHari))->startOfDay();
                $akhirKelompok = ($i === $jumlahKelompok - 1)
                    ? $akhir->copy()
                    : $mulai->copy()->addDays((int) floor(($i + 1) * $lebarHari) - 1)->endOfDay();

                if ($akhirKelompok->lt($awalKelompok)) {
                    $akhirKelompok = $awalKelompok->copy()->endOfDay();
                }

                $labels[] = $awalKelompok->day.' '.self::BULAN[$awalKelompok->month - 1]
                    .'–'.$akhirKelompok->day.' '.self::BULAN[$akhirKelompok->month - 1];

                $item = $pesanan->filter(function (Pesanan $p) use ($awalKelompok, $akhirKelompok): bool {
                    if (!$p->dibuat_pada) {
                        return false;
                    }

                    return $p->dibuat_pada->betweenIncluded($awalKelompok, $akhirKelompok);
                });

                $selesai[] = $item->where('status_pesanan', Pesanan::SELESAI)->count();
                $berlangsung[] = $item->whereIn('status_pesanan', self::STATUS_BERLANGSUNG)->count();
                $dibatalkan[] = $item->where('status_pesanan', Pesanan::DIBATALKAN)->count();
            }
        }

        $rentang = $mulai->toDateString() === $akhir->toDateString()
            ? $this->tanggalIndonesia($mulai)
            : $this->tanggalIndonesia($mulai).' – '.$this->tanggalIndonesia($akhir);

        return $this->susunPaketPeriode(
            $rentang,
            $pesanan,
            $teknisiAktif,
            $labels,
            $selesai,
            $berlangsung,
            $dibatalkan
        );
    }

    /**
     * @param  Collection<int, Pesanan>  $koleksiPesanan
     * @param  array<int, string>  $labels
     * @param  array<int, int>  $selesai
     * @param  array<int, int>  $berlangsung
     * @param  array<int, int>  $dibatalkan
     * @return array<string, mixed>
     */
    private function susunPaketPeriode(
        string $rentang,
        Collection $koleksiPesanan,
        int $teknisiAktif,
        array $labels,
        array $selesai,
        array $berlangsung,
        array $dibatalkan
    ): array {
        $pesananSelesai = $koleksiPesanan->where('status_pesanan', Pesanan::SELESAI);
        $totalNilai = (float) $pesananSelesai->sum(fn (Pesanan $p): float => (float) $p->total_biaya);

        return [
            'rentang' => $rentang,
            'ringkasan' => [
                'pesanan' => $koleksiPesanan->count(),
                'selesai' => $pesananSelesai->count(),
                'nilai' => $totalNilai,
                'teknisi' => $teknisiAktif,
            ],
            'grafik' => [
                'labels' => $labels,
                'selesai' => $selesai,
                'berlangsung' => $berlangsung,
                'dibatalkan' => $dibatalkan,
            ],
        ];
    }

    private function formatStatusTabel(string $statusPesanan): string
    {
        if ($statusPesanan === Pesanan::SELESAI) {
            return 'Selesai';
        }

        if ($statusPesanan === Pesanan::DIBATALKAN) {
            return 'Dibatalkan';
        }

        return 'Berlangsung';
    }

    private function namaLayananPesanan(Pesanan $pesanan): string
    {
        $detailLayanan = $pesanan->detail->firstWhere('jenis_item', DetailPesanan::JENIS_LAYANAN);
        if ($detailLayanan?->layanan?->nama_layanan) {
            return $detailLayanan->layanan->nama_layanan;
        }
        if ($detailLayanan?->nama_item) {
            return $detailLayanan->nama_item;
        }
        if (is_array($pesanan->detail_layanan) && !empty($pesanan->detail_layanan['jenis_pekerjaan'])) {
            return (string) $pesanan->detail_layanan['jenis_pekerjaan'];
        }

        $parts = array_filter([
            $pesanan->jenis_ac ? 'AC '.$pesanan->jenis_ac : null,
            $pesanan->pk ? $pesanan->pk.' PK' : null,
        ]);

        return !empty($parts) ? implode(' ', $parts) : 'Layanan AC';
    }

public function index(Request $request): View
    {
        $periode = $this->dataPeriode();
        $teknisiAktif = $periode['30hari']['ringkasan']['teknisi'] ?? 0;

        $dari = (string) $request->query('dari', '');
        $sampai = (string) $request->query('sampai', '');
        $kustom = ($dari !== '' && $sampai !== '')
            ? $this->dataKustom($dari, $sampai, (int) $teknisiAktif)
            : null;

        if ($kustom !== null) {
            $periode['kustom'] = $kustom;
        }

        $pesananTerbaru = Pesanan::query()
            ->with([
                'pelanggan',
                'teknisi.pengguna',
                'detail' => fn ($q) => $q->where('jenis_item', DetailPesanan::JENIS_LAYANAN)->with('layanan'),
            ])
            ->orderByDesc('dibuat_pada')
            ->limit(8)
            ->get();

        $transaksi = $pesananTerbaru->map(function (Pesanan $p): array {
            $waktu = $p->dibuat_pada ? Carbon::parse($p->dibuat_pada) : null;

            return [
                'id' => (string) $p->id_pesanan,
                'kode' => $p->kode ?: (string) $p->id_pesanan,
                'tanggal' => $waktu ? $this->tanggalIndonesia($waktu) : '-',
                'jam' => $waktu ? $waktu->format('H.i') : '-',
                'pelanggan' => $p->pelanggan?->nama ?? 'Pelanggan',
                'teknisi' => $p->teknisi?->pengguna?->nama ?? 'Belum ditugaskan',
                'layanan' => $this->namaLayananPesanan($p),
                'harga' => (float) $p->total_biaya,
                'status' => $this->formatStatusTabel((string) $p->status_pesanan),
            ];
        })->values()->all();

        return view('admin.dashboard', [
            'periode' => $periode,
            'transaksi' => $transaksi,
            'teknisiMenungguVerifikasi' => self::teknisiMenunggu(),
            'jumlahPengaduanBaru' => self::jumlahPengaduanBaru(),
            'jumlahPengajuanMenunggu' => self::jumlahPengajuanMenunggu(),
            'kustomAktif' => $kustom !== null,
            'kustomDariAwal' => $kustom !== null ? $dari : '',
            'kustomSampaiAwal' => $kustom !== null ? $sampai : '',
        ]);
    }
}
