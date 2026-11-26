<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DetailPesanan;
use App\Models\Pendapatan;
use App\Models\PengajuanDana;
use App\Models\Teknisi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Dompet teknisi: saldo dari tabel `pendapatan`, riwayat pekerjaan selesai,
 * dan pengajuan pencairan (ditransfer manual oleh Admin).
 */
class DompetController extends Controller
{
    /** Batas "hari ini" mengikuti waktu Batam, bukan UTC server. */
    private const ZONA_WAKTU = 'Asia/Jakarta';

    public const LABEL_STATUS = [
        'menunggu' => 'Menunggu',
        'disetujui' => 'Diproses',
        'selesai_ditransfer' => 'Ditransfer',
        'ditolak' => 'Ditolak',
    ];

    public function dompet(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->ringkasan($this->teknisi($request))]);
    }

    /** Pekerjaan selesai beserta pendapatan bersih, terbaru dulu. */
    public function riwayat(Request $request): JsonResponse
    {
        $halaman = Pendapatan::query()
            ->where('id_teknisi', $this->teknisi($request)->id_pengguna)
            ->with(['pesanan.lokasi', 'pesanan.pelanggan', 'pesanan.ratingUlasan', 'pesanan.detail'])
            ->latest('dibuat_pada')->latest('id_pendapatan')
            ->paginate(20);

        return response()->json([
            'data' => $halaman->getCollection()->map(function (Pendapatan $p) {
                $pesanan = $p->pesanan;
                $layanan = $pesanan->detail->firstWhere('jenis_item', DetailPesanan::JENIS_LAYANAN);

                return [
                    'id_pesanan' => $pesanan->id_pesanan,
                    'kode' => $pesanan->kode,
                    'layanan' => $layanan?->nama_item,
                    'nama_pelanggan' => $pesanan->pelanggan?->nama,
                    'wilayah' => $pesanan->lokasi?->label_alamat,
                    'selesai_pada' => ($pesanan->selesai_pada ?? $p->dibuat_pada)?->toIso8601String(),
                    'total_dibayar' => (int) round((float) $p->pendapatan_platform + (float) $p->pendapatan_teknisi),
                    'potongan_platform' => (int) round((float) $p->pendapatan_platform),
                    'persentase_platform' => (float) $p->persentase_platform,
                    'diterima' => (int) round((float) $p->pendapatan_teknisi),
                    'rating' => $pesanan->ratingUlasan?->rating,
                ];
            })->values(),
            'meta' => ['halaman' => $halaman->currentPage(), 'halaman_terakhir' => $halaman->lastPage()],
        ]);
    }

    public function ajukanPencairan(Request $request): JsonResponse
    {
        $data = $request->validate(
            ['nominal' => ['required', 'integer', 'min:'.PengajuanDana::MINIMUM_PENCAIRAN]],
            [
                'required' => 'Nominal pencairan wajib diisi.',
                'integer' => 'Nominal pencairan harus berupa angka.',
                'min' => 'Minimal pencairan Rp50.000.',
            ],
        );
        $teknisi = $this->teknisi($request);

        if (! $teknisi->nama_bank || ! $teknisi->no_rekening || ! $teknisi->atas_nama) {
            return response()->json([
                'message' => 'Lengkapi data rekening di profil sebelum mencairkan saldo.',
                'kode' => 'rekening_belum_lengkap',
            ], 422);
        }

        $galat = DB::transaction(function () use ($teknisi, $data) {
            // Kunci baris teknisi supaya dua pengajuan bersamaan tidak
            // bisa melebihi saldo.
            Teknisi::query()->whereKey($teknisi->id_pengguna)->lockForUpdate()->first();
            if ($data['nominal'] > $teknisi->saldo()) {
                return 'Nominal melebihi saldo yang bisa dicairkan.';
            }

            PengajuanDana::create([
                'jenis' => PengajuanDana::PENCAIRAN,
                'id_pemohon' => $teknisi->id_pengguna,
                'nominal' => $data['nominal'],
                // Rekening disalin: perubahan profil tidak mengubah pengajuan lama.
                'nama_bank' => $teknisi->nama_bank,
                'no_rekening' => $teknisi->no_rekening,
                'atas_nama' => $teknisi->atas_nama,
            ]);

            return null;
        });

        if ($galat) {
            return response()->json(['message' => $galat, 'kode' => 'saldo_tidak_cukup'], 422);
        }

        return response()->json(['data' => $this->ringkasan($teknisi)], 201);
    }

    private function teknisi(Request $request): Teknisi
    {
        return $request->user()->teknisi()->firstOrFail();
    }

    private function ringkasan(Teknisi $teknisi): array
    {
        $awalHari = Carbon::now(self::ZONA_WAKTU)->startOfDay()->setTimezone(config('app.timezone'));

        return [
            'saldo' => (int) floor($teknisi->saldo()),
            'pendapatan_hari_ini' => (int) round((float) $teknisi->pendapatan()
                ->where('dibuat_pada', '>=', $awalHari)->sum('pendapatan_teknisi')),
            'total_pendapatan' => (int) round((float) $teknisi->pendapatan()->sum('pendapatan_teknisi')),
            'minimum_pencairan' => PengajuanDana::MINIMUM_PENCAIRAN,
            'rekening' => $teknisi->no_rekening ? [
                'nama_bank' => $teknisi->nama_bank,
                'no_rekening' => $teknisi->no_rekening,
                'atas_nama' => $teknisi->atas_nama,
            ] : null,
            'pencairan' => PengajuanDana::query()
                ->where('jenis', PengajuanDana::PENCAIRAN)
                ->where('id_pemohon', $teknisi->id_pengguna)
                ->latest('dibuat_pada')->latest('id_pengajuan')
                ->limit(20)->get()
                ->map(fn (PengajuanDana $p) => [
                    'id' => $p->id_pengajuan,
                    'kode' => 'WD-'.str_pad((string) $p->id_pengajuan, 6, '0', STR_PAD_LEFT),
                    'nominal' => (int) round((float) $p->nominal),
                    'status' => $p->status,
                    'label_status' => self::LABEL_STATUS[$p->status] ?? $p->status,
                    'rekening' => "{$p->nama_bank} • {$p->no_rekening} a.n {$p->atas_nama}",
                    'alasan_penolakan' => $p->alasan_penolakan,
                    'diajukan_pada' => $p->dibuat_pada?->toIso8601String(),
                    'diproses_pada' => $p->diproses_pada?->toIso8601String(),
                ])->values(),
        ];
    }
}
