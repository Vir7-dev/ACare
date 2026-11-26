<?php

namespace Tests\Feature\Api;

use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProfilApiTest extends TestCase
{
    use RefreshDatabase;

    private Pengguna $pengguna;

    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pengguna = Pengguna::create([
            'nama' => 'Dina Safitri',
            'email' => 'dina@contoh.id',
            'no_telepon' => '083862865166',
            'kata_sandi' => 'rahasia123',
            'role' => Pengguna::ROLE_PELANGGAN,
        ]);
        $this->token = $this->pengguna->createToken('hp')->plainTextToken;
    }

    private function teknisi(): string
    {
        $t = Pengguna::create([
            'nama' => 'Rizky Pratama',
            'email' => 'rizky@contoh.id',
            'no_telepon' => '081200000099',
            'kata_sandi' => 'rahasia123',
            'role' => Pengguna::ROLE_TEKNISI,
        ]);
        $t->teknisi()->create([
            'jenis_kendaraan' => 'Honda Beat',
            'plat_nomor' => 'BP 1234 AC',
            'nama_bank' => 'BNI',
            'no_rekening' => '1234567890',
            'atas_nama' => 'Rizky Pratama',
            'status_verifikasi' => 'terverifikasi',
        ]);

        return $t->createToken('hp')->plainTextToken;
    }

    public function test_tanpa_token_ditolak(): void
    {
        $this->getJson('/api/saya')->assertUnauthorized();
    }

    public function test_menampilkan_akun_sendiri(): void
    {
        $this->withToken($this->token)->getJson('/api/saya')
            ->assertOk()
            ->assertJsonPath('data.email', 'dina@contoh.id')
            ->assertJsonMissingPath('data.teknisi');
    }

    public function test_ubah_profil_sebagian(): void
    {
        $this->withToken($this->token)->putJson('/api/saya', [
            'nama' => 'Dina S.',
            'no_telepon' => '0811 2222 3333',
        ])->assertOk()
            ->assertJsonPath('data.nama', 'Dina S.')
            ->assertJsonPath('data.no_telepon', '081122223333')
            ->assertJsonPath('data.email', 'dina@contoh.id');
    }

    public function test_email_milik_akun_lain_ditolak_tapi_email_sendiri_boleh(): void
    {
        $this->teknisi();

        $this->withToken($this->token)->putJson('/api/saya', ['email' => 'rizky@contoh.id'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email' => 'Email sudah terdaftar.']);

        $this->withToken($this->token)->putJson('/api/saya', ['email' => 'dina@contoh.id'])->assertOk();
    }

    public function test_teknisi_bisa_ubah_kendaraan_dan_tentang_saya(): void
    {
        $token = $this->teknisi();

        $this->withToken($token)->putJson('/api/saya', [
            'jenis_kendaraan' => 'Yamaha NMAX',
            'plat_nomor' => 'bp 777 xy',
            'deskripsi' => 'Spesialis AC inverter.',
        ])->assertOk()
            ->assertJsonPath('data.teknisi.jenis_kendaraan', 'Yamaha NMAX')
            ->assertJsonPath('data.teknisi.plat_nomor', 'BP 777 XY')
            ->assertJsonPath('data.teknisi.deskripsi', 'Spesialis AC inverter.');

        $this->withToken($token)->putJson('/api/saya', ['deskripsi' => str_repeat('a', 301)])
            ->assertJsonValidationErrors(['deskripsi' => 'Tentang saya maksimal 300 karakter.']);
    }

    public function test_ganti_foto_profil_menghapus_foto_lama(): void
    {
        Storage::fake('public');

        // Dipanggil dari emulator Android: URL foto memakai alamat yang sama.
        $lama = $this->withToken($this->token)
            ->post('http://10.0.2.2:8000/api/saya/foto', ['foto' => UploadedFile::fake()->image('a.jpg')], ['Accept' => 'application/json'])
            ->assertOk()->json('data.foto_profil');
        $pathLama = $this->pengguna->refresh()->foto_profil;

        $this->withToken($this->token)
            ->post('/api/saya/foto', ['foto' => UploadedFile::fake()->image('b.png')], ['Accept' => 'application/json'])
            ->assertOk();

        $this->assertSame('http://10.0.2.2:8000/storage/'.$pathLama, $lama);
        Storage::disk('public')->assertMissing($pathLama);
        Storage::disk('public')->assertExists($this->pengguna->refresh()->foto_profil);
    }

    public function test_kata_sandi_lama_salah_ditolak(): void
    {
        $this->withToken($this->token)->putJson('/api/saya/kata-sandi', [
            'kata_sandi_lama' => 'bukanini1',
            'kata_sandi_baru' => 'barurahasia1',
            'kata_sandi_baru_confirmation' => 'barurahasia1',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['kata_sandi_lama' => 'Kata sandi lama tidak sesuai.']);
    }

    public function test_ganti_kata_sandi_mengeluarkan_perangkat_lain(): void
    {
        $tokenLain = $this->pengguna->createToken('tablet')->plainTextToken;

        $this->withToken($this->token)->putJson('/api/saya/kata-sandi', [
            'kata_sandi_lama' => 'rahasia123',
            'kata_sandi_baru' => 'barurahasia1',
            'kata_sandi_baru_confirmation' => 'barurahasia1',
        ])->assertOk();

        $this->assertSame(1, $this->pengguna->tokens()->count());
        $this->app['auth']->forgetGuards();
        $this->withToken($tokenLain)->getJson('/api/saya')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $this->withToken($this->token)->getJson('/api/saya')->assertOk();

        $this->postJson('/api/masuk', [
            'identitas' => 'dina@contoh.id',
            'kata_sandi' => 'barurahasia1',
            'peran' => 'pelanggan',
        ])->assertOk();
    }

    public function test_kata_sandi_baru_harus_berbeda_dan_terkonfirmasi(): void
    {
        $this->withToken($this->token)->putJson('/api/saya/kata-sandi', [
            'kata_sandi_lama' => 'rahasia123',
            'kata_sandi_baru' => 'rahasia123',
            'kata_sandi_baru_confirmation' => 'lain12345',
        ])->assertJsonValidationErrors(['kata_sandi_baru']);
    }
}
