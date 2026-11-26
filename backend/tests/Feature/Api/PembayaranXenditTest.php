<?php

namespace Tests\Feature\Api;

use App\Models\Layanan;
use App\Models\Pembayaran;
use App\Models\Pengguna;
use App\Models\Pesanan;
use Database\Seeders\LayananSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Factory;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/** Pembayaran lewat Xendit (tiruan Http::fake, tanpa internet). */
class PembayaranXenditTest extends TestCase
{
    use RefreshDatabase;

    private const PR_ID = 'pr-1102feb0-bb79-47ae-9d1e-e69394d3949c';

    private string $token;

    private Pesanan $pesanan;

    private Pembayaran $tagihan;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(LayananSeeder::class);
        config([
            'services.xendit.secret_key' => 'xnd_development_tiruan',
            'services.xendit.webhook_token' => 'token-rahasia',
            'services.xendit.url' => 'https://api.xendit.co',
        ]);

        $pelanggan = Pengguna::create([
            'nama' => 'Dina', 'email' => 'dina@contoh.id', 'no_telepon' => '081111111111',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $lokasi = $pelanggan->lokasi()->create([
            'label_alamat' => 'Rumah', 'alamat_lengkap' => 'Jl. Engku Putri No. 12, Batam',
            'latitude' => 1.1283, 'longitude' => 104.053,
        ]);
        $this->token = $pelanggan->createToken('hp')->plainTextToken;

        $id = $this->withToken($this->token)->postJson('/api/pesanan', [
            'id_layanan' => Layanan::where('nama_layanan', 'Service AC')->value('id_layanan'),
            'jumlah_unit' => 1, 'jenis_ac' => 'split', 'pk' => 1, 'merek' => 'Daikin',
            'id_lokasi' => $lokasi->id_lokasi,
            'jadwal_service' => now()->addHour()->toIso8601String(),
            'detail_layanan' => ['keluhan' => ['Tidak dingin']],
        ])->assertCreated()->json('data.id');

        $this->pesanan = Pesanan::findOrFail($id);
        $this->tagihan = $this->pesanan->pembayaran()->firstOrFail();
    }

    private function urlBayar(): string
    {
        return "/api/pesanan/{$this->pesanan->id_pesanan}/pembayaran/{$this->tagihan->id_pembayaran}/bayar";
    }

    private function fakeBuat(array $aksi, string $status = 'REQUIRES_ACTION'): void
    {
        // Tiruan baru menggantikan yang lama (Http::fake menumpuk aturan).
        Http::swap(new Factory);
        Http::fake(['api.xendit.co/v3/payment_requests' => Http::response([
            'payment_request_id' => self::PR_ID,
            'reference_id' => 'pembayaran-'.$this->tagihan->id_pembayaran,
            'status' => $status,
            'actions' => $aksi,
        ], 201)]);
    }

    private function webhook(array $data = [], string $event = 'payment.capture', string $token = 'token-rahasia')
    {
        return $this->withHeader('x-callback-token', $token)->postJson('/api/xendit/webhook', [
            'event' => $event,
            'business_id' => 'bisnis',
            'data' => [
                'payment_id' => 'py-123',
                'payment_request_id' => self::PR_ID,
                'reference_id' => 'pembayaran-'.$this->tagihan->id_pembayaran,
                'currency' => 'IDR',
                'request_amount' => 100000,
                'channel_code' => 'QRIS',
                'captures' => [['capture_id' => 'cap-1', 'capture_amount' => 100000]],
                'status' => 'SUCCEEDED',
                ...$data,
            ],
        ]);
    }

    public function test_bayar_qris_mengirim_payment_request_dan_menampilkan_kode_qr(): void
    {
        $this->fakeBuat([['type' => 'PRESENT_TO_CUSTOMER', 'descriptor' => 'QR_STRING', 'value' => '00020101021226']]);

        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])
            ->assertOk()
            ->assertJsonPath('data.pembayaran.0.status', 'menunggu')
            ->assertJsonPath('data.pembayaran.0.instruksi.jenis', 'qr')
            ->assertJsonPath('data.pembayaran.0.instruksi.nama_metode', 'QRIS')
            ->assertJsonPath('data.pembayaran.0.instruksi.kode', '00020101021226');

        Http::assertSent(fn (Request $r) => $r->url() === 'https://api.xendit.co/v3/payment_requests'
            && $r->hasHeader('api-version', '2024-11-11')
            && $r->hasHeader('Authorization', 'Basic '.base64_encode('xnd_development_tiruan:'))
            && $r['reference_id'] === 'pembayaran-'.$this->tagihan->id_pembayaran
            && $r['type'] === 'PAY' && $r['currency'] === 'IDR' && $r['country'] === 'ID'
            && $r['request_amount'] === 100000
            && $r['channel_code'] === 'QRIS'
            && isset($r['channel_properties']['expires_at']));

        $this->assertSame(self::PR_ID, $this->tagihan->refresh()->referensi_transaksi);
    }

    public function test_bayar_va_dan_ewallet(): void
    {
        $this->fakeBuat([['type' => 'PRESENT_TO_CUSTOMER', 'descriptor' => 'VIRTUAL_ACCOUNT_NUMBER', 'value' => '8808123456']]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'BNI_VIRTUAL_ACCOUNT'])
            ->assertOk()
            ->assertJsonPath('data.pembayaran.0.instruksi.jenis', 'va')
            ->assertJsonPath('data.pembayaran.0.instruksi.kode', '8808123456');
        Http::assertSent(fn (Request $r) => $r['channel_properties']['display_name'] === 'Dina');

        // Ganti metode: payment request baru dibuat.
        $this->fakeBuat([['type' => 'REDIRECT_CUSTOMER', 'descriptor' => 'WEB_URL', 'value' => 'https://dana.id/bayar/abc']]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'DANA'])
            ->assertOk()
            ->assertJsonPath('data.pembayaran.0.instruksi.jenis', 'ewallet')
            ->assertJsonPath('data.pembayaran.0.instruksi.url', 'https://dana.id/bayar/abc')
            ->assertJsonPath('data.pembayaran.0.instruksi.kode', null);
        Http::assertSent(fn (Request $r) => str_ends_with($r['channel_properties']['success_return_url'], '/pembayaran/kembali'));
    }

    public function test_metode_sama_yang_masih_berlaku_dipakai_ulang(): void
    {
        $this->fakeBuat([['type' => 'PRESENT_TO_CUSTOMER', 'descriptor' => 'QR_STRING', 'value' => 'qr']]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])->assertOk();
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])->assertOk();

        Http::assertSentCount(1);
    }

    public function test_metode_tidak_dikenal_dan_tagihan_tidak_aktif_ditolak(): void
    {
        Http::fake();
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'BITCOIN'])
            ->assertUnprocessable()->assertJsonPath('errors.metode.0', 'Metode pembayaran tidak tersedia.');

        $this->tagihan->update(['status_pembayaran' => Pembayaran::BERHASIL]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])
            ->assertConflict()->assertJsonPath('kode', 'bukan_tagihan_aktif');
        Http::assertNothingSent();
    }

    public function test_xendit_gagal_atau_belum_diatur(): void
    {
        Http::fake(['api.xendit.co/*' => Http::response(['error_code' => 'API_VALIDATION_ERROR', 'message' => 'x'], 400)]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])
            ->assertStatus(502)->assertJsonPath('kode', 'xendit_gagal');
        $this->assertNull($this->tagihan->refresh()->referensi_transaksi);

        config(['services.xendit.secret_key' => null]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])
            ->assertStatus(503)->assertJsonPath('kode', 'pembayaran_belum_siap');
    }

    public function test_webhook_lunas_memulai_pencarian_teknisi_sekali_saja(): void
    {
        $this->fakeBuat([['type' => 'PRESENT_TO_CUSTOMER', 'descriptor' => 'QR_STRING', 'value' => 'qr']]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])->assertOk();

        $this->webhook()->assertOk();
        $this->tagihan->refresh();
        $this->assertSame(Pembayaran::BERHASIL, $this->tagihan->status_pembayaran);
        $this->assertSame('QRIS', $this->tagihan->metode_pembayaran);
        $this->assertNotNull($this->pesanan->refresh()->pencarian_dimulai_pada);

        // Webhook yang sama datang lagi: tidak mengubah apa pun.
        $waktu = $this->tagihan->waktu_pembayaran;
        $this->travel(1)->minutes();
        $this->webhook()->assertOk();
        $this->assertEquals($waktu, $this->tagihan->refresh()->waktu_pembayaran);
    }

    public function test_webhook_tanpa_token_benar_ditolak(): void
    {
        $this->webhook(token: 'salah')->assertUnauthorized()->assertJsonPath('kode', 'token_tidak_sah');
        $this->withHeaders([])->postJson('/api/xendit/webhook', [])->assertUnauthorized();
        $this->assertSame(Pembayaran::MENUNGGU, $this->tagihan->refresh()->status_pembayaran);
    }

    public function test_webhook_diabaikan_bila_bukan_lunas_atau_jumlah_kurang(): void
    {
        $this->webhook(['status' => 'FAILED'], 'payment.failure')->assertOk();
        $this->webhook(['captures' => [['capture_amount' => 5000]], 'request_amount' => 5000])->assertOk();
        $this->webhook(['reference_id' => 'pembayaran-9999', 'payment_request_id' => 'pr-lain'])->assertOk();

        $this->assertSame(Pembayaran::MENUNGGU, $this->tagihan->refresh()->status_pembayaran);
    }

    public function test_dibayar_setelah_pesanan_dibatalkan_dana_tertahan(): void
    {
        $this->withToken($this->token)->postJson("/api/pesanan/{$this->pesanan->id_pesanan}/batal")->assertOk();
        $this->assertSame(Pembayaran::KEDALUWARSA, $this->tagihan->refresh()->status_pembayaran);

        $this->webhook()->assertOk();
        $this->assertSame(Pembayaran::TERTAHAN, $this->tagihan->refresh()->status_pembayaran);
    }

    public function test_detail_pesanan_memeriksa_status_ke_xendit_bila_webhook_belum_datang(): void
    {
        $this->fakeBuat([['type' => 'PRESENT_TO_CUSTOMER', 'descriptor' => 'QR_STRING', 'value' => 'qr']]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])->assertOk();

        Http::fake(['api.xendit.co/v3/payment_requests/'.self::PR_ID => Http::sequence()
            ->push(['payment_request_id' => self::PR_ID, 'status' => 'REQUIRES_ACTION'])
            ->push(['payment_request_id' => self::PR_ID, 'status' => 'SUCCEEDED', 'channel_code' => 'QRIS'])]);

        $url = "/api/pesanan/{$this->pesanan->id_pesanan}";
        $this->withToken($this->token)->getJson($url)->assertJsonPath('data.pembayaran.0.status', 'menunggu');
        // Dalam 5 detik tidak bertanya lagi ke Xendit.
        $this->withToken($this->token)->getJson($url)->assertJsonPath('data.pembayaran.0.status', 'menunggu');

        Cache::flush();
        $this->withToken($this->token)->getJson($url)
            ->assertJsonPath('data.pembayaran.0.status', 'berhasil')
            ->assertJsonPath('data.pembayaran.0.instruksi', null);
        $this->assertNotNull($this->pesanan->refresh()->pencarian_dimulai_pada);
    }

    public function test_simulasi_memanggil_xendit_bila_tagihan_sudah_dibuat(): void
    {
        $this->fakeBuat([['type' => 'PRESENT_TO_CUSTOMER', 'descriptor' => 'QR_STRING', 'value' => 'qr']]);
        $this->withToken($this->token)->postJson($this->urlBayar(), ['metode' => 'QRIS'])->assertOk();

        Http::fake(['api.xendit.co/*' => Http::response(['status' => 'PENDING'])]);
        $this->withToken($this->token)
            ->postJson("/api/pesanan/{$this->pesanan->id_pesanan}/pembayaran/{$this->tagihan->id_pembayaran}/simulasi-lunas")
            ->assertOk()->assertJsonPath('data.pembayaran.0.status', 'menunggu');

        Http::assertSent(fn (Request $r) => $r->url() === 'https://api.xendit.co/v3/payment_requests/'.self::PR_ID.'/simulate'
            && $r['amount'] === 100000);
    }
}
