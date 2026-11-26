<?php

namespace Tests\Feature\Api;

use App\Models\Layanan;
use App\Models\Lokasi;
use App\Models\Pembayaran;
use App\Models\Pengguna;
use App\Models\Pesanan;
use Database\Seeders\LayananSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PesananApiTest extends TestCase
{
    use RefreshDatabase;

    private Pengguna $pelanggan;

    private Lokasi $lokasi;

    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(LayananSeeder::class);
        $this->freezeSecond();
        $this->pelanggan = Pengguna::create([
            'nama' => 'Dina', 'email' => 'dina@contoh.id', 'no_telepon' => '081111111111',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $this->lokasi = $this->pelanggan->lokasi()->create([
            'label_alamat' => 'Rumah', 'alamat_lengkap' => 'Jl. Engku Putri No. 12, Batam',
            'latitude' => 1.1283, 'longitude' => 104.053,
        ]);
        $this->token = $this->pelanggan->createToken('hp')->plainTextToken;
    }

    private function idLayanan(string $nama): int
    {
        return Layanan::where('nama_layanan', $nama)->value('id_layanan');
    }

    private function data(array $ubah = []): array
    {
        return [
            'id_layanan' => $this->idLayanan('Service AC'),
            'jumlah_unit' => 2,
            'jenis_ac' => 'split',
            'pk' => 1,
            'merek' => 'Daikin',
            'id_lokasi' => $this->lokasi->id_lokasi,
            'detail_lokasi' => 'Kamar tidur utama',
            'jadwal_service' => now()->addHour()->toIso8601String(),
            'catatan' => 'Telepon dulu sebelum datang.',
            'detail_layanan' => ['keluhan' => ['Tidak dingin', 'Bocor air'], 'jenis_freon' => 'R32'],
            ...$ubah,
        ];
    }

    private function buat(array $ubah = [])
    {
        return $this->withToken($this->token)->postJson('/api/pesanan', $this->data($ubah));
    }

    public function test_buat_pesanan_menghitung_biaya_awal_dan_membuat_tagihan(): void
    {
        $res = $this->buat()->assertCreated()
            ->assertJsonPath('data.status', 'mencari_teknisi')
            ->assertJsonPath('data.label_status', 'Mencari Teknisi')
            ->assertJsonPath('data.layanan.nama', 'Service AC')
            ->assertJsonPath('data.layanan.bisa_biaya_tambahan', true)
            ->assertJsonPath('data.jumlah_unit', 2)
            ->assertJsonPath('data.biaya.total', 200000)
            ->assertJsonPath('data.biaya.rincian.0.subtotal', 200000)
            ->assertJsonPath('data.pembayaran.0.jenis', 'awal')
            ->assertJsonPath('data.pembayaran.0.status', 'menunggu')
            ->assertJsonPath('data.pembayaran.0.jumlah', 200000)
            ->assertJsonPath('data.alamat.label', 'Rumah')
            ->assertJsonPath('data.teknisi', null)
            ->assertJsonPath('data.bisa_dibatalkan', true);

        // Hanya isian yang berlaku untuk Service AC yang disimpan.
        $res->assertJsonPath('data.detail_layanan', ['keluhan' => ['Tidak dingin', 'Bocor air']]);
        $this->assertMatchesRegularExpression('/^AC-\d{6}$/', $res->json('data.kode'));
    }

    public function test_isian_wajib_mengikuti_layanan(): void
    {
        $this->buat([
            'id_layanan' => $this->idLayanan('Isi Freon'),
            'detail_layanan' => [],
        ])->assertUnprocessable()->assertJsonValidationErrors([
            'detail_layanan.jenis_freon' => 'Jenis freon wajib dipilih.',
        ]);

        $this->buat([
            'id_layanan' => $this->idLayanan('Bongkar Pasang'),
            'detail_layanan' => ['jenis_pekerjaan' => 'pindah'],
        ])->assertCreated()->assertJsonPath('data.detail_layanan.jenis_pekerjaan', 'pindah');
    }

    public function test_validasi_pesanan_berbahasa_indonesia(): void
    {
        $this->withToken($this->token)->postJson('/api/pesanan', [
            'jumlah_unit' => 9,
            'pk' => 7,
            'jadwal_service' => now()->subDay()->toIso8601String(),
        ])->assertUnprocessable()->assertJsonValidationErrors([
            'id_layanan' => 'Layanan wajib diisi.',
            'jumlah_unit' => 'Jumlah unit maksimal 5.',
            'pk' => 'Kapasitas PK tidak valid.',
            'id_lokasi' => 'Alamat wajib diisi.',
            'jadwal_service' => 'Jadwal servis tidak boleh di masa lalu.',
        ]);
    }

    public function test_alamat_milik_orang_lain_atau_terhapus_ditolak(): void
    {
        $this->lokasi->delete();

        $this->buat()->assertUnprocessable()
            ->assertJsonValidationErrors(['id_lokasi' => 'Alamat tidak ditemukan.']);
    }

    public function test_tidak_bisa_memesan_saat_masih_ada_pesanan_aktif(): void
    {
        $this->buat()->assertCreated();

        $this->buat()->assertStatus(409)->assertJsonPath('kode', 'masih_ada_pesanan_aktif');
        $this->assertSame(1, Pesanan::count());
    }

    public function test_riwayat_dan_filter_status(): void
    {
        $id = $this->buat()->json('data.id');
        $this->withToken($this->token)->postJson("/api/pesanan/{$id}/batal")->assertOk();
        $this->buat(['id_layanan' => $this->idLayanan('Cuci AC')])->assertCreated();

        $this->withToken($this->token)->getJson('/api/pesanan')
            ->assertOk()->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.layanan.nama', 'Cuci AC');
        $this->withToken($this->token)->getJson('/api/pesanan?status=aktif')
            ->assertJsonCount(1, 'data')->assertJsonPath('data.0.status', 'mencari_teknisi');
        $this->withToken($this->token)->getJson('/api/pesanan?status=dibatalkan')
            ->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $id);
    }

    public function test_batal_saat_mencari_teknisi_membatalkan_tagihan(): void
    {
        $id = $this->buat()->json('data.id');

        $this->withToken($this->token)->postJson("/api/pesanan/{$id}/batal", ['alasan' => 'Salah pilih jadwal'])
            ->assertOk()
            ->assertJsonPath('data.status', 'dibatalkan')
            ->assertJsonPath('data.alasan_pembatalan', 'Salah pilih jadwal')
            ->assertJsonPath('data.pembayaran.0.status', 'kedaluwarsa')
            ->assertJsonPath('data.bisa_dibatalkan', false);
    }

    public function test_batal_setelah_dibayar_dana_tertahan_untuk_refund(): void
    {
        $id = $this->buat()->json('data.id');
        Pembayaran::where('id_pesanan', $id)->update(['status_pembayaran' => Pembayaran::BERHASIL]);

        $this->withToken($this->token)->postJson("/api/pesanan/{$id}/batal")
            ->assertOk()->assertJsonPath('data.pembayaran.0.status', 'tertahan');
    }

    public function test_tidak_bisa_batal_setelah_teknisi_ditemukan(): void
    {
        $id = $this->buat()->json('data.id');
        Pesanan::whereKey($id)->update(['status_pesanan' => Pesanan::MENUJU_LOKASI]);

        $this->withToken($this->token)->postJson("/api/pesanan/{$id}/batal")
            ->assertUnprocessable()->assertJsonPath('kode', 'tidak_bisa_dibatalkan');
    }

    public function test_pesanan_orang_lain_tidak_terlihat(): void
    {
        $id = $this->buat()->json('data.id');
        $lain = Pengguna::create([
            'nama' => 'Lain', 'email' => 'lain@contoh.id', 'no_telepon' => '082222222222',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $tokenLain = $lain->createToken('hp')->plainTextToken;

        $this->app['auth']->forgetGuards();
        $this->withToken($tokenLain)->getJson("/api/pesanan/{$id}")->assertNotFound();
        $this->app['auth']->forgetGuards();
        $this->withToken($tokenLain)->postJson("/api/pesanan/{$id}/batal")->assertNotFound();
        $this->assertSame(Pesanan::MENCARI_TEKNISI, Pesanan::find($id)->status_pesanan);
    }

    public function test_detail_tetap_menampilkan_alamat_yang_sudah_dihapus(): void
    {
        $id = $this->buat()->json('data.id');
        Pesanan::whereKey($id)->update(['status_pesanan' => Pesanan::SELESAI]);
        $this->lokasi->delete();

        $this->withToken($this->token)->getJson("/api/pesanan/{$id}")
            ->assertOk()->assertJsonPath('data.alamat.alamat_lengkap', 'Jl. Engku Putri No. 12, Batam');
    }

    public function test_tanpa_token_pesan_berbahasa_indonesia(): void
    {
        $this->getJson('/api/pesanan')
            ->assertUnauthorized()
            ->assertJson(['message' => 'Sesi kamu sudah berakhir. Silakan masuk lagi.']);
    }
}
