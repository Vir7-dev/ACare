<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DokumenVerifikasi;
use App\Models\Pengguna;
use App\Models\Pesanan;
use App\Models\Teknisi;
use App\Support\StatusAdmin;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PenggunaController extends Controller
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    private static function formatTanggalWaktu(?Carbon $waktu): string
    {
        if (! $waktu) {
            return '- 00:00';
        }

        return $waktu->day.' '.self::BULAN[$waktu->month - 1].' '.$waktu->year.' '.$waktu->format('H:i');
    }

    private static function formatLabelPeran(string $role): string
    {
        return strtolower($role) === Pengguna::ROLE_TEKNISI ? 'Teknisi' : 'Pengguna';
    }

    private static function formatStatusPesanan(string $status): string
    {
        return match ($status) {
            Pesanan::SELESAI => 'Selesai',
            Pesanan::DIBATALKAN => 'Dibatalkan',
            default => 'Berlangsung',
        };
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public static function daftarPengguna(): array
    {
        $dokumenTersimpan = StatusAdmin::ambil('dokumen') ?? [];

        $penggunaList = Pengguna::query()
            ->whereIn('role', [Pengguna::ROLE_PELANGGAN, Pengguna::ROLE_TEKNISI])
            ->with([
                'teknisi.dokumen',
                'lokasi',
                'pesanan' => fn ($q) => $q->with('teknisi.pengguna')->orderByDesc('dibuat_pada')->limit(10),
            ])
            ->orderByDesc('dibuat_pada')
            ->get();

        return $penggunaList->map(function (Pengguna $u) use ($dokumenTersimpan): array {
            $isTeknisi = $u->role === Pengguna::ROLE_TEKNISI;
            $teknisi = $u->teknisi;

            $lokasiUtama = $u->lokasi->first();
            $alamat = $lokasiUtama?->alamat_lengkap ?: ($lokasiUtama?->label_alamat ?: '-');

            $statusVerifikasi = $isTeknisi
                ? ($teknisi?->status_verifikasi ?? 'menunggu')
                : 'terverifikasi';

            $dokumen = [];
            if ($isTeknisi && $teknisi) {
                $dokumen = $teknisi->dokumen->map(function (DokumenVerifikasi $d) use ($u, $teknisi, $dokumenTersimpan): array {
                    $kunci = $u->id_pengguna.':'.$d->id_dokumen;
                    $statusTersimpan = $dokumenTersimpan[$kunci] ?? null;

                    $status = $statusTersimpan
                        ?? ($teknisi->status_verifikasi === 'terverifikasi' ? 'valid' : 'menunggu');

                    $namaFile = $d->path_file ? basename((string) $d->path_file) : 'dokumen-'.$d->id_dokumen;
                    $labelJenis = $d->jenis_dokumen ?: 'Dokumen Verifikasi';

                    $catatan = match ($status) {
                        'valid' => 'Telah diperiksa: berkas asli dan valid',
                        'tidak_valid' => 'Telah diperiksa: perlu perbaikan atau buram',
                        default => 'Menunggu pengecekan kelayakan berkas',
                    };

                    return [
                        'id' => (string) $d->id_dokumen,
                        'nama' => $labelJenis,
                        'file' => $namaFile,
                        'path' => $d->path_file,
                        'deskripsi' => $labelJenis,
                        'status' => $status,
                        'catatan' => $catatan,
                    ];
                })->values()->all();
            }

            $riwayatOrder = $u->pesanan->map(function (Pesanan $p): array {
                return [
                    'id' => $p->kode,
                    'layanan' => $p->jenis_ac
                        ? 'AC '.$p->jenis_ac.($p->pk ? ' '.$p->pk.' PK' : '')
                        : 'Layanan AC',
                    'tgl' => $p->dibuat_pada
                        ? $p->dibuat_pada->day.' '.self::BULAN[$p->dibuat_pada->month - 1].' '.$p->dibuat_pada->year
                        : '-',
                    'biaya' => 'Rp '.number_format((float) $p->total_biaya, 0, ',', '.'),
                    'teknisi' => $p->teknisi?->pengguna?->nama ?? 'Belum ditugaskan',
                    'status' => self::formatStatusPesanan((string) $p->status_pesanan),
                ];
            })->values()->all();

            $kendaraan = null;
            if ($isTeknisi && $teknisi) {
                $bagianKendaraan = array_filter([
                    $teknisi->jenis_kendaraan ?: null,
                    $teknisi->plat_nomor ? '('.$teknisi->plat_nomor.')' : null,
                ]);
                $kendaraan = ! empty($bagianKendaraan) ? implode(' ', $bagianKendaraan) : null;
            }

            $dibuat = $u->dibuat_pada ? Carbon::parse($u->dibuat_pada) : null;

            return [
                'id' => (string) $u->id_pengguna,
                'nama' => $u->nama,
                'email' => $u->email ?: '-',
                'telepon' => $u->no_telepon ?: '-',
                'alamat' => $alamat,
                'peran' => self::formatLabelPeran((string) $u->role),
                'status_verifikasi' => $statusVerifikasi,
                'tanggal_daftar' => self::formatTanggalWaktu($dibuat),
                'sejak_tanggal' => self::formatTanggalWaktu($dibuat),
                'kendaraan' => $kendaraan,
                'keahlian' => $isTeknisi ? ($teknisi?->deskripsi ?: null) : null,
                'alasan_penolakan' => $isTeknisi ? $teknisi?->alasan_penolakan : null,
                'dokumen' => $dokumen,
                'riwayat_order' => $riwayatOrder,
            ];
        })->values()->all();
    }

    /**
     * Ubah status verifikasi teknisi (juga dipakai untuk membatalkan).
     */
    public function ubahStatus(Request $request): JsonResponse
    {
        $data = $request->validate([
            'perubahan' => ['required', 'array', 'min:1', 'max:50'],
            'perubahan.*.id' => ['required'],
            'perubahan.*.status' => ['required', 'in:menunggu,terverifikasi,ditolak'],
            'perubahan.*.alasan' => ['nullable', 'string', 'max:1000'],
            'massal' => ['sometimes', 'boolean'],
        ]);

        $ids = collect($data['perubahan'])->pluck('id')->map(fn ($v) => (int) $v)->unique()->values();
        $teknisiMap = Teknisi::query()
            ->with(['pengguna', 'dokumen'])
            ->whereIn('id_pengguna', $ids)
            ->get()
            ->keyBy('id_pengguna');

        $dokumenTersimpan = StatusAdmin::ambil('dokumen') ?? [];

        foreach ($data['perubahan'] as $ubah) {
            $idTeknisi = (int) $ubah['id'];
            $teknisi = $teknisiMap->get($idTeknisi);

            if (! $teknisi || ! $teknisi->pengguna || $teknisi->pengguna->role !== Pengguna::ROLE_TEKNISI) {
                return response()->json(['pesan' => 'Hanya teknisi yang memiliki status verifikasi.'], 422);
            }

            if ($ubah['status'] === 'ditolak' && trim((string) ($ubah['alasan'] ?? '')) === '') {
                return response()->json(['pesan' => 'Alasan penolakan wajib diisi.'], 422);
            }

            if (($data['massal'] ?? false) && $ubah['status'] === 'terverifikasi') {
                $dokumenKosong = $teknisi->dokumen->isEmpty();
                $adaYangTidakValid = $teknisi->dokumen->contains(function (DokumenVerifikasi $d) use ($idTeknisi, $dokumenTersimpan): bool {
                    $statusDok = $dokumenTersimpan[$idTeknisi.':'.$d->id_dokumen] ?? 'menunggu';

                    return $statusDok !== 'valid';
                });

                if ($dokumenKosong || $adaYangTidakValid) {
                    return response()->json([
                        'pesan' => ($teknisi->pengguna->nama ?? 'Teknisi').' belum memiliki semua dokumen berstatus valid. Tinjau satu per satu.',
                    ], 422);
                }
            }
        }

        $adminId = session('admin_id')
            ?? \App\Models\Pengguna::query()->where('role', Pengguna::ROLE_ADMIN)->value('id_pengguna');
        $waktuSekarang = now();

        foreach ($data['perubahan'] as $ubah) {
            $idTeknisi = (int) $ubah['id'];
            $teknisi = $teknisiMap->get($idTeknisi);
            if (! $teknisi) {
                continue;
            }

            $statusBaru = $ubah['status'];
            $teknisi->status_verifikasi = $statusBaru;
            $teknisi->diverifikasi_oleh = $adminId;
            $teknisi->diverifikasi_pada = $waktuSekarang;

            if ($statusBaru === 'ditolak') {
                $teknisi->alasan_penolakan = trim((string) ($ubah['alasan'] ?? ''));
            } else {
                $teknisi->alasan_penolakan = null;
            }

            $teknisi->save();
        }

        return response()->json(['ok' => true, 'menunggu' => count(self::teknisiMenunggu())]);
    }

    /**
     * Tandai hasil pemeriksaan satu dokumen teknisi.
     */
    public function ubahDokumen(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => ['required'],
            'dokumen_id' => ['required'],
            'status' => ['required', 'in:menunggu,valid,tidak_valid'],
        ]);

        $dokumen = DokumenVerifikasi::query()
            ->where('id_teknisi', (int) $data['id'])
            ->where('id_dokumen', (int) $data['dokumen_id'])
            ->first();

        if (! $dokumen) {
            return response()->json(['pesan' => 'Dokumen tidak ditemukan.'], 404);
        }

        StatusAdmin::simpan('dokumen', ((int) $data['id']).':'.((int) $data['dokumen_id']), $data['status']);

        return response()->json(['ok' => true]);
    }

    public function index(Request $request)
    {
        $penggunaList = self::daftarPengguna();
        $selectedPengguna = $penggunaList[0] ?? null;

        $statusAwal = in_array($request->query('status'), ['menunggu', 'terverifikasi', 'ditolak'], true)
            ? $request->query('status')
            : 'semua';

        return view('admin.kelola-pengguna', [
            'penggunaList' => $penggunaList,
            'selectedPengguna' => $selectedPengguna,
            'statusAwal' => $statusAwal,
        ]);
    }

    /**
     * Teknisi yang masih menunggu verifikasi (id dan nama).
     *
     * @return array<int, array{id: string, nama: string}>
     */
    public static function teknisiMenunggu(): array
    {
        return Teknisi::query()
            ->with('pengguna')
            ->where('status_verifikasi', 'menunggu')
            ->get()
            ->map(fn (Teknisi $t): array => [
                'id' => (string) $t->id_pengguna,
                'nama' => $t->pengguna?->nama ?? 'Teknisi',
            ])
            ->values()
            ->all();
    }
}
