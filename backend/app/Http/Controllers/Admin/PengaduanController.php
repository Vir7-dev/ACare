<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pengaduan;
use App\Models\Pengguna;
use Illuminate\Contracts\View\View;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PengaduanController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    private static function keStatusDb(string $labelStatus): string
    {
        return match ($labelStatus) {
            'Baru' => 'diajukan',
            'Diproses' => 'diproses',
            'Selesai' => 'selesai',
            default => 'diajukan',
        };
    }

    private static function keLabelStatus(?string $statusDb): string
    {
        return match (strtolower((string) $statusDb)) {
            'diajukan', 'baru' => 'Baru',
            'diproses' => 'Diproses',
            'selesai' => 'Selesai',
            default => 'Baru',
        };
    }

    private static function labelPeran(?string $role): string
    {
        return match (strtolower((string) $role)) {
            Pengguna::ROLE_TEKNISI => 'Teknisi',
            Pengguna::ROLE_PELANGGAN => 'Pelanggan',
            default => ucfirst((string) ($role ?: 'Pengguna')),
        };
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public static function daftarPengaduan(): array
    {
        $list = Pengaduan::query()
            ->with(['pelapor', 'pesanan.pelanggan', 'pesanan.teknisi.pengguna'])
            ->orderByDesc('dibuat_pada')
            ->get();

        return $list->map(function (Pengaduan $p): array {
            $waktu = $p->dibuat_pada;
            $tanggal = $waktu
                ? $waktu->day.' '.self::BULAN[$waktu->month - 1].' '.$waktu->year
                : '-';
            $jam = $waktu ? $waktu->format('H:i').' WIB' : '-';

            $terlapor = $p->terlapor();
            $namaTerlapor = $p->isAduanSistem()
                ? 'Sistem & Aplikasi'
                : ($terlapor?->nama ?? '-');

            $deskripsi = (string) ($p->deskripsi ?? '');
            $ringkasan = $deskripsi !== '' ? Str::limit($deskripsi, 90) : '-';

            $orderId = $p->id_pesanan ? (string) $p->id_pesanan : '-';
            
            return [
                'id' => (string) $p->id_pengaduan,
                'tanggal' => $tanggal,
                'jam' => $jam,
                'pelapor' => $p->pelapor?->nama ?? 'Pengguna',
                'peran' => self::labelPeran($p->pelapor?->role),
                'terlapor' => $namaTerlapor,
                'order_id' => $orderId,
                'kategori' => $p->jenis_pengaduan ?: 'Umum',
                'ringkasan' => $ringkasan,
                'deskripsi' => $deskripsi !== '' ? $deskripsi : '-',
                'status' => self::keLabelStatus($p->status_pengaduan),
            ];
        })->values()->all();
    }

    /**
     * Ubah status satu atau beberapa pengaduan (juga dipakai untuk membatalkan).
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required'],
            'perubahan.*.status' => ['required', 'in:Baru,Diproses,Selesai'],
        ]);

        $ids = collect($data['perubahan'])->pluck('id')->map(fn ($v) => (int) $v)->unique()->values();
        $pengaduanMap = Pengaduan::query()
            ->whereIn('id_pengaduan', $ids)
            ->get()
            ->keyBy('id_pengaduan');

        foreach ($data['perubahan'] as $ubah) {
            if (! $pengaduanMap->has((int) $ubah['id'])) {
                return response()->json(['pesan' => 'Pengaduan tidak ditemukan.'], 404);
            }
        }

        $adminId = session('admin_id')
            ?? Pengguna::query()->where('role', Pengguna::ROLE_ADMIN)->value('id_pengguna');
        $sekarang = now();

        foreach ($data['perubahan'] as $ubah) {
            /** @var Pengaduan|null $pengaduan */
            $pengaduan = $pengaduanMap->get((int) $ubah['id']);
            if (! $pengaduan) {
                continue;
            }

            $statusDb = self::keStatusDb($ubah['status']);
            $pengaduan->status_pengaduan = $statusDb;
            $pengaduan->id_admin = $adminId;

            if ($statusDb === 'selesai') {
                $pengaduan->selesai_pada = $sekarang;
            } else {
                $pengaduan->selesai_pada = null;
            }

            $pengaduan->save();
        }

        return response()->json(['ok' => true, 'baru' => self::jumlahBaru()]);
    }

    /**
     * Jumlah pengaduan yang belum ditangani (status_pengaduan = 'diajukan').
     */
    public static function jumlahBaru(): int
    {
        return Pengaduan::query()
            ->where('status_pengaduan', 'diajukan')
            ->count();
    }

    public function index(Request $request): View
    {
        $statusAwal = in_array($request->query('status'), ['Baru', 'Diproses', 'Selesai'], true)
            ? $request->query('status')
            : 'Semua';

        return view('admin.pengaduan', [
            'pengaduanList' => self::daftarPengaduan(),
            'jumlahBaru' => self::jumlahBaru(),
            'statusAwal' => $statusAwal,
        ]);
    }
}
