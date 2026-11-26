<?php

namespace App\Services;

use App\Models\Pembayaran;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Tagihan pelanggan lewat Xendit Payment Request API v3.
 *
 * Satu baris `pembayaran` bisa dibuatkan beberapa payment request (misal
 * pelanggan ganti metode). Semuanya membawa reference_id yang sama
 * (`pembayaran-{id}`), jadi webhook dari payment request lama tetap
 * dikenali. Status lunas hanya dipercaya dari Xendit (webhook atau
 * pemeriksaan status ke Xendit), tidak pernah dari aplikasi.
 */
class Xendit
{
    public const VERSI_API = '2024-11-11';

    /** Batas waktu kode QRIS dan nomor Virtual Account. */
    public const BATAS_MENIT = 30;

    /** Jeda minimal antar pemeriksaan status ke Xendit untuk satu tagihan. */
    private const JEDA_PERIKSA_DETIK = 5;

    /**
     * Metode yang ditawarkan di aplikasi. Kunci = channel_code Xendit.
     * jenis: qr (tampilkan kode QR), va (tampilkan nomor), ewallet (buka tautan).
     */
    public const METODE = [
        'QRIS' => ['nama' => 'QRIS', 'jenis' => 'qr'],
        'BNI_VIRTUAL_ACCOUNT' => ['nama' => 'BNI Virtual Account', 'jenis' => 'va'],
        'BRI_VIRTUAL_ACCOUNT' => ['nama' => 'BRI Virtual Account', 'jenis' => 'va'],
        'MANDIRI_VIRTUAL_ACCOUNT' => ['nama' => 'Mandiri Virtual Account', 'jenis' => 'va'],
        'DANA' => ['nama' => 'DANA', 'jenis' => 'ewallet'],
        'SHOPEEPAY' => ['nama' => 'ShopeePay', 'jenis' => 'ewallet'],
    ];

    public function __construct(private AlurPesanan $alur) {}

    /** Kunci Xendit sudah diisi di .env. */
    public function aktif(): bool
    {
        return filled(config('services.xendit.secret_key'));
    }

    public static function referensi(Pembayaran $pembayaran): string
    {
        return 'pembayaran-'.$pembayaran->id_pembayaran;
    }

    /**
     * Buat (atau pakai ulang) tagihan Xendit dengan metode pilihan pelanggan.
     *
     * @throws XenditException
     */
    public function buatTagihan(Pembayaran $pembayaran, string $metode): Pembayaran
    {
        if ($pembayaran->referensi_transaksi
            && $pembayaran->metode_pembayaran === $metode
            && $pembayaran->kedaluwarsa_pada?->isFuture()) {
            return $pembayaran; // tagihan sebelumnya masih berlaku
        }

        $jenis = self::METODE[$metode]['jenis'];
        $batas = now()->addMinutes(self::BATAS_MENIT);
        $pesanan = $pembayaran->pesanan;

        $properti = match ($jenis) {
            'qr' => ['expires_at' => $batas->toIso8601ZuluString()],
            'va' => [
                'display_name' => mb_substr($pesanan->pelanggan?->nama ?: 'Pelanggan ACare', 0, 50),
                'expires_at' => $batas->toIso8601ZuluString(),
            ],
            'ewallet' => [
                'success_return_url' => route('pembayaran.kembali'),
                'failure_return_url' => route('pembayaran.kembali', ['gagal' => 1]),
            ],
        };

        $hasil = $this->kirim(fn (PendingRequest $http) => $http->post('/v3/payment_requests', [
            'reference_id' => self::referensi($pembayaran),
            'type' => 'PAY',
            'country' => 'ID',
            'currency' => 'IDR',
            'request_amount' => (int) round((float) $pembayaran->jumlah_bayar),
            'capture_method' => 'AUTOMATIC',
            'channel_code' => $metode,
            'channel_properties' => $properti,
            'description' => ($pembayaran->jenis_pembayaran === Pembayaran::AWAL ? 'Biaya awal ' : 'Pelunasan ')
                .$pesanan->kode,
            'metadata' => ['id_pesanan' => (string) $pesanan->id_pesanan],
        ]));

        $aksi = collect($hasil['actions'] ?? []);
        $nilai = fn (string $descriptor) => $aksi->firstWhere('descriptor', $descriptor)['value'] ?? null;

        $pembayaran->update([
            'metode_pembayaran' => $metode,
            'referensi_transaksi' => $hasil['payment_request_id'],
            'kode_bayar' => $nilai('QR_STRING') ?? $nilai('VIRTUAL_ACCOUNT_NUMBER') ?? $nilai('PAYMENT_CODE'),
            'url_pembayaran' => $nilai('DEEPLINK_URL') ?? $nilai('WEB_URL'),
            // E-wallet tidak punya batas yang bisa diatur; pakai batas yang sama.
            'kedaluwarsa_pada' => $batas,
        ]);

        if (($hasil['status'] ?? null) === 'SUCCEEDED') {
            $this->alur->pembayaranBerhasil($pembayaran, $metode);
        }

        return $pembayaran->refresh();
    }

    /**
     * Tanyakan status tagihan ke Xendit. Cadangan bila webhook belum
     * sampai (misal terowongan lokal mati). Dibatasi tiap 5 detik.
     */
    public function periksa(Pembayaran $pembayaran): void
    {
        if (! $this->aktif()
            || $pembayaran->status_pembayaran !== Pembayaran::MENUNGGU
            || ! $pembayaran->referensi_transaksi
            || ! Cache::add('xendit-periksa-'.$pembayaran->id_pembayaran, true, self::JEDA_PERIKSA_DETIK)) {
            return;
        }

        try {
            $hasil = $this->kirim(fn (PendingRequest $http) => $http
                ->get('/v3/payment_requests/'.$pembayaran->referensi_transaksi));
        } catch (XenditException) {
            return; // dicoba lagi pada pemeriksaan berikutnya
        }

        if (($hasil['status'] ?? null) === 'SUCCEEDED') {
            $this->alur->pembayaranBerhasil($pembayaran, $hasil['channel_code'] ?? null);
        }
    }

    /**
     * Mode Test: minta Xendit menganggap tagihan dibayar. Hasilnya datang
     * lewat webhook (atau pemeriksaan status), sama seperti pembayaran asli.
     *
     * @throws XenditException
     */
    public function simulasi(Pembayaran $pembayaran): void
    {
        $this->kirim(fn (PendingRequest $http) => $http->post(
            '/v3/payment_requests/'.$pembayaran->referensi_transaksi.'/simulate',
            ['amount' => (int) round((float) $pembayaran->jumlah_bayar)],
        ));
    }

    /**
     * Proses isi webhook yang tokennya sudah diperiksa.
     * Hanya payment.capture berstatus SUCCEEDED yang mengubah data.
     */
    public function terimaWebhook(array $isi): void
    {
        $data = $isi['data'] ?? [];
        if (($isi['event'] ?? null) !== 'payment.capture' || ($data['status'] ?? null) !== 'SUCCEEDED') {
            Log::info('Webhook Xendit diabaikan', ['event' => $isi['event'] ?? null, 'status' => $data['status'] ?? null]);

            return;
        }

        $pembayaran = $this->cariPembayaran($data);
        if (! $pembayaran) {
            Log::warning('Webhook Xendit: tagihan tidak dikenal', ['reference_id' => $data['reference_id'] ?? null]);

            return;
        }

        $dibayar = collect($data['captures'] ?? [])->sum('capture_amount') ?: (float) ($data['request_amount'] ?? 0);
        if (($data['currency'] ?? 'IDR') !== 'IDR' || $dibayar + 0.01 < (float) $pembayaran->jumlah_bayar) {
            Log::error('Webhook Xendit: jumlah tidak sesuai', [
                'id_pembayaran' => $pembayaran->id_pembayaran, 'dibayar' => $dibayar,
            ]);

            return;
        }

        $this->alur->pembayaranBerhasil($pembayaran, $data['channel_code'] ?? null);
    }

    private function cariPembayaran(array $data): ?Pembayaran
    {
        if (preg_match('/^pembayaran-(\d+)$/', (string) ($data['reference_id'] ?? ''), $m)) {
            return Pembayaran::query()->find((int) $m[1]);
        }

        return isset($data['payment_request_id'])
            ? Pembayaran::query()->where('referensi_transaksi', $data['payment_request_id'])->first()
            : null;
    }

    /**
     * @param  callable(PendingRequest): Response  $permintaan
     *
     * @throws XenditException
     */
    private function kirim(callable $permintaan): array
    {
        if (! $this->aktif()) {
            throw new XenditException('Kunci Xendit belum diisi.');
        }

        $http = Http::baseUrl(config('services.xendit.url'))
            ->withBasicAuth(config('services.xendit.secret_key'), '')
            ->withHeaders(['api-version' => self::VERSI_API])
            ->acceptJson()
            ->timeout(20);

        try {
            $res = $permintaan($http);
        } catch (ConnectionException $e) {
            Log::warning('Xendit tidak bisa dihubungi', ['galat' => $e->getMessage()]);
            throw new XenditException('Xendit tidak bisa dihubungi.', previous: $e);
        }

        if ($res->failed()) {
            Log::warning('Xendit menolak permintaan', ['status' => $res->status(), 'isi' => $res->json()]);
            throw new XenditException((string) ($res->json('message') ?? 'Permintaan ditolak Xendit.'));
        }

        return $res->json() ?? [];
    }
}
