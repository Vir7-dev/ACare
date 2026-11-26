<?php

namespace Tests\Feature\Api;

use App\Models\Layanan;
use App\Models\Pembayaran;
use App\Models\Pendapatan;
use App\Models\Pengguna;
use App\Models\Pesanan;
use Database\Seeders\LayananSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class AlurTeknisiApiTest extends TestCase
{
    use RefreshDatabase;

    private Pengguna $pelanggan;

    /** Lokasi pelanggan: Batam Centre. */
    private const LAT = 1.1283;

    private const LNG = 104.0530;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(LayananSeeder::class);
        $this->freezeSecond();
        Storage::fake('local');
        $this->pelanggan = $this->akun('pelanggan', 'dina');
        $this->pelanggan->lokasi()->create([
            'label_alamat' => 'Rumah', 'alamat_lengkap' => 'Jl. Engku Putri No. 12',
            'latitude' => self::LAT, 'longitude' => self::LNG,
        ]);
    }

    private function akun(string $role, string $nama): Pengguna
    {
        static $no = 10;
        $no++;

        return Pengguna::create([
            'nama' => ucfirst($nama), 'email' => "$nama@contoh.id", 'no_telepon' => '0812000000'.$no,
            'kata_sandi' => 'rahasia123', 'role' => $role,
        ]);
    }

    /** Teknisi terverifikasi, online, di titik tertentu. */
    private function teknisi(string $nama, float $lat, float $lng, array $ubah = []): Pengguna
    {
        $p = $this->akun('teknisi', $nama);
        $p->teknisi()->create([
            'jenis_kendaraan' => 'Honda Beat', 'plat_nomor' => 'BP 1 AA', 'nama_bank' => 'BNI',
            'no_rekening' => '123456', 'atas_nama' => $nama, 'status_verifikasi' => 'terverifikasi',
            'status_ketersediaan' => 'tersedia', 'latitude' => $lat, 'longitude' => $lng,
            'lokasi_diperbarui_pada' => now(), ...$ubah,
        ]);

        return $p;
    }

    /** Kirim permintaan sebagai pengguna tertentu (guard dibersihkan tiap kali). */
    private function sebagai(Pengguna $p): static
    {
        $this->app['auth']->forgetGuards();

        return $this->actingAs($p, 'sanctum');
    }

    /** Pelanggan memesan lalu membayar biaya awal (simulasi). */
    private function pesanDanBayar(string $layanan = 'Service AC'): int
    {
        $res = $this->sebagai($this->pelanggan)->postJson('/api/pesanan', [
            'id_layanan' => Layanan::where('nama_layanan', $layanan)->value('id_layanan'),
            'jumlah_unit' => 1, 'jenis_ac' => 'split', 'pk' => 1,
            'id_lokasi' => $this->pelanggan->lokasi()->value('id_lokasi'),
            'jadwal_service' => now()->toIso8601String(),
        ])->assertCreated();
        $id = $res->json('data.id');

        $this->sebagai($this->pelanggan)
            ->postJson("/api/pesanan/{$id}/pembayaran/{$res->json('data.pembayaran.0.id')}/simulasi-lunas")
            ->assertOk()->assertJsonPath('data.pembayaran.0.status', 'berhasil');

        return $id;
    }

    private function tawaranUntuk(Pengguna $t): TestResponse
    {
        return $this->sebagai($t)->getJson('/api/teknisi/tawaran');
    }

    private function sampaiPengecekan(Pengguna $t, int $id): void
    {
        $this->sebagai($t)->postJson("/api/teknisi/tawaran/{$id}/terima")->assertOk();
        $this->sebagai($t)->postJson("/api/teknisi/pekerjaan/{$id}/tiba")->assertOk()->assertJsonPath('data.status', 'tiba');
        $this->sebagai($t)->postJson("/api/teknisi/pekerjaan/{$id}/pengecekan")->assertOk()
            ->assertJsonPath('data.status', 'pengecekan_awal');
    }

    private function selesaikan(Pengguna $t, int $id): TestResponse
    {
        return $this->sebagai($t)->post("/api/teknisi/pekerjaan/{$id}/selesai", [
            'foto_sebelum' => UploadedFile::fake()->image('a.jpg'),
            'foto_sesudah' => UploadedFile::fake()->image('b.jpg'),
            'catatan' => 'Kapasitor diganti, AC dingin kembali.',
        ], ['Accept' => 'application/json']);
    }

    // ---------- Tawaran ----------

    public function test_pesanan_belum_dibayar_tidak_ditawarkan(): void
    {
        $t = $this->teknisi('andi', 1.13, 104.05);
        $this->sebagai($this->pelanggan)->postJson('/api/pesanan', [
            'id_layanan' => 1, 'jumlah_unit' => 1, 'jenis_ac' => 'split', 'pk' => 1,
            'id_lokasi' => $this->pelanggan->lokasi()->value('id_lokasi'),
            'jadwal_service' => now()->toIso8601String(),
        ])->assertCreated();

        $this->tawaranUntuk($t)->assertOk()->assertJsonPath('data', null);
    }

    public function test_ditawarkan_ke_teknisi_terdekat_yang_memenuhi_syarat(): void
    {
        $jauh = $this->teknisi('budi', 1.16, 104.08);           // ~4,6 km
        $dekat = $this->teknisi('andi', 1.135, 104.045);        // ~1,2 km
        $offline = $this->teknisi('cici', 1.1284, 104.0531, ['status_ketersediaan' => 'tidak_tersedia']);
        $lama = $this->teknisi('dedi', 1.1285, 104.0532, ['lokasi_diperbarui_pada' => now()->subHour()]);
        $belum = $this->teknisi('eko', 1.1286, 104.0533, ['status_verifikasi' => 'menunggu']);
        $id = $this->pesanDanBayar();

        $this->tawaranUntuk($dekat)->assertOk()
            ->assertJsonPath('data.id', $id)
            ->assertJsonPath('data.layanan', 'Service AC')
            ->assertJsonPath('data.bisa_biaya_tambahan', true)
            ->assertJsonPath('data.biaya_awal', 100000)
            ->assertJsonPath('data.pelanggan.nama', 'Dina')
            ->assertJsonPath('data.pelanggan.no_telepon', null)
            ->assertJsonPath('data.tawaran.sisa_detik', 30);
        $this->assertEqualsWithDelta(1.2, $this->tawaranUntuk($dekat)->json('data.jarak_km'), 0.3);

        foreach ([$jauh, $offline, $lama] as $t) {
            $this->tawaranUntuk($t)->assertJsonPath('data', null);
        }
        $this->sebagai($belum)->getJson('/api/teknisi/tawaran')->assertForbidden();
    }

    public function test_ditolak_atau_lewat_batas_pindah_ke_teknisi_berikutnya(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $b = $this->teknisi('budi', 1.16, 104.08);
        $id = $this->pesanDanBayar();

        $this->sebagai($a)->postJson("/api/teknisi/tawaran/{$id}/tolak")->assertOk();
        $this->tawaranUntuk($b)->assertJsonPath('data.id', $id);

        // Budi tidak menjawab 30 detik: pesanan kembali dicari, Andi sudah menolak.
        $this->travel(31)->seconds();
        $this->tawaranUntuk($b)->assertJsonPath('data', null);
        $this->tawaranUntuk($a)->assertJsonPath('data', null);
        $this->assertEqualsCanonicalizing(
            [$a->id_pengguna, $b->id_pengguna],
            Pesanan::find($id)->teknisi_menolak,
        );
    }

    public function test_terima_tawaran_teknisi_tampil_ke_pelanggan(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar();

        $this->sebagai($a)->postJson("/api/teknisi/tawaran/{$id}/terima")->assertOk()
            ->assertJsonPath('data.status', 'menuju_lokasi')
            ->assertJsonPath('data.pelanggan.no_telepon', $this->pelanggan->no_telepon);

        $this->sebagai($this->pelanggan)->getJson("/api/pesanan/{$id}")->assertOk()
            ->assertJsonPath('data.status', 'menuju_lokasi')
            ->assertJsonPath('data.label_status', 'Teknisi Menuju Lokasi')
            ->assertJsonPath('data.teknisi.nama', 'Andi')
            ->assertJsonPath('data.teknisi.plat_nomor', 'BP 1 AA')
            ->assertJsonPath('data.teknisi.lokasi.latitude', 1.135)
            ->assertJsonPath('data.bisa_dibatalkan', false);
    }

    public function test_tawaran_kedaluwarsa_tidak_bisa_diterima(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar();
        $this->travel(31)->seconds();

        $this->sebagai($a)->postJson("/api/teknisi/tawaran/{$id}/terima")
            ->assertStatus(409)->assertJsonPath('kode', 'tawaran_tidak_berlaku');
    }

    public function test_teknisi_yang_sedang_bekerja_tidak_ditawari(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar();
        $this->sebagai($a)->postJson("/api/teknisi/tawaran/{$id}/terima")->assertOk();

        $lain = $this->akun('pelanggan', 'eka');
        $lain->lokasi()->create(['label_alamat' => 'R', 'alamat_lengkap' => 'X', 'latitude' => self::LAT, 'longitude' => self::LNG]);
        $this->pelanggan = $lain;
        $this->pesanDanBayar();

        $this->tawaranUntuk($a)->assertJsonPath('data', null);
        $this->sebagai($a)->putJson('/api/teknisi/status', ['online' => false])
            ->assertStatus(409)->assertJsonPath('kode', 'masih_ada_pekerjaan');
    }

    public function test_tanpa_teknisi_selama_15_menit_pesanan_batal_dana_tertahan(): void
    {
        $id = $this->pesanDanBayar();
        $this->travel(16)->minutes();

        $this->artisan('pesanan:proses')->assertSuccessful();

        $this->sebagai($this->pelanggan)->getJson("/api/pesanan/{$id}")
            ->assertJsonPath('data.status', 'dibatalkan')
            ->assertJsonPath('data.alasan_pembatalan', 'Tidak ada teknisi yang menerima dalam batas waktu')
            ->assertJsonPath('data.pembayaran.0.status', 'tertahan');
    }

    // ---------- Pekerjaan ----------

    public function test_alur_lengkap_dengan_biaya_tambahan_disetujui_dan_pelunasan(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar();
        $this->sampaiPengecekan($a, $id);

        $this->sebagai($a)->post("/api/teknisi/pekerjaan/{$id}/foto-pemeriksaan",
            ['foto' => UploadedFile::fake()->image('cek.jpg')], ['Accept' => 'application/json'])
            ->assertOk()->assertJsonPath('data.foto.0.tahap', 'pemeriksaan');

        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/biaya", [
            'item' => [
                ['nama' => 'Ganti kapasitor', 'jenis' => 'suku_cadang', 'harga' => 85000],
                ['nama' => 'Jasa penggantian', 'jenis' => 'jasa', 'harga' => 50000],
            ],
            'catatan' => 'Kapasitor lemah.',
        ])->assertOk()->assertJsonPath('data.status', 'menunggu_persetujuan_biaya');

        $this->sebagai($this->pelanggan)->getJson("/api/pesanan/{$id}")
            ->assertJsonPath('data.label_status', 'Pengecekan')
            ->assertJsonPath('data.biaya.status_biaya', 'menunggu')
            ->assertJsonPath('data.biaya.rincian.1.ditagih', false)
            ->assertJsonPath('data.biaya.catatan_teknisi', 'Kapasitor lemah.');

        $this->sebagai($this->pelanggan)->postJson("/api/pesanan/{$id}/biaya", ['setuju' => true])
            ->assertOk()
            ->assertJsonPath('data.status', 'dikerjakan')
            ->assertJsonPath('data.biaya.total', 235000)
            ->assertJsonPath('data.biaya.rincian.1.ditagih', true);

        $this->selesaikan($a, $id)->assertOk()->assertJsonPath('data.status', 'menunggu_pembayaran');

        $res = $this->sebagai($this->pelanggan)->getJson("/api/pesanan/{$id}")
            ->assertJsonPath('data.pembayaran.1.jenis', 'pelunasan')
            ->assertJsonPath('data.pembayaran.1.jumlah', 135000)
            ->assertJsonPath('data.pembayaran.1.status', 'menunggu');

        $this->sebagai($this->pelanggan)
            ->postJson("/api/pesanan/{$id}/pembayaran/{$res->json('data.pembayaran.1.id')}/simulasi-lunas")
            ->assertOk()->assertJsonPath('data.status', 'selesai');

        $p = Pendapatan::where('id_pesanan', $id)->first();
        $this->assertSame(23500.0, (float) $p->pendapatan_platform);
        $this->assertSame(211500.0, (float) $p->pendapatan_teknisi);
        $this->assertCount(3, Pesanan::find($id)->fotoBukti);
    }

    public function test_biaya_tidak_ditanggapi_5_menit_dianggap_ditolak(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar('Cek AC');
        $this->sampaiPengecekan($a, $id);
        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/biaya", [
            'item' => [['nama' => 'Isi freon', 'jenis' => 'jasa', 'harga' => 150000]],
        ])->assertOk();

        $this->travel(6)->minutes();

        $this->sebagai($this->pelanggan)->postJson("/api/pesanan/{$id}/biaya", ['setuju' => true])
            ->assertStatus(409)->assertJsonPath('kode', 'tidak_ada_persetujuan');
        $this->sebagai($a)->getJson('/api/teknisi/pekerjaan')
            ->assertJsonPath('data.status', 'dikerjakan')
            ->assertJsonPath('data.biaya.status_biaya', 'ditolak')
            ->assertJsonPath('data.biaya.total', 50000);

        // Tanpa biaya tambahan: selesai langsung, tanpa pelunasan.
        $this->selesaikan($a, $id)->assertOk()->assertJsonPath('data.status', 'selesai');
        $this->assertSame(45000.0, (float) Pendapatan::where('id_pesanan', $id)->value('pendapatan_teknisi'));
        $this->assertSame(1, Pembayaran::where('id_pesanan', $id)->count());
    }

    public function test_layanan_tanpa_biaya_tambahan_langsung_dikerjakan(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar('Cuci AC');
        $this->sampaiPengecekan($a, $id);

        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/biaya", [
            'item' => [['nama' => 'X', 'jenis' => 'jasa', 'harga' => 10000]],
        ])->assertUnprocessable()->assertJsonPath('kode', 'tanpa_biaya_tambahan');

        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/tanpa-biaya")
            ->assertOk()->assertJsonPath('data.status', 'dikerjakan');
        $this->selesaikan($a, $id)->assertOk()->assertJsonPath('data.status', 'selesai');
    }

    public function test_langkah_harus_berurutan_dan_bukti_wajib(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar();
        $this->sebagai($a)->postJson("/api/teknisi/tawaran/{$id}/terima")->assertOk();

        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/pengecekan")->assertStatus(409)
            ->assertJson(['message' => 'Langkah ini tidak sesuai dengan status pesanan saat ini.']);
        // Bukti lengkap pun ditolak bila pekerjaan belum sampai tahap dikerjakan.
        $this->selesaikan($a, $id)->assertStatus(409);
        $this->assertCount(0, Pesanan::find($id)->fotoBukti);

        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/tiba")->assertOk();
        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/pengecekan")->assertOk();
        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/tanpa-biaya")->assertOk();
        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/selesai", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'foto_sebelum' => 'Foto sebelum wajib diisi.',
                'catatan' => 'Catatan pengerjaan wajib diisi.',
            ]);
    }

    public function test_foto_bukti_hanya_untuk_pelanggan_dan_teknisinya(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045);
        $id = $this->pesanDanBayar('Cuci AC');
        $this->sampaiPengecekan($a, $id);
        $this->sebagai($a)->postJson("/api/teknisi/pekerjaan/{$id}/tanpa-biaya")->assertOk();
        $idFoto = $this->selesaikan($a, $id)->json('data.foto.0.id');

        $this->sebagai($this->pelanggan)->get("/api/pesanan/{$id}/foto/{$idFoto}")->assertOk();
        $this->sebagai($a)->get("/api/pesanan/{$id}/foto/{$idFoto}")->assertOk();
        $this->sebagai($this->akun('pelanggan', 'asing'))->getJson("/api/pesanan/{$id}/foto/{$idFoto}")->assertNotFound();
    }

    public function test_online_wajib_kirim_lokasi(): void
    {
        $a = $this->teknisi('andi', 1.135, 104.045, ['status_ketersediaan' => 'tidak_tersedia']);

        $this->sebagai($a)->putJson('/api/teknisi/status', ['online' => true])
            ->assertUnprocessable()->assertJsonValidationErrors(['latitude']);
        $this->sebagai($a)->putJson('/api/teknisi/status', ['online' => true, 'latitude' => 1.14, 'longitude' => 104.04])
            ->assertOk()->assertJsonPath('data.online', true)->assertJsonPath('data.latitude', 1.14);
    }

    public function test_pelanggan_tidak_bisa_memakai_rute_teknisi(): void
    {
        $this->sebagai($this->pelanggan)->getJson('/api/teknisi/tawaran')
            ->assertForbidden()->assertJsonPath('kode', 'peran_tidak_sesuai');
    }
}
