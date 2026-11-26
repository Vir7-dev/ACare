<?php

namespace Tests\Feature\Api;

use App\Models\DetailPesanan;
use App\Models\Pendapatan;
use App\Models\PengajuanDana;
use App\Models\Pengguna;
use App\Models\Pesanan;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/** Dompet teknisi: saldo, riwayat pekerjaan, dan pengajuan pencairan. */
class DompetTeknisiTest extends TestCase
{
    use RefreshDatabase;

    private Pengguna $pelanggan;

    private Pengguna $teknisi;

    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        // 10:00 WIB = 03:00 UTC.
        $this->travelTo(Carbon::parse('2026-11-26 03:00:00', 'UTC'));
        $this->pelanggan = Pengguna::create([
            'nama' => 'Dina', 'email' => 'dina@contoh.id', 'no_telepon' => '081111111111',
            'kata_sandi' => 'rahasia123', 'role' => 'pelanggan',
        ]);
        $this->pelanggan->lokasi()->create([
            'label_alamat' => 'Rumah', 'alamat_lengkap' => 'Jl. Engku Putri No. 12, Batam',
            'latitude' => 1.1283, 'longitude' => 104.053,
        ]);
        $this->teknisi = Pengguna::create([
            'nama' => 'Andi', 'email' => 'andi@contoh.id', 'no_telepon' => '082222222222',
            'kata_sandi' => 'rahasia123', 'role' => 'teknisi',
        ]);
        $this->teknisi->teknisi()->create([
            'jenis_kendaraan' => 'Honda Beat', 'plat_nomor' => 'BP 1 AA', 'nama_bank' => 'BNI',
            'no_rekening' => '1234567890', 'atas_nama' => 'Andi', 'status_verifikasi' => 'terverifikasi',
        ]);
        $this->token = $this->teknisi->createToken('hp')->plainTextToken;
    }

    /** Pesanan selesai milik teknisi dengan bagi hasil 10%. */
    private function selesai(int $totalDibayar, string $waktu, ?int $rating = null): Pesanan
    {
        $p = Pesanan::create([
            'id_pelanggan' => $this->pelanggan->id_pengguna,
            'id_lokasi' => $this->pelanggan->lokasi()->value('id_lokasi'),
            'id_teknisi' => $this->teknisi->id_pengguna,
            'jadwal_service' => now(),
            'status_pesanan' => Pesanan::SELESAI,
            'selesai_pada' => Carbon::parse($waktu, 'UTC'),
            'total_biaya' => $totalDibayar,
        ]);
        $p->detail()->create([
            'jenis_item' => DetailPesanan::JENIS_LAYANAN, 'nama_item' => 'Service AC', 'jumlah' => 1, 'harga' => $totalDibayar,
        ]);
        $pendapatan = Pendapatan::create([
            'id_pesanan' => $p->id_pesanan, 'id_teknisi' => $this->teknisi->id_pengguna,
            'persentase_platform' => 10, ...Pendapatan::hitung($totalDibayar, 10),
        ]);
        $pendapatan->forceFill(['dibuat_pada' => Carbon::parse($waktu, 'UTC')])->save();
        if ($rating) {
            $p->ratingUlasan()->create(['rating' => $rating, 'ulasan' => 'Bagus']);
        }

        return $p;
    }

    public function test_dompet_menghitung_saldo_dan_pendapatan_hari_ini_waktu_wib(): void
    {
        // Kemarin 23:30 WIB (16:30 UTC) bukan hari ini; 00:30 WIB (17:30 UTC) hari ini.
        $this->selesai(200000, '2026-11-25 16:30:00');
        $this->selesai(100000, '2026-11-25 17:30:00');
        PengajuanDana::create([
            'jenis' => 'pencairan', 'id_pemohon' => $this->teknisi->id_pengguna, 'nominal' => 60000,
            'nama_bank' => 'BNI', 'no_rekening' => '1', 'atas_nama' => 'Andi', 'status' => 'ditolak',
            'alasan_penolakan' => 'Rekening tidak sesuai',
        ]);
        PengajuanDana::create([
            'jenis' => 'pencairan', 'id_pemohon' => $this->teknisi->id_pengguna, 'nominal' => 50000,
            'nama_bank' => 'BNI', 'no_rekening' => '1', 'atas_nama' => 'Andi',
        ]);

        $this->withToken($this->token)->getJson('/api/teknisi/dompet')
            ->assertOk()
            // 180.000 + 90.000 - 50.000 (yang ditolak tidak dihitung).
            ->assertJsonPath('data.saldo', 220000)
            ->assertJsonPath('data.pendapatan_hari_ini', 90000)
            ->assertJsonPath('data.total_pendapatan', 270000)
            ->assertJsonPath('data.minimum_pencairan', 50000)
            ->assertJsonPath('data.rekening.no_rekening', '1234567890')
            ->assertJsonCount(2, 'data.pencairan')
            ->assertJsonPath('data.pencairan.1.label_status', 'Ditolak')
            ->assertJsonPath('data.pencairan.1.alasan_penolakan', 'Rekening tidak sesuai');
    }

    public function test_riwayat_pekerjaan_selesai_terbaru_dulu(): void
    {
        $lama = $this->selesai(200000, '2026-11-20 05:00:00', rating: 5);
        $this->selesai(75000, '2026-11-24 05:00:00');

        $this->withToken($this->token)->getJson('/api/teknisi/riwayat')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.diterima', 67500)
            ->assertJsonPath('data.0.rating', null)
            ->assertJsonPath('data.1.kode', $lama->kode)
            ->assertJsonPath('data.1.layanan', 'Service AC')
            ->assertJsonPath('data.1.nama_pelanggan', 'Dina')
            ->assertJsonPath('data.1.wilayah', 'Rumah')
            ->assertJsonPath('data.1.total_dibayar', 200000)
            ->assertJsonPath('data.1.potongan_platform', 20000)
            ->assertJsonPath('data.1.diterima', 180000)
            ->assertJsonPath('data.1.rating', 5);
    }

    public function test_ajukan_pencairan_memotong_saldo_dan_menyalin_rekening(): void
    {
        $this->selesai(200000, '2026-11-25 05:00:00');

        $this->withToken($this->token)->postJson('/api/teknisi/pencairan', ['nominal' => 100000])
            ->assertCreated()
            ->assertJsonPath('data.saldo', 80000)
            ->assertJsonPath('data.pencairan.0.nominal', 100000)
            ->assertJsonPath('data.pencairan.0.status', 'menunggu')
            ->assertJsonPath('data.pencairan.0.label_status', 'Menunggu')
            ->assertJsonPath('data.pencairan.0.rekening', 'BNI • 1234567890 a.n Andi');

        // Rekening di profil berubah: pengajuan lama tetap ke rekening lama.
        $this->teknisi->teknisi()->update(['no_rekening' => '999']);
        $this->assertSame('1234567890', PengajuanDana::first()->no_rekening);
    }

    public function test_pencairan_ditolak_bila_di_bawah_minimum_atau_melebihi_saldo(): void
    {
        $this->selesai(100000, '2026-11-25 05:00:00'); // saldo 90.000

        $this->withToken($this->token)->postJson('/api/teknisi/pencairan', ['nominal' => 30000])
            ->assertUnprocessable()->assertJsonPath('errors.nominal.0', 'Minimal pencairan Rp50.000.');
        $this->withToken($this->token)->postJson('/api/teknisi/pencairan', ['nominal' => 95000])
            ->assertUnprocessable()->assertJsonPath('kode', 'saldo_tidak_cukup');
        $this->withToken($this->token)->postJson('/api/teknisi/pencairan', ['nominal' => 90000])
            ->assertCreated()->assertJsonPath('data.saldo', 0);
        $this->withToken($this->token)->postJson('/api/teknisi/pencairan', ['nominal' => 50000])
            ->assertUnprocessable()->assertJsonPath('kode', 'saldo_tidak_cukup');

        $this->assertSame(1, PengajuanDana::count());
    }

    public function test_pencairan_butuh_rekening_lengkap(): void
    {
        $this->selesai(100000, '2026-11-25 05:00:00');
        $this->teknisi->teknisi()->update(['no_rekening' => '']);

        $this->withToken($this->token)->postJson('/api/teknisi/pencairan', ['nominal' => 50000])
            ->assertUnprocessable()->assertJsonPath('kode', 'rekening_belum_lengkap');
    }

    public function test_pelanggan_tidak_bisa_membuka_dompet_teknisi(): void
    {
        $token = $this->pelanggan->createToken('hp')->plainTextToken;
        $this->withToken($token)->getJson('/api/teknisi/dompet')->assertForbidden();
    }
}
