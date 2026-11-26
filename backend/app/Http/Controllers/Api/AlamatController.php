<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\SimpanAlamatRequest;
use App\Http\Resources\LokasiResource;
use App\Models\Lokasi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

/**
 * Alamat tersimpan pelanggan (tabel `lokasi`). Alamat yang sudah pernah
 * dipakai pesanan tidak diubah isinya, supaya riwayat pesanan tetap benar.
 */
class AlamatController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return LokasiResource::collection(
            $request->user()->lokasi()->orderBy('id_lokasi')->get(),
        );
    }

    public function store(SimpanAlamatRequest $request): JsonResponse
    {
        $lokasi = $request->user()->lokasi()->create($this->data($request));

        return (new LokasiResource($lokasi))->response()->setStatusCode(201);
    }

    /**
     * Ubah alamat. Bila alamat itu sudah dipakai pesanan, perubahan disimpan
     * sebagai alamat baru dan yang lama disembunyikan; aplikasi menerima id baru.
     */
    public function update(SimpanAlamatRequest $request, int $id): JsonResponse
    {
        $lokasi = $this->milik($request, $id);

        if (! $lokasi->sudahDipakai()) {
            $lokasi->update($this->data($request));

            return (new LokasiResource($lokasi))->response();
        }

        $baru = DB::transaction(function () use ($request, $lokasi) {
            $baru = $request->user()->lokasi()->create($this->data($request));
            $lokasi->delete();

            return $baru;
        });

        // Bagi aplikasi ini tetap "ubah" (200), walau tersimpan sebagai baris baru.
        return (new LokasiResource($baru))->response()->setStatusCode(200);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $lokasi = $this->milik($request, $id);

        if (! $lokasi->bisaDihapus()) {
            return response()->json([
                'message' => 'Alamat tidak dapat dihapus karena sedang digunakan pada pesanan aktif.',
                'kode' => 'alamat_dipakai',
            ], 422);
        }

        $lokasi->delete();

        return response()->json(['message' => 'Alamat dihapus.']);
    }

    private function milik(Request $request, int $id): Lokasi
    {
        return $request->user()->lokasi()->whereKey($id)->firstOrFail();
    }

    private function data(SimpanAlamatRequest $request): array
    {
        return [
            'label_alamat' => $request->validated('label'),
            'alamat_lengkap' => $request->validated('alamat_lengkap'),
            'latitude' => $request->validated('latitude'),
            'longitude' => $request->validated('longitude'),
        ];
    }
}
