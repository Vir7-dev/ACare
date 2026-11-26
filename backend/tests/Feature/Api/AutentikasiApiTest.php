<?php

namespace Tests\Feature\Api;

use App\Models\DokumenVerifikasi;
use App\Models\Pengguna;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AutentikasiApiTest extends TestCase
{
    use RefreshDatabase;

    private function pelanggan(array $data = []): Pengguna
    {
        return Pengguna::create([
            'nama' => 'Dina Safitri',
            'email' => 'dina@contoh.id',
            'no_telepon' => '083862865166',
            'kata_sandi' => 'rahasia123',
            'role' => Pengguna::ROLE_PELANGGAN,
            ...$data,
        ]);
    }

    private function teknisi(string $status = 'terverifikasi', ?string $alasan = null): Pengguna
    {
        $p = Pengguna::create([
            'nama' => 'Rizky Pratama',
            'email' => 'rizky@contoh.id',
            'no_telepon' => '081200000099',
            'kata_sandi' => 'rahasia123',
            'role' => Pengguna::ROLE_TEKNISI,
        ]);
        $p->teknisi()->create([
            'jenis_kendaraan' => 'Honda Beat',
            'plat_nomor' => 'BP 1234 AC',
            'nama_bank' => 'BNI',
            'no_rekening' => '1234567890',
            'atas_nama' => 'Rizky Pratama',
            'status_verifikasi' => $status,
            'alasan_penolakan' => $alasan,
        ]);

        return $p;
    }

    private function masuk(string $identitas, string $peran = 'pelanggan', string $sandi = 'rahasia123')
    {
        return $this->postJson('/api/masuk', [
            'identitas' => $identitas,
            'kata_sandi' => $sandi,
            'peran' => $peran,
        ]);
    }

    // ---------- Daftar pelanggan ----------

    public function test_pelanggan_bisa_mendaftar_dan_nomor_diseragamkan(): void
    {
        $this->postJson('/api/daftar', [
            'nama' => '  Dina Safitri ',
            'email' => 'Dina@Contoh.ID',
            'no_telepon' => '+62 838-6286-5166',
            'kata_sandi' => 'rahasia123',
        ])->assertCreated()
            ->assertJsonPath('pengguna.email', 'dina@contoh.id')
            ->assertJsonPath('pengguna.no_telepon', '083862865166')
            ->assertJsonPath('pengguna.role', 'pelanggan')
            ->assertJsonMissingPath('pengguna.kata_sandi');

        $this->assertDatabaseHas('pengguna', ['email' => 'dina@contoh.id', 'role' => 'pelanggan']);
        $this->assertNotSame('rahasia123', Pengguna::first()->kata_sandi);
    }

    public function test_email_dan_nomor_tidak_boleh_dipakai_dua_akun(): void
    {
        $this->pelanggan();

        $this->postJson('/api/daftar', [
            'nama' => 'Orang Lain',
            'email' => 'DINA@contoh.id',
            'no_telepon' => '6283862865166',
            'kata_sandi' => 'rahasia123',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors([
                'email' => 'Email sudah terdaftar.',
                'no_telepon' => 'Nomor telepon sudah terdaftar.',
            ]);
    }

    public function test_pesan_validasi_daftar_berbahasa_indonesia(): void
    {
        $this->postJson('/api/daftar', ['kata_sandi' => 'pendek'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'nama' => 'Nama wajib diisi.',
                'email' => 'Email wajib diisi.',
                'kata_sandi' => 'Kata sandi minimal 8 karakter.',
            ]);
    }

    // ---------- Daftar teknisi ----------

    private function dataTeknisi(): array
    {
        $dokumen = [];
        foreach (DokumenVerifikasi::JENIS_WAJIB as $jenis) {
            $dokumen[$jenis] = UploadedFile::fake()->image("$jenis.jpg");
        }

        return [
            'nama' => 'Budi Teknisi',
            'email' => 'budi@contoh.id',
            'no_telepon' => '081234567890',
            'kata_sandi' => 'rahasia123',
            'jenis_kendaraan' => 'Honda Vario',
            'plat_nomor' => 'bp 4892 ql',
            'nama_bank' => 'BNI (Bank Negara Indonesia)',
            'no_rekening' => '1234 5678 90',
            'atas_nama' => 'Budi Teknisi',
            'dokumen' => $dokumen,
        ];
    }

    public function test_teknisi_mendaftar_dengan_dokumen_tersimpan_privat(): void
    {
        Storage::fake('local');

        $this->post('/api/daftar/teknisi', $this->dataTeknisi(), ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('pengguna.role', 'teknisi')
            ->assertJsonPath('pengguna.teknisi.status_verifikasi', 'menunggu')
            ->assertJsonPath('pengguna.teknisi.plat_nomor', 'BP 4892 QL')
            ->assertJsonPath('pengguna.teknisi.no_rekening', '1234567890')
            ->assertJsonMissingPath('token');

        $teknisi = Pengguna::where('email', 'budi@contoh.id')->first()->teknisi;
        $this->assertCount(5, $teknisi->dokumen);
        foreach ($teknisi->dokumen as $d) {
            Storage::disk('local')->assertExists($d->path_file);
            $this->assertStringStartsWith('dokumen-teknisi/'.$teknisi->id_pengguna.'/', $d->path_file);
        }
    }

    public function test_daftar_teknisi_ditolak_bila_dokumen_kurang(): void
    {
        Storage::fake('local');
        $data = $this->dataTeknisi();
        unset($data['dokumen']['ktp']);
        $data['dokumen']['ijazah'] = UploadedFile::fake()->create('ijazah.pdf', 100, 'application/pdf');

        $this->post('/api/daftar/teknisi', $data, ['Accept' => 'application/json'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'dokumen.ktp' => 'KTP wajib diisi.',
                'dokumen.ijazah' => 'Ijazah harus berformat jpg, jpeg, png.',
            ]);
        $this->assertDatabaseCount('pengguna', 0);
    }

    // ---------- Masuk ----------

    public function test_masuk_dengan_email_atau_nomor_telepon(): void
    {
        $this->pelanggan();

        $this->masuk('DINA@contoh.id')->assertOk()
            ->assertJsonStructure(['token', 'pengguna' => ['id', 'nama', 'email', 'no_telepon', 'role']])
            ->assertJsonPath('pengguna.nama', 'Dina Safitri');

        $this->masuk('+62 838 6286 5166')->assertOk();
        $this->assertSame(2, Pengguna::first()->tokens()->count());
    }

    public function test_kata_sandi_salah_ditolak(): void
    {
        $this->pelanggan();

        $this->masuk('dina@contoh.id', sandi: 'salah12345')
            ->assertUnauthorized()
            ->assertJson([
                'kode' => 'kredensial_salah',
                'message' => 'Email/nomor telepon atau kata sandi salah.',
            ]);
        $this->masuk('tidak@ada.id')->assertUnauthorized();
    }

    public function test_terlalu_banyak_percobaan_dikunci_sementara(): void
    {
        $this->pelanggan();

        for ($i = 0; $i < 5; $i++) {
            $this->masuk('dina@contoh.id', sandi: 'salah12345')->assertUnauthorized();
        }

        $this->masuk('dina@contoh.id')
            ->assertStatus(429)
            ->assertJsonPath('kode', 'terlalu_banyak_percobaan');
    }

    public function test_peran_harus_sesuai_akun(): void
    {
        $this->pelanggan();

        $this->masuk('dina@contoh.id', 'teknisi')
            ->assertForbidden()
            ->assertJson([
                'kode' => 'peran_tidak_sesuai',
                'message' => 'Akun ini terdaftar sebagai Pelanggan. Pilih peran Pelanggan untuk masuk.',
            ]);
    }

    public function test_admin_tidak_bisa_masuk_lewat_aplikasi(): void
    {
        $this->pelanggan(['email' => 'admin@contoh.id', 'no_telepon' => '081200000001', 'role' => 'admin']);

        $this->masuk('admin@contoh.id')->assertForbidden()->assertJsonPath('kode', 'peran_tidak_sesuai');
    }

    public function test_akun_diblokir_tidak_bisa_masuk(): void
    {
        $this->pelanggan(['status_akun' => 'diblokir']);

        $this->masuk('dina@contoh.id')->assertForbidden()->assertJsonPath('kode', 'akun_diblokir');
    }

    public function test_teknisi_menunggu_verifikasi_belum_bisa_masuk(): void
    {
        $this->teknisi('menunggu');

        $this->masuk('rizky@contoh.id', 'teknisi')
            ->assertForbidden()
            ->assertJsonPath('kode', 'belum_terverifikasi');
    }

    public function test_teknisi_ditolak_melihat_alasan(): void
    {
        $this->teknisi('ditolak', 'Foto KTP buram, silakan daftar ulang.');

        $this->masuk('rizky@contoh.id', 'teknisi')
            ->assertForbidden()
            ->assertJson([
                'kode' => 'verifikasi_ditolak',
                'alasan' => 'Foto KTP buram, silakan daftar ulang.',
            ]);
    }

    public function test_teknisi_terverifikasi_bisa_masuk(): void
    {
        $this->teknisi();

        $this->masuk('rizky@contoh.id', 'teknisi')
            ->assertOk()
            ->assertJsonPath('pengguna.teknisi.jenis_kendaraan', 'Honda Beat');
    }

    // ---------- Keluar ----------

    public function test_keluar_hanya_menghapus_token_perangkat_ini(): void
    {
        $this->pelanggan();
        $tokenHp = $this->masuk('dina@contoh.id')->json('token');
        $tokenTablet = $this->masuk('dina@contoh.id')->json('token');

        $this->withToken($tokenHp)->postJson('/api/keluar')->assertOk();

        $this->assertSame(1, Pengguna::first()->tokens()->count());
        $this->app['auth']->forgetGuards();
        $this->withToken($tokenHp)->getJson('/api/saya')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $this->withToken($tokenTablet)->getJson('/api/saya')->assertOk();
    }

    public function test_akun_yang_diblokir_saat_masuk_langsung_dikeluarkan(): void
    {
        $p = $this->pelanggan();
        $token = $this->masuk('dina@contoh.id')->json('token');
        $p->update(['status_akun' => 'diblokir']);

        $this->withToken($token)->getJson('/api/saya')
            ->assertForbidden()
            ->assertJsonPath('kode', 'akun_diblokir');
        $this->assertSame(0, $p->tokens()->count());
    }

    public function test_token_kedaluwarsa_setelah_30_hari(): void
    {
        $this->pelanggan();
        $token = $this->masuk('dina@contoh.id')->json('token');

        $this->travel(31)->days();

        $this->withToken($token)->getJson('/api/saya')->assertUnauthorized();
    }
}
