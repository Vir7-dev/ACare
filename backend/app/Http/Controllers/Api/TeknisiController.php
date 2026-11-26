<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\AjukanBiayaRequest;
use App\Http\Requests\Api\SelesaiPekerjaanRequest;
use App\Http\Resources\PekerjaanTeknisiResource;
use App\Models\FotoBuktiPengerjaan;
use App\Models\Pesanan;
use App\Models\Teknisi;
use App\Services\AlurPesanan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Alur kerja teknisi: status online & lokasi, tawaran pesanan, lalu
 * menuju → tiba → pengecekan → (biaya tambahan) → dikerjakan → selesai.
 */
class TeknisiController extends Controller
{
    private const RELASI = ['detail.layanan', 'lokasi', 'pelanggan', 'fotoBukti'];

    public function __construct(private AlurPesanan $alur) {}

    // ---------- Status & lokasi ----------

    public function status(Request $request): JsonResponse
    {
        $data = $request->validate([
            'online' => ['required', 'boolean'],
            'latitude' => ['required_if:online,true', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['required_if:online,true', 'nullable', 'numeric', 'between:-180,180'],
        ], [
            'required_if' => 'Lokasi dibutuhkan untuk mulai menerima pesanan.',
        ]);
        $teknisi = $this->teknisi($request);

        if (! $data['online'] && $this->pekerjaanAktif($teknisi)) {
            return $this->tolak(409, 'masih_ada_pekerjaan',
                'Selesaikan pesanan yang sedang berjalan sebelum offline.');
        }

        $teknisi->update([
            'status_ketersediaan' => $data['online'] ? 'tersedia' : 'tidak_tersedia',
            ...($data['online'] ? $this->lokasiBaru($data) : []),
        ]);

        return response()->json(['data' => $this->ringkasStatus($teknisi)]);
    }

    /** Dikirim berkala selama online, juga untuk pelacakan oleh pelanggan. */
    public function lokasi(Request $request): JsonResponse
    {
        $data = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);
        $teknisi = $this->teknisi($request);
        $teknisi->update($this->lokasiBaru($data));

        return response()->json(['data' => $this->ringkasStatus($teknisi)]);
    }

    // ---------- Tawaran ----------

    /** Tawaran yang sedang menunggu jawaban teknisi ini (atau null). */
    public function tawaran(Request $request): JsonResponse
    {
        $teknisi = $this->teknisi($request);
        $pesanan = Pesanan::query()->where('id_teknisi_ditawari', $teknisi->id_pengguna)
            ->where('status_pesanan', Pesanan::MENCARI_TEKNISI)->first();

        if ($pesanan) {
            $this->alur->perbarui($pesanan);
            $pesanan->refresh();
        }
        if (! $pesanan || (int) $pesanan->id_teknisi_ditawari !== (int) $teknisi->id_pengguna) {
            return response()->json(['data' => null]);
        }

        return response()->json(['data' => new PekerjaanTeknisiResource($pesanan->load(self::RELASI))]);
    }

    public function terima(Request $request, int $id): JsonResponse|PekerjaanTeknisiResource
    {
        $teknisi = $this->teknisi($request);
        $pesanan = Pesanan::query()->findOrFail($id);

        if ($this->pekerjaanAktif($teknisi) || ! $this->alur->terimaTawaran($pesanan, $teknisi)) {
            return $this->tolak(409, 'tawaran_tidak_berlaku',
                'Tawaran ini sudah tidak berlaku. Tunggu tawaran berikutnya.');
        }

        return new PekerjaanTeknisiResource($pesanan->refresh()->load(self::RELASI));
    }

    public function tolakTawaran(Request $request, int $id): JsonResponse
    {
        $this->alur->tolakTawaran(Pesanan::query()->findOrFail($id), $this->teknisi($request));

        return response()->json(['message' => 'Tawaran ditolak.']);
    }

    // ---------- Pekerjaan ----------

    public function pekerjaan(Request $request): JsonResponse
    {
        $pesanan = $this->pekerjaanAktif($this->teknisi($request));
        if ($pesanan) {
            $this->alur->perbarui($pesanan);
        }

        return response()->json([
            'data' => $pesanan ? new PekerjaanTeknisiResource($pesanan->refresh()->load(self::RELASI)) : null,
        ]);
    }

    public function tiba(Request $request, int $id): PekerjaanTeknisiResource
    {
        $pesanan = $this->pekerjaanMilik($request, $id, [Pesanan::MENUJU_LOKASI]);
        $pesanan->update(['status_pesanan' => Pesanan::TIBA, 'tiba_pada' => now()]);

        return new PekerjaanTeknisiResource($pesanan->load(self::RELASI));
    }

    public function mulaiPengecekan(Request $request, int $id): PekerjaanTeknisiResource
    {
        $pesanan = $this->pekerjaanMilik($request, $id, [Pesanan::TIBA]);
        $pesanan->update(['status_pesanan' => Pesanan::PENGECEKAN_AWAL, 'pengecekan_pada' => now()]);

        return new PekerjaanTeknisiResource($pesanan->load(self::RELASI));
    }

    /** Foto kondisi unit saat pengecekan (boleh lebih dari satu). */
    public function fotoPemeriksaan(Request $request, int $id): PekerjaanTeknisiResource
    {
        $request->validate(
            ['foto' => ['required', 'file', 'mimes:jpg,jpeg,png', 'max:5120']],
            ['required' => 'Foto wajib diunggah.', 'mimes' => 'Foto harus berformat jpg atau png.',
                'max' => 'Ukuran foto maksimal 5 MB.'],
        );
        $pesanan = $this->pekerjaanMilik($request, $id, [Pesanan::PENGECEKAN_AWAL, Pesanan::MENUNGGU_PERSETUJUAN_BIAYA]);
        $this->simpanFoto($pesanan, 'pemeriksaan', $request->file('foto'));

        return new PekerjaanTeknisiResource($pesanan->load(self::RELASI));
    }

    public function ajukanBiaya(AjukanBiayaRequest $request, int $id): JsonResponse|PekerjaanTeknisiResource
    {
        $pesanan = $this->pekerjaanMilik($request, $id, [Pesanan::PENGECEKAN_AWAL]);
        $layanan = $pesanan->detail()->where('jenis_item', 'layanan')->first()?->layanan;

        if (! $layanan?->bisaBiayaTambahan()) {
            return $this->tolak(422, 'tanpa_biaya_tambahan',
                'Layanan ini tidak memakai biaya tambahan.');
        }

        $this->alur->ajukanBiaya($pesanan, $request->validated('item'), $request->validated('catatan'));

        return new PekerjaanTeknisiResource($pesanan->refresh()->load(self::RELASI));
    }

    /** Pengecekan selesai tanpa biaya tambahan: langsung dikerjakan. */
    public function tanpaBiaya(Request $request, int $id): PekerjaanTeknisiResource
    {
        $pesanan = $this->pekerjaanMilik($request, $id, [Pesanan::PENGECEKAN_AWAL]);
        $pesanan->update(['status_pesanan' => Pesanan::DIKERJAKAN, 'dikerjakan_pada' => now()]);

        return new PekerjaanTeknisiResource($pesanan->load(self::RELASI));
    }

    /** Unggah bukti kerja dan selesaikan (lanjut ke pelunasan bila ada sisa). */
    public function selesai(SelesaiPekerjaanRequest $request, int $id): PekerjaanTeknisiResource
    {
        $pesanan = $this->pekerjaanMilik($request, $id, [Pesanan::DIKERJAKAN]);

        DB::transaction(function () use ($request, $pesanan) {
            $this->simpanFoto($pesanan, 'sebelum', $request->file('foto_sebelum'));
            $this->simpanFoto($pesanan, 'sesudah', $request->file('foto_sesudah'));
            foreach ($request->file('foto_tambahan', []) as $f) {
                $this->simpanFoto($pesanan, 'tambahan', $f);
            }
            $this->alur->selesaiDikerjakan($pesanan, $request->validated('catatan'));
        });

        return new PekerjaanTeknisiResource($pesanan->refresh()->load(self::RELASI));
    }

    // ---------- Bantuan ----------

    private function teknisi(Request $request): Teknisi
    {
        $teknisi = $request->user()->teknisi;
        if (! $teknisi?->isTerverifikasi()) {
            throw new HttpException(403, 'Akun teknisi belum diverifikasi Admin.');
        }

        return $teknisi;
    }

    private function pekerjaanAktif(Teknisi $teknisi): ?Pesanan
    {
        return Pesanan::query()->where('id_teknisi', $teknisi->id_pengguna)
            ->whereIn('status_pesanan', Pesanan::STATUS_DIKERJAKAN_TEKNISI)->first();
    }

    /**
     * Pesanan milik teknisi ini pada salah satu status yang diizinkan.
     *
     * @param  array<int, string>  $status
     */
    private function pekerjaanMilik(Request $request, int $id, array $status): Pesanan
    {
        $pesanan = Pesanan::query()->where('id_teknisi', $this->teknisi($request)->id_pengguna)
            ->whereKey($id)->firstOrFail();
        $this->alur->perbarui($pesanan);

        if (! in_array($pesanan->status_pesanan, $status, true)) {
            throw new HttpException(409, 'Langkah ini tidak sesuai dengan status pesanan saat ini.');
        }

        return $pesanan;
    }

    private function simpanFoto(Pesanan $pesanan, string $tahap, UploadedFile $foto): void
    {
        $pesanan->fotoBukti()->create([
            'tahap' => $tahap,
            'path_foto' => $foto->store('bukti-pengerjaan/'.$pesanan->id_pesanan, FotoBuktiPengerjaan::DISK),
        ]);
    }

    private function lokasiBaru(array $data): array
    {
        return [
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'lokasi_diperbarui_pada' => now(),
        ];
    }

    private function ringkasStatus(Teknisi $teknisi): array
    {
        return [
            'online' => $teknisi->status_ketersediaan === 'tersedia',
            'latitude' => $teknisi->latitude === null ? null : (float) $teknisi->latitude,
            'longitude' => $teknisi->longitude === null ? null : (float) $teknisi->longitude,
        ];
    }

    private function tolak(int $status, string $kode, string $pesan): JsonResponse
    {
        return response()->json(['message' => $pesan, 'kode' => $kode], $status);
    }

    /** Dipakai rute unduh foto: hanya pelanggan pemilik dan teknisinya. */
    public static function bolehLihatFoto(Request $request, Pesanan $pesanan): bool
    {
        $id = $request->user()->id_pengguna;

        return (int) $pesanan->id_pelanggan === (int) $id || (int) $pesanan->id_teknisi === (int) $id;
    }

    public function foto(Request $request, int $id, int $idFoto)
    {
        $pesanan = Pesanan::query()->findOrFail($id);
        abort_unless(self::bolehLihatFoto($request, $pesanan), 404);
        $foto = $pesanan->fotoBukti()->whereKey($idFoto)->firstOrFail();

        return Storage::disk(FotoBuktiPengerjaan::DISK)->response($foto->path_foto);
    }
}
