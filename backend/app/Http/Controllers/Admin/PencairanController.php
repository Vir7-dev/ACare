<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PengajuanDana;
use App\Models\Pengguna;
use App\Models\Pesanan;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PencairanController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    public const STATUS = ['Menunggu', 'Disetujui', 'Selesai Ditransfer', 'Ditolak'];

    private const ALUR = [
        'Menunggu' => ['Disetujui', 'Ditolak'],
        'Disetujui' => ['Selesai Ditransfer', 'Ditolak'],
        'Selesai Ditransfer' => [],
        'Ditolak' => [],
    ];

    private static function keStatusDb(string $labelStatus): string
    {
        return match ($labelStatus) {
            'Menunggu' => 'menunggu',
            'Disetujui' => 'disetujui',
            'Selesai Ditransfer' => 'selesai_ditransfer',
            'Ditolak' => 'ditolak',
            default => 'menunggu',
        };
    }

    private static function keLabelStatus(?string $statusDb): string
    {
        return match (strtolower((string) $statusDb)) {
            'menunggu' => 'Menunggu',
            'disetujui' => 'Disetujui',
            'selesai_ditransfer' => 'Selesai Ditransfer',
            'ditolak' => 'Ditolak',
            default => 'Menunggu',
        };
    }

    private static function formatWaktuTransfer(?\Carbon\CarbonInterface $waktu): ?string
    {
        if (! $waktu) {
            return null;
        }

        return $waktu->day.' '.self::BULAN[$waktu->month - 1].' '.$waktu->year.', '.$waktu->format('H:i').' WIB';
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public static function daftarPengajuan(): array
    {
        $list = PengajuanDana::query()
            ->with(['pemohon', 'pesanan'])
            ->orderByDesc('dibuat_pada')
            ->get();

        return $list->map(function (PengajuanDana $item): array {
            $waktu = $item->dibuat_pada;
            $tanggal = $waktu
                ? $waktu->day.' '.self::BULAN[$waktu->month - 1].' '.$waktu->year
                : '-';
            $jam = $waktu ? $waktu->format('H:i').' WIB' : '-';

            $isPencairan = strtolower((string) $item->jenis) === PengajuanDana::PENCAIRAN;
            $jenisLabel = $isPencairan ? 'Pencairan' : 'Refund';
            $peranLabel = strtolower((string) ($item->pemohon?->role ?? '')) === Pengguna::ROLE_TEKNISI
                ? 'Teknisi'
                : 'Pelanggan';

            $nominal = (float) $item->nominal;
            $pesananTerkait = [];
            if ($item->pesanan) {
                $keteranganPesanan = $item->pesanan->jenis_ac
                    ? 'AC '.$item->pesanan->jenis_ac.($item->pesanan->pk ? ' '.$item->pesanan->pk.' PK' : '')
                    : 'Pesanan AC';
                $pesananTerkait[] = [
                    'id' => (string) $item->pesanan->id_pesanan,
                    'keterangan' => $keteranganPesanan,
                    'nominal' => $nominal,
                ];
            } elseif ($item->id_pesanan) {
                $pesananTerkait[] = [
                    'id' => (string) $item->id_pesanan,
                    'keterangan' => 'Pesanan',
                    'nominal' => $nominal,
                ];
            }

            $statusLabel = self::keLabelStatus($item->status);
            $waktuTransfer = $statusLabel === 'Selesai Ditransfer'
                ? (self::formatWaktuTransfer($item->diproses_pada) ?? '-')
                : null;

            return [
                'id' => (string) $item->id_pengajuan,
                'jenis' => $jenisLabel,
                'tanggal' => $tanggal,
                'jam' => $jam,
                'pemohon' => $item->pemohon?->nama ?? 'Pengguna',
                'peran' => $peranLabel,
                'tujuan' => [
                    'jenis' => 'Bank',
                    'nama' => $item->nama_bank ?: '-',
                    'nomor' => $item->no_rekening ?: '-',
                    'atas_nama' => $item->atas_nama ?: ($item->pemohon?->nama ?? '-'),
                ],
                'pesanan' => $pesananTerkait,
                'alasan_pengajuan' => ! $isPencairan ? ($item->alasan ?: null) : null,
                'nominal' => $nominal,
                'status' => $statusLabel,
                'alasan' => $statusLabel === 'Ditolak' ? ($item->alasan_penolakan ?: '-') : null,
                'referensi' => $statusLabel === 'Selesai Ditransfer' ? 'Tercatat di sistem' : null,
                'waktu_transfer' => $waktuTransfer,
            ];
        })->values()->all();
    }

    /**
     * Jumlah pengajuan yang masih menunggu keputusan Admin.
     */
    public static function jumlahMenunggu(): int
    {
        return PengajuanDana::query()
            ->where('status', 'menunggu')
            ->count();
    }

    /**
     * Ubah status satu atau beberapa pengajuan.
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'pulihkan' => ['sometimes', 'boolean'],
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required'],
            'perubahan.*.status' => ['required', 'in:'.implode(',', self::STATUS)],
            'perubahan.*.alasan' => ['nullable', 'string', 'max:200'],
            'perubahan.*.referensi' => ['nullable', 'string', 'max:60'],
        ]);

        $pulihkan = (bool) ($data['pulihkan'] ?? false);
        $ids = collect($data['perubahan'])->pluck('id')->map(fn ($v) => (int) $v)->unique()->values();
        $pengajuanMap = PengajuanDana::query()
            ->whereIn('id_pengajuan', $ids)
            ->get()
            ->keyBy('id_pengajuan');

        foreach ($data['perubahan'] as $ubah) {
            $idPengajuan = (int) $ubah['id'];
            /** @var PengajuanDana|null $item */
            $item = $pengajuanMap->get($idPengajuan);
            if (! $item) {
                return response()->json(['pesan' => 'Pengajuan tidak ditemukan.'], 404);
            }
            if ($pulihkan) {
                continue;
            }
            $dari = self::keLabelStatus($item->status);
            if (! in_array($ubah['status'], self::ALUR[$dari], true)) {
                return response()->json(['pesan' => 'Pengajuan '.$idPengajuan.' tidak bisa diubah dari '.$dari.' ke '.$ubah['status'].'.'], 422);
            }
            if ($ubah['status'] === 'Ditolak' && trim((string) ($ubah['alasan'] ?? '')) === '') {
                return response()->json(['pesan' => 'Alasan penolakan wajib diisi.'], 422);
            }
            if ($ubah['status'] === 'Selesai Ditransfer' && trim((string) ($ubah['referensi'] ?? '')) === '') {
                return response()->json(['pesan' => 'Referensi transfer wajib diisi.'], 422);
            }
        }

        $adminId = session('admin_id')
            ?? Pengguna::query()->where('role', Pengguna::ROLE_ADMIN)->value('id_pengguna');
        $sekarang = now();

        $hasil = [];
        foreach ($data['perubahan'] as $ubah) {
            $idPengajuan = (int) $ubah['id'];
            /** @var PengajuanDana|null $item */
            $item = $pengajuanMap->get($idPengajuan);
            if (! $item) {
                continue;
            }

            $statusDb = self::keStatusDb($ubah['status']);
            $item->status = $statusDb;
            $item->id_admin = $adminId;
            $item->diproses_pada = $sekarang;

            if ($statusDb === 'ditolak') {
                $item->alasan_penolakan = trim((string) ($ubah['alasan'] ?? ''));
            } elseif ($statusDb === 'menunggu') {
                $item->alasan_penolakan = null;
                $item->diproses_pada = null;
            } else {
                $item->alasan_penolakan = null;
            }

            $item->save();

            $statusLabel = self::keLabelStatus($item->status);
            $referensiInput = trim((string) ($ubah['referensi'] ?? ''));

            $hasil[(string) $idPengajuan] = [
                'status' => $statusLabel,
                'alasan' => $statusLabel === 'Ditolak' ? $item->alasan_penolakan : null,
                'referensi' => $statusLabel === 'Selesai Ditransfer' ? ($referensiInput !== '' ? $referensiInput : null) : null,
                'waktu_transfer' => $statusLabel === 'Selesai Ditransfer' ? self::formatWaktuTransfer($item->diproses_pada) : null,
            ];
        }

        return response()->json(['ok' => true, 'menunggu' => self::jumlahMenunggu(), 'catatan' => $hasil]);
    }

    public function index(Request $request): View
    {
        $statusAwal = in_array($request->query('status'), self::STATUS, true)
            ? $request->query('status')
            : 'Semua';

        $idTransaksi = Pesanan::query()
            ->orderByDesc('id_pesanan')
            ->limit(100)
            ->pluck('id_pesanan')
            ->map(fn ($id): string => (string) $id)
            ->values()
            ->all();

        return view('admin.pencairan-refund', [
            'pengajuanList' => self::daftarPengajuan(),
            'statusAwal' => $statusAwal,
            'idTransaksi' => $idTransaksi,
        ]);
    }
}
