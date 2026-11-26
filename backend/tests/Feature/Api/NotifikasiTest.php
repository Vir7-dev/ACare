<?php

namespace Tests\Feature\Api;

use App\Jobs\KirimNotifikasiFcm;
use App\Models\FcmToken;
use App\Models\Layanan;
use App\Models\Notifikasi;
use App\Models\Pengguna;
use App\Models\Pesanan;
use App\Services\AlurPesanan;
use App\Services\Fcm;
use Database\Seeders\LayananSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/** Token perangkat, pengiriman FCM (tiruan), dan notifikasi tiap status. */
class NotifikasiTest extends TestCase
{
    use RefreshDatabase;

    private Pengguna $pelanggan;

    private Pengguna $teknisi;

    private string $tokenPelanggan;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(LayananSeeder::class);
        $this->pelanggan = Pengguna::create([
            'nama' => 'Dina', 'email' => 'dina@contoh.id', 'no_telepon' => '081111111111',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $this->pelanggan->lokasi()->create([
            'label_alamat' => 'Rumah', 'alamat_lengkap' => 'Jl. Engku Putri No. 12, Batam',
            'latitude' => 1.1283, 'longitude' => 104.053,
        ]);
        $this->tokenPelanggan = $this->pelanggan->createToken('hp')->plainTextToken;

        $this->teknisi = Pengguna::create([
            'nama' => 'Andi', 'email' => 'andi@contoh.id', 'no_telepon' => '082222222222',
            'kata_sandi' => 'rahasia123', 'role' => 'teknisi',
        ]);
        $this->teknisi->teknisi()->create([
            'jenis_kendaraan' => 'Honda Beat', 'plat_nomor' => 'BP 1 AA', 'nama_bank' => 'BNI',
            'no_rekening' => '123456', 'atas_nama' => 'Andi', 'status_verifikasi' => 'terverifikasi',
            'status_ketersediaan' => 'tersedia', 'latitude' => 1.13, 'longitude' => 104.05,
            'lokasi_diperbarui_pada' => now(),
        ]);
    }

    /** File service account palsu dengan kunci RSA sungguhan. */
    private function akunPalsu(): void
    {
        // Di Windows OpenSSL butuh openssl.cnf bawaan PHP.
        $opsi = ['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA];
        $cnf = dirname(PHP_BINARY).'/extras/ssl/openssl.cnf';
        if (is_file($cnf)) {
            $opsi['config'] = $cnf;
        }
        $kunci = openssl_pkey_new($opsi);
        if ($kunci === false) {
            $this->markTestSkipped('OpenSSL tidak bisa membuat kunci RSA di mesin ini.');
        }
        openssl_pkey_export($kunci, $pem, null, $opsi);
        $path = storage_path('framework/testing/firebase-uji.json');
        @mkdir(dirname($path), 0777, true);
        file_put_contents($path, json_encode([
            'type' => 'service_account', 'project_id' => 'acare-uji',
            'client_email' => 'fcm@acare-uji.iam.gserviceaccount.com',
            'private_key' => $pem, 'token_uri' => 'https://oauth2.googleapis.com/token',
        ]));
        config(['services.firebase.credentials' => $path, 'services.firebase.project_id' => null]);
    }

    private function pesanan(): Pesanan
    {
        $id = $this->withToken($this->tokenPelanggan)->postJson('/api/pesanan', [
            'id_layanan' => Layanan::where('nama_layanan', 'Service AC')->value('id_layanan'),
            'jumlah_unit' => 1, 'jenis_ac' => 'split', 'pk' => 1,
            'id_lokasi' => $this->pelanggan->lokasi()->value('id_lokasi'),
            'jadwal_service' => now()->addHour()->toIso8601String(),
            'detail_layanan' => ['keluhan' => ['Tidak dingin']],
        ])->assertCreated()->json('data.id');

        return Pesanan::findOrFail($id);
    }

    /** @return list<string> */
    private function tipeUntuk(Pengguna $p): array
    {
        return Notifikasi::where('id_penerima', $p->id_pengguna)->orderBy('id_notifikasi')
            ->pluck('tipe_notifikasi')->all();
    }

    public function test_daftar_pindah_dan_hapus_token_perangkat(): void
    {
        $this->withToken($this->tokenPelanggan)->putJson('/api/saya/perangkat', ['token' => 'tok-hp-1'])
            ->assertOk();
        $this->withToken($this->tokenPelanggan)->putJson('/api/saya/perangkat', ['token' => 'tok-hp-1'])
            ->assertOk();
        $this->assertSame(1, FcmToken::count());

        // Teknisi masuk di HP yang sama: token pindah ke akunnya.
        $tokenTeknisi = $this->teknisi->createToken('hp')->plainTextToken;
        $this->app['auth']->forgetGuards();
        $this->withToken($tokenTeknisi)->putJson('/api/saya/perangkat', ['token' => 'tok-hp-1'])->assertOk();
        $this->assertSame($this->teknisi->id_pengguna, FcmToken::first()->id_pengguna);

        // Pelanggan tidak bisa menghapus token milik akun lain.
        $this->app['auth']->forgetGuards();
        $this->withToken($this->tokenPelanggan)->deleteJson('/api/saya/perangkat', ['token' => 'tok-hp-1'])->assertOk();
        $this->assertSame(1, FcmToken::count());

        $this->app['auth']->forgetGuards();
        $this->withToken($tokenTeknisi)->deleteJson('/api/saya/perangkat', ['token' => 'tok-hp-1'])->assertOk();
        $this->assertSame(0, FcmToken::count());

        $this->withToken($tokenTeknisi)->putJson('/api/saya/perangkat', [])
            ->assertUnprocessable()->assertJsonPath('errors.token.0', 'Token perangkat wajib diisi.');
    }

    public function test_fcm_mengirim_pesan_v1_dan_memakai_ulang_token_akses(): void
    {
        $this->akunPalsu();
        FcmToken::create(['id_pengguna' => $this->pelanggan->id_pengguna, 'token' => 'tok-a']);
        FcmToken::create(['id_pengguna' => $this->pelanggan->id_pengguna, 'token' => 'tok-b']);
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'akses-123', 'expires_in' => 3599]),
            'fcm.googleapis.com/*' => Http::response(['name' => 'projects/acare-uji/messages/1']),
        ]);

        $terkirim = app(Fcm::class)->kirimKePengguna(
            $this->pelanggan->id_pengguna, 'Judul', 'Isi', ['tipe' => 'uji', 'id_pesanan' => 7],
        );

        $this->assertSame(2, $terkirim);
        Http::assertSentCount(3); // 1x token akses + 2x kirim
        Http::assertSent(fn (Request $r) => str_contains($r->url(), 'oauth2.googleapis.com')
            && $r['grant_type'] === 'urn:ietf:params:oauth:grant-type:jwt-bearer'
            && count(explode('.', $r['assertion'])) === 3);
        Http::assertSent(fn (Request $r) => $r->url() === 'https://fcm.googleapis.com/v1/projects/acare-uji/messages:send'
            && $r->hasHeader('Authorization', 'Bearer akses-123')
            && $r['message']['token'] === 'tok-a'
            && $r['message']['notification'] === ['title' => 'Judul', 'body' => 'Isi']
            && $r['message']['data'] === ['tipe' => 'uji', 'id_pesanan' => '7']
            && $r['message']['android']['notification']['channel_id'] === Fcm::KANAL_ANDROID);
    }

    public function test_token_perangkat_yang_tidak_terdaftar_dihapus(): void
    {
        $this->akunPalsu();
        FcmToken::create(['id_pengguna' => $this->pelanggan->id_pengguna, 'token' => 'tok-lama']);
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'akses', 'expires_in' => 3599]),
            'fcm.googleapis.com/*' => Http::response(['error' => [
                'code' => 404, 'status' => 'NOT_FOUND',
                'details' => [['@type' => 'type.googleapis.com/google.firebase.fcm.v1.FcmError', 'errorCode' => 'UNREGISTERED']],
            ]], 404),
        ]);

        $this->assertSame(0, app(Fcm::class)->kirimKePengguna($this->pelanggan->id_pengguna, 'J', 'I'));
        $this->assertSame(0, FcmToken::count());
    }

    public function test_tanpa_file_service_account_tidak_mengirim_apa_pun(): void
    {
        Http::fake();
        FcmToken::create(['id_pengguna' => $this->pelanggan->id_pengguna, 'token' => 'tok']);

        $this->assertFalse(app(Fcm::class)->aktif());
        $this->assertSame(0, app(Fcm::class)->kirimKePengguna($this->pelanggan->id_pengguna, 'J', 'I'));
        Http::assertNothingSent();
    }

    public function test_notifikasi_untuk_setiap_tahap_pesanan(): void
    {
        Bus::fake();
        $alur = app(AlurPesanan::class);
        $p = $this->pesanan();
        $bayar = $p->pembayaran()->first();

        // Lunas -> pelanggan diberi tahu, teknisi terdekat ditawari.
        $alur->pembayaranBerhasil($bayar, 'QRIS');
        $this->assertSame(['pembayaran_berhasil'], $this->tipeUntuk($this->pelanggan));
        $this->assertSame(['tawaran'], $this->tipeUntuk($this->teknisi));
        Bus::assertDispatchedAfterResponse(KirimNotifikasiFcm::class, fn (KirimNotifikasiFcm $j) => $j->idPengguna === $this->teknisi->id_pengguna
            && $j->judul === 'Pesanan masuk!'
            && $j->data === ['tipe' => 'tawaran', 'id_pesanan' => $p->id_pesanan]);

        $this->assertTrue($alur->terimaTawaran($p->refresh(), $this->teknisi->teknisi));
        $p->refresh()->update(['status_pesanan' => Pesanan::TIBA, 'tiba_pada' => now()]);
        $p->update(['status_pesanan' => Pesanan::PENGECEKAN_AWAL]);
        $alur->ajukanBiaya($p->refresh(), [['nama' => 'Kapasitor', 'jenis' => 'suku_cadang', 'harga' => 85000]], null);

        // Menanggapi biaya menyimpan dua kali dalam satu transaksi: teknisi
        // tetap diberi tahu.
        $alur->tanggapiBiaya($p->refresh(), true);
        $alur->selesaiDikerjakan($p->refresh(), 'Kapasitor diganti');
        $alur->pembayaranBerhasil($p->pembayaran()->where('jenis_pembayaran', 'pelunasan')->firstOrFail(), 'DANA');

        $this->assertSame([
            'pembayaran_berhasil', 'teknisi_ditemukan', 'teknisi_tiba', 'persetujuan_biaya', 'pelunasan', 'selesai',
        ], $this->tipeUntuk($this->pelanggan));
        $this->assertSame(['tawaran', 'biaya_ditanggapi', 'pelunasan_diterima'], $this->tipeUntuk($this->teknisi));
        $this->assertSame('Biaya disetujui', Notifikasi::where('tipe_notifikasi', 'biaya_ditanggapi')->value('judul'));
    }

    public function test_batal_otomatis_tanpa_teknisi_memberi_tahu_pelanggan(): void
    {
        Bus::fake();
        $this->teknisi->teknisi()->update(['status_ketersediaan' => 'offline']);
        $p = $this->pesanan();
        app(AlurPesanan::class)->pembayaranBerhasil($p->pembayaran()->first(), 'QRIS');

        $this->travel(Pesanan::BATAS_PENCARIAN_MENIT + 1)->minutes();
        app(AlurPesanan::class)->perbarui($p->refresh());

        $this->assertSame(['pembayaran_berhasil', 'tanpa_teknisi'], $this->tipeUntuk($this->pelanggan));
        $this->assertSame([], $this->tipeUntuk($this->teknisi));
    }

    public function test_dibatalkan_pelanggan_tidak_mengirim_notifikasi(): void
    {
        Bus::fake();
        $p = $this->pesanan();
        $this->withToken($this->tokenPelanggan)->postJson("/api/pesanan/{$p->id_pesanan}/batal")->assertOk();

        $this->assertSame(0, Notifikasi::count());
        Bus::assertNotDispatchedAfterResponse(KirimNotifikasiFcm::class);
    }
}
