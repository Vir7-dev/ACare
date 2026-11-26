<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\BuatPesananRequest;
use App\Http\Resources\PesananResource;
use App\Models\DetailPesanan;
use App\Models\Pembayaran;
use App\Models\Pesanan;
use App\Services\AlurPesanan;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

/**
 * Pesanan milik pelanggan: buat, lihat riwayat dan detail, batalkan.
 *
 * Pesanan baru langsung berstatus `mencari_teknisi` dengan pembayaran awal
 * `menunggu`. Tawaran ke teknisi baru dikirim setelah pembayaran awal
 * berhasil (tahap pembayaran Xendit).
 */
class PesananController extends Controller
{
    private const RELASI = ['detail.layanan', 'lokasi', 'pembayaran', 'teknisi.pengguna'];

    public function __construct(private AlurPesanan $alur) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        // Batas waktu pesanan aktif diperiksa dulu supaya status di daftar terbaru.
        Pesanan::query()->where('id_pelanggan', $request->user()->id_pengguna)->aktif()
            ->get()->each(fn (Pesanan $p) => $this->alur->perbarui($p));

        $request->validate(['status' => ['nullable', 'in:aktif,selesai,dibatalkan']]);

        $pesanan = Pesanan::query()
            ->where('id_pelanggan', $request->user()->id_pengguna)
            ->when($request->input('status'), fn (Builder $q, string $s) => match ($s) {
                'aktif' => $q->aktif(),
                'selesai' => $q->where('status_pesanan', Pesanan::SELESAI),
                'dibatalkan' => $q->where('status_pesanan', Pesanan::DIBATALKAN),
            })
            ->with(self::RELASI)
            ->latest('dibuat_pada')
            ->latest('id_pesanan')
            ->paginate(20);

        return PesananResource::collection($pesanan);
    }

    public function show(Request $request, int $id): PesananResource
    {
        $pesanan = $this->alur->perbarui($this->milik($request, $id));

        return new PesananResource($pesanan->refresh()->load(self::RELASI));
    }

    /** Pelanggan menyetujui atau menolak rincian biaya perbaikan dari teknisi. */
    public function biaya(Request $request, int $id): JsonResponse|PesananResource
    {
        $request->validate(['setuju' => ['required', 'boolean']], ['required' => 'Pilih setuju atau tolak.']);
        $pesanan = $this->alur->perbarui($this->milik($request, $id));

        if ($pesanan->status_pesanan !== Pesanan::MENUNGGU_PERSETUJUAN_BIAYA
            || $pesanan->status_biaya !== Pesanan::BIAYA_MENUNGGU) {
            return response()->json([
                'message' => $pesanan->status_biaya === Pesanan::BIAYA_DITOLAK
                    ? 'Waktu persetujuan sudah habis, pesanan dilanjutkan dengan biaya awal saja.'
                    : 'Tidak ada rincian biaya yang menunggu persetujuan.',
                'kode' => 'tidak_ada_persetujuan',
            ], 409);
        }

        $this->alur->tanggapiBiaya($pesanan, $request->boolean('setuju'));

        return new PesananResource($pesanan->refresh()->load(self::RELASI));
    }

    /**
     * Anggap tagihan lunas tanpa Xendit. Hanya untuk pengembangan dan test;
     * di server sungguhan rute ini tidak ada (404).
     */
    public function simulasiBayar(Request $request, int $id, int $idPembayaran): JsonResponse|PesananResource
    {
        abort_unless(app()->environment(['local', 'testing']), 404);
        $pesanan = $this->milik($request, $id);
        $pembayaran = $pesanan->pembayaran()->whereKey($idPembayaran)->firstOrFail();

        if ($pembayaran->status_pembayaran !== Pembayaran::MENUNGGU) {
            return response()->json(['message' => 'Tagihan ini tidak menunggu pembayaran.', 'kode' => 'bukan_tagihan_aktif'], 409);
        }

        $this->alur->pembayaranBerhasil($pembayaran, 'SIMULASI');

        return new PesananResource($pesanan->refresh()->load(self::RELASI));
    }

    public function store(BuatPesananRequest $request): JsonResponse
    {
        $pengguna = $request->user();

        if (Pesanan::query()->where('id_pelanggan', $pengguna->id_pengguna)->aktif()->exists()) {
            return response()->json([
                'message' => 'Masih ada pesanan yang sedang berjalan. Selesaikan atau batalkan dulu sebelum memesan lagi.',
                'kode' => 'masih_ada_pesanan_aktif',
            ], 409);
        }

        $layanan = $request->layanan();

        $pesanan = DB::transaction(function () use ($request, $pengguna, $layanan) {
            $pesanan = Pesanan::create([
                'id_pelanggan' => $pengguna->id_pengguna,
                'id_lokasi' => $request->validated('id_lokasi'),
                'detail_lokasi' => $request->validated('detail_lokasi'),
                'jadwal_service' => $request->date('jadwal_service'),
                'jenis_ac' => $request->validated('jenis_ac'),
                'pk' => $request->validated('pk'),
                'merek' => $request->validated('merek'),
                'detail_layanan' => $request->detailLayanan() ?: null,
                'catatan_pelanggan' => $request->validated('catatan'),
            ]);

            $pesanan->detail()->create([
                'id_layanan' => $layanan->id_layanan,
                'jenis_item' => DetailPesanan::JENIS_LAYANAN,
                'nama_item' => $layanan->nama_layanan,
                'jumlah' => $request->integer('jumlah_unit'),
                'harga' => $layanan->harga,
            ]);

            $pesanan->update(['total_biaya' => $pesanan->hitungTotalBiaya()]);

            $pesanan->pembayaran()->create([
                'jenis_pembayaran' => Pembayaran::AWAL,
                'jumlah_bayar' => $pesanan->total_biaya,
                'status_pembayaran' => Pembayaran::MENUNGGU,
            ]);

            return $pesanan;
        });

        return (new PesananResource($pesanan->load(self::RELASI)))->response()->setStatusCode(201);
    }

    /** Pelanggan hanya bisa membatalkan selama teknisi belum ditemukan. */
    public function batal(Request $request, int $id): JsonResponse|PesananResource
    {
        $request->validate(['alasan' => ['nullable', 'string', 'max:255']]);
        $pesanan = $this->milik($request, $id);

        if (! $pesanan->bisaDibatalkan()) {
            return response()->json([
                'message' => 'Pesanan tidak bisa dibatalkan karena teknisi sudah ditemukan.',
                'kode' => 'tidak_bisa_dibatalkan',
            ], 422);
        }

        DB::transaction(function () use ($request, $pesanan) {
            $pesanan->update([
                'status_pesanan' => Pesanan::DIBATALKAN,
                'dibatalkan_pada' => now(),
                'alasan_pembatalan' => $request->input('alasan') ?: 'Dibatalkan oleh pelanggan saat mencari teknisi',
            ]);

            // Belum dibayar: tagihan tidak berlaku lagi. Sudah dibayar: dana
            // tertahan sampai pelanggan mengajukan refund.
            foreach ($pesanan->pembayaran as $p) {
                if ($p->status_pembayaran === Pembayaran::MENUNGGU) {
                    $p->update(['status_pembayaran' => Pembayaran::KEDALUWARSA]);
                } elseif ($p->status_pembayaran === Pembayaran::BERHASIL) {
                    $p->update(['status_pembayaran' => Pembayaran::TERTAHAN]);
                }
            }
        });

        return new PesananResource($pesanan->refresh()->load(self::RELASI));
    }

    private function milik(Request $request, int $id): Pesanan
    {
        return Pesanan::query()
            ->where('id_pelanggan', $request->user()->id_pengguna)
            ->whereKey($id)
            ->firstOrFail();
    }
}
