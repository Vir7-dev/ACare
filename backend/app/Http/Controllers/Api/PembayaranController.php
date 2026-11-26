<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PesananResource;
use App\Models\Pembayaran;
use App\Models\Pesanan;
use App\Services\AlurPesanan;
use App\Services\Xendit;
use App\Services\XenditException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Tagihan pelanggan: pilih metode lalu bayar lewat Xendit.
 * Status lunas datang dari webhook (XenditWebhookController).
 */
class PembayaranController extends Controller
{
    private const RELASI = ['detail.layanan', 'lokasi', 'pembayaran', 'teknisi.pengguna'];

    public function __construct(private Xendit $xendit, private AlurPesanan $alur) {}

    /** Buat tagihan Xendit dengan metode pilihan; kode QR/VA/tautan ada di `pembayaran[].instruksi`. */
    public function bayar(Request $request, int $id, int $idPembayaran): JsonResponse|PesananResource
    {
        $request->validate(
            ['metode' => ['required', Rule::in(array_keys(Xendit::METODE))]],
            ['required' => 'Pilih metode pembayaran.', 'in' => 'Metode pembayaran tidak tersedia.'],
        );
        [$pesanan, $pembayaran] = $this->tagihan($request, $id, $idPembayaran);

        if ($galat = $this->bukanTagihanAktif($pesanan, $pembayaran)) {
            return $galat;
        }

        if (! $this->xendit->aktif()) {
            return response()->json([
                'message' => 'Pembayaran online belum tersedia. Coba lagi nanti.',
                'kode' => 'pembayaran_belum_siap',
            ], 503);
        }

        try {
            $this->xendit->buatTagihan($pembayaran, $request->input('metode'));
        } catch (XenditException) {
            return response()->json([
                'message' => 'Tagihan belum bisa dibuat. Coba lagi sebentar lagi atau pilih metode lain.',
                'kode' => 'xendit_gagal',
            ], 502);
        }

        return new PesananResource($pesanan->refresh()->load(self::RELASI));
    }

    /**
     * Hanya env local/testing. Bila tagihan sudah dibuat di Xendit, Xendit
     * diminta mensimulasikan pembayaran (hasil lewat webhook). Bila belum,
     * tagihan langsung dianggap lunas tanpa Xendit.
     */
    public function simulasi(Request $request, int $id, int $idPembayaran): JsonResponse|PesananResource
    {
        abort_unless(app()->environment(['local', 'testing']), 404);
        [$pesanan, $pembayaran] = $this->tagihan($request, $id, $idPembayaran);

        if ($pembayaran->status_pembayaran !== Pembayaran::MENUNGGU) {
            return response()->json(['message' => 'Tagihan ini tidak menunggu pembayaran.', 'kode' => 'bukan_tagihan_aktif'], 409);
        }

        if ($this->xendit->aktif() && $pembayaran->referensi_transaksi) {
            try {
                $this->xendit->simulasi($pembayaran);
            } catch (XenditException $e) {
                return response()->json(['message' => 'Simulasi Xendit gagal: '.$e->getMessage(), 'kode' => 'xendit_gagal'], 502);
            }
        } else {
            $this->alur->pembayaranBerhasil($pembayaran, 'SIMULASI');
        }

        return new PesananResource($pesanan->refresh()->load(self::RELASI));
    }

    /** @return array{Pesanan, Pembayaran} */
    private function tagihan(Request $request, int $id, int $idPembayaran): array
    {
        $pesanan = Pesanan::query()
            ->where('id_pelanggan', $request->user()->id_pengguna)
            ->whereKey($id)
            ->firstOrFail();

        return [$pesanan, $pesanan->pembayaran()->whereKey($idPembayaran)->firstOrFail()];
    }

    private function bukanTagihanAktif(Pesanan $pesanan, Pembayaran $pembayaran): ?JsonResponse
    {
        if ($pembayaran->status_pembayaran === Pembayaran::MENUNGGU && $pesanan->status_pesanan !== Pesanan::DIBATALKAN) {
            return null;
        }

        return response()->json(['message' => 'Tagihan ini tidak menunggu pembayaran.', 'kode' => 'bukan_tagihan_aktif'], 409);
    }
}
