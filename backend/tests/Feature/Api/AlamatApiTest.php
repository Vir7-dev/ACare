<?php

namespace Tests\Feature\Api;

use App\Models\Lokasi;
use App\Models\Pengguna;
use App\Models\Pesanan;
use Database\Seeders\LayananSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AlamatApiTest extends TestCase
{
    use RefreshDatabase;

    private Pengguna $pelanggan;

    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(LayananSeeder::class);
        $this->pelanggan = Pengguna::create([
            'nama' => 'Dina', 'email' => 'dina@contoh.id', 'no_telepon' => '081111111111',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $this->token = $this->pelanggan->createToken('hp')->plainTextToken;
    }

    private function alamat(array $data = []): Lokasi
    {
        return $this->pelanggan->lokasi()->create([
            'label_alamat' => 'Rumah', 'alamat_lengkap' => 'Jl. Engku Putri No. 12, Batam',
            'latitude' => 1.1283, 'longitude' => 104.053, ...$data,
        ]);
    }

    private function pesananDengan(Lokasi $lokasi, string $status): Pesanan
    {
        return Pesanan::create([
            'id_pelanggan' => $this->pelanggan->id_pengguna, 'id_lokasi' => $lokasi->id_lokasi,
            'jadwal_service' => now(), 'status_pesanan' => $status,
        ]);
    }

    public function test_daftar_layanan_aktif_dengan_harga(): void
    {
        $this->withToken($this->token)->getJson('/api/layanan')
            ->assertOk()
            ->assertJsonCount(5, 'data')
            ->assertJsonPath('data.0.nama', 'Cuci AC')
            ->assertJsonPath('data.0.harga', 75000)
            ->assertJsonPath('data.0.bisa_biaya_tambahan', false)
            ->assertJsonPath('data.4.nama', 'Cek AC')
            ->assertJsonPath('data.4.bisa_biaya_tambahan', true);
    }

    public function test_tambah_dan_lihat_alamat_sendiri_saja(): void
    {
        $lain = Pengguna::create([
            'nama' => 'Lain', 'email' => 'lain@contoh.id', 'no_telepon' => '082222222222',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $lain->lokasi()->create(['label_alamat' => 'Kantor', 'alamat_lengkap' => 'X', 'latitude' => 1, 'longitude' => 104]);

        $this->withToken($this->token)->postJson('/api/alamat', [
            'label' => ' Rumah ', 'alamat_lengkap' => 'Perumahan Batu Aji Blok C No. 12',
            'latitude' => 1.0436, 'longitude' => 103.9806,
        ])->assertCreated()->assertJsonPath('data.label', 'Rumah');

        $this->withToken($this->token)->getJson('/api/alamat')
            ->assertOk()->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.latitude', 1.0436);
    }

    public function test_validasi_alamat_berbahasa_indonesia(): void
    {
        $this->withToken($this->token)->postJson('/api/alamat', ['latitude' => 200])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'label' => 'Label alamat wajib diisi.',
                'alamat_lengkap' => 'Alamat lengkap wajib diisi.',
                'latitude' => 'Titik lokasi tidak valid.',
            ]);
    }

    public function test_ubah_alamat_yang_belum_dipakai_langsung_diubah(): void
    {
        $a = $this->alamat();

        $this->withToken($this->token)->putJson("/api/alamat/{$a->id_lokasi}", [
            'label' => 'Rumah Ibu', 'alamat_lengkap' => 'Jl. Baru', 'latitude' => 1.1, 'longitude' => 104.1,
        ])->assertOk()->assertJsonPath('data.id', $a->id_lokasi)->assertJsonPath('data.label', 'Rumah Ibu');
    }

    public function test_ubah_alamat_yang_sudah_dipakai_membuat_alamat_baru(): void
    {
        $a = $this->alamat();
        $pesanan = $this->pesananDengan($a, Pesanan::SELESAI);

        $baru = $this->withToken($this->token)->putJson("/api/alamat/{$a->id_lokasi}", [
            'label' => 'Rumah', 'alamat_lengkap' => 'Jl. Pindahan No. 3', 'latitude' => 1.1, 'longitude' => 104.1,
        ])->assertOk()->json('data.id');

        $this->assertNotSame($a->id_lokasi, $baru);
        $this->assertSoftDeleted('lokasi', ['id_lokasi' => $a->id_lokasi]);
        // Riwayat pesanan tetap menunjuk alamat lama yang isinya tidak berubah.
        $this->assertSame('Jl. Engku Putri No. 12, Batam', $pesanan->fresh()->lokasi->alamat_lengkap);
        $this->withToken($this->token)->getJson('/api/alamat')->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.alamat_lengkap', 'Jl. Pindahan No. 3');
    }

    public function test_alamat_pesanan_aktif_tidak_bisa_dihapus(): void
    {
        $a = $this->alamat();
        $this->pesananDengan($a, Pesanan::MENUJU_LOKASI);

        $this->withToken($this->token)->deleteJson("/api/alamat/{$a->id_lokasi}")
            ->assertUnprocessable()->assertJsonPath('kode', 'alamat_dipakai');
    }

    public function test_hapus_alamat_tersembunyi_dari_daftar(): void
    {
        $a = $this->alamat();

        $this->withToken($this->token)->deleteJson("/api/alamat/{$a->id_lokasi}")->assertOk();

        $this->assertSoftDeleted('lokasi', ['id_lokasi' => $a->id_lokasi]);
        $this->withToken($this->token)->getJson('/api/alamat')->assertJsonCount(0, 'data');
    }

    public function test_alamat_orang_lain_tidak_ditemukan(): void
    {
        $lain = Pengguna::create([
            'nama' => 'Lain', 'email' => 'lain@contoh.id', 'no_telepon' => '082222222222',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $milikLain = $lain->lokasi()->create(['label_alamat' => 'Kantor', 'alamat_lengkap' => 'X', 'latitude' => 1, 'longitude' => 104]);

        $this->withToken($this->token)->deleteJson("/api/alamat/{$milikLain->id_lokasi}")
            ->assertNotFound()
            ->assertJson(['message' => 'Data tidak ditemukan.']);
    }

    public function test_teknisi_tidak_bisa_memakai_fitur_alamat(): void
    {
        $t = Pengguna::create([
            'nama' => 'Teknisi', 'email' => 't@contoh.id', 'no_telepon' => '083333333333',
            'kata_sandi' => 'rahasia123', 'role' => 'teknisi',
        ]);

        $this->withToken($t->createToken('hp')->plainTextToken)->getJson('/api/alamat')
            ->assertForbidden()->assertJsonPath('kode', 'peran_tidak_sesuai');
    }
}
