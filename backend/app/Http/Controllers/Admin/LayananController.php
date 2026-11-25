<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Layanan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LayananController extends Controller
{
    private const DEFAULT_PERSENTASE_PLATFORM = 10;

    private static function keLabelStatus(?string $statusDb): string
    {
        return strtolower((string) $statusDb) === 'aktif' ? 'Aktif' : 'Tidak Aktif';
    }

    private static function keStatusDb(string $labelStatus): string
    {
        return $labelStatus === 'Aktif' ? 'aktif' : 'nonaktif';
    }

    /**
     * Katalog layanan dari database.
     *
     * @return array<int, array<string, mixed>>
     */
    public static function daftarLayanan(): array
    {
        $items = Layanan::query()
            ->withCount('detailPesanan')
            ->orderBy('id_layanan')
            ->get();

        return $items->map(function (Layanan $item): array {
            $harga = (float) $item->harga;
            $durasiMenit = (int) ($item->estimasi_durasi ?? 0);

            return [
                'id' => (int) $item->id_layanan,
                'nama' => (string) $item->nama_layanan,
                'deskripsi' => (string) ($item->deskripsi_layanan ?? ''),
                'harga' => $harga,
                'harga_min' => $harga,
                'harga_max' => $harga,
                'durasi' => $durasiMenit,
                'estimasi_durasi' => $durasiMenit,
                'persentase_platform' => (float) ($item->persentase_platform ?? self::DEFAULT_PERSENTASE_PLATFORM),
                'icon' => 'lucide:wrench',
                'warna' => 'bg-brand-50 text-brand-dark',
                'status' => self::keLabelStatus($item->status_layanan),
                'total_pesanan' => (int) ($item->detail_pesanan_count ?? 0),
            ];
        })->values()->all();
    }

    /**
     * Simpan seluruh katalog hasil perubahan (tambah, ubah, hapus, status) ke database.
     */
    public function sinkron(Request $request): JsonResponse
    {
        $data = $request->validate([
            'layanan' => ['present', 'array', 'max:200'],
            'layanan.*.id' => ['required'],
            'layanan.*.nama' => ['required', 'string', 'max:100'],
            'layanan.*.deskripsi' => ['nullable', 'string', 'max:1000'],
            'layanan.*.harga' => ['nullable', 'numeric', 'min:0'],
            'layanan.*.harga_min' => ['nullable', 'numeric', 'min:0'],
            'layanan.*.harga_max' => ['nullable', 'numeric', 'min:0'],
            'layanan.*.durasi' => ['nullable'],
            'layanan.*.estimasi_durasi' => ['nullable', 'integer', 'min:0'],
            'layanan.*.persentase_platform' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'layanan.*.status' => ['required', 'in:Aktif,Tidak Aktif'],
            'layanan.*.total_pesanan' => ['nullable', 'integer', 'min:0'],
        ]);

        $daftarAda = Layanan::query()->get()->keyBy('id_layanan');
        $idDipertahankan = [];

        DB::transaction(function () use ($data, $daftarAda, &$idDipertahankan): void {
            foreach ($data['layanan'] as $item) {
                $nama = trim((string) $item['nama']);
                $deskripsi = trim((string) ($item['deskripsi'] ?? ''));

                $hargaMentah = $item['harga']
                    ?? $item['harga_min']
                    ?? $item['harga_max']
                    ?? 0;
                $harga = max(0, (float) $hargaMentah);

                $durasiMentah = $item['estimasi_durasi'] ?? ($item['durasi'] ?? 0);
                $durasiMenit = max(0, (int) preg_replace('/\D+/', '', (string) $durasiMentah));

                $statusDb = self::keStatusDb((string) $item['status']);

                $idAngka = is_numeric($item['id']) ? (int) $item['id'] : 0;
                /** @var Layanan|null $model */
                $model = $idAngka > 0 ? $daftarAda->get($idAngka) : null;

                if ($model) {
                    $model->update([
                        'nama_layanan' => $nama,
                        'deskripsi_layanan' => $deskripsi !== '' ? $deskripsi : null,
                        'harga' => $harga,
                        'estimasi_durasi' => $durasiMenit,
                        'status_layanan' => $statusDb,
                    ]);
                    $idDipertahankan[] = (int) $model->id_layanan;
                } else {
                    $baru = Layanan::query()->create([
                        'nama_layanan' => $nama,
                        'deskripsi_layanan' => $deskripsi !== '' ? $deskripsi : null,
                        'harga' => $harga,
                        'estimasi_durasi' => $durasiMenit,
                        'persentase_platform' => isset($item['persentase_platform'])
                            ? (float) $item['persentase_platform']
                            : self::DEFAULT_PERSENTASE_PLATFORM,
                        'status_layanan' => $statusDb,
                    ]);
                    $idDipertahankan[] = (int) $baru->id_layanan;
                }
            }

            $idHapus = $daftarAda->keys()
                ->map(fn ($id) => (int) $id)
                ->reject(fn (int $id) => in_array($id, $idDipertahankan, true))
                ->values()
                ->all();

            if (! empty($idHapus)) {
                Layanan::query()->whereIn('id_layanan', $idHapus)->delete();
            }
        });

        return response()->json([
            'ok' => true,
            'layanan' => self::daftarLayanan(),
        ]);
    }

    public function index()
    {
        $layanan = self::daftarLayanan();

        return view('admin.kelola-layanan', compact('layanan'));
    }
}
