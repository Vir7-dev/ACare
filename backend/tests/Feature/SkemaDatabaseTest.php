<?php

namespace Tests\Feature;

use App\Models\DetailPesanan;
use App\Models\FotoBuktiPengerjaan;
use App\Models\Layanan;
use App\Models\Lokasi;
use App\Models\Pembayaran;
use App\Models\Pendapatan;
use App\Models\Pengaduan;
use App\Models\PengajuanDana;
use App\Models\Pengguna;
use App\Models\Pesanan;
use App\Models\Teknisi;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SkemaDatabaseTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    private function pelanggan(): Pengguna
    {
        return Pengguna::where('email', 'pelanggan@acare.id')->firstOrFail();
    }

    private function teknisi(): Teknisi
    {
        return Pengguna::where('email', 'teknisi@acare.id')->firstOrFail()->teknisi;
    }

    private function buatPesanan(array $data = []): Pesanan
    {
        $pelanggan = $this->pelanggan();

        return Pesanan::create(array_merge([
            'id_pelanggan' => $pelanggan->id_pengguna,
            'id_lokasi' => $pelanggan->lokasi()->first()->id_lokasi,
            'jadwal_service' => now()->addHour(),
            'jenis_ac' => 'split',
            'pk' => 1.5,
        ], $data));
    }

    public function test_seeder_mengisi_lima_layanan_dan_akun_tiap_peran(): void
    {
        $this->assertSame(5, Layanan::count());
        $this->assertEqualsCanonicalizing(
            ['admin', 'pelanggan', 'teknisi'],
            Pengguna::pluck('role')->all(),
        );
        $this->assertTrue(Hash::check('password', $this->pelanggan()->kata_sandi));
    }

    public function test_alur_pesanan_sampai_pendapatan_dan_pencairan(): void
    {
        $layanan = Layanan::where('nama_layanan', 'Service AC')->firstOrFail();
        $teknisi = $this->teknisi();
        $pesanan = $this->buatPesanan(['id_teknisi' => $teknisi->id_pengguna]);

        DetailPesanan::create([
            'id_pesanan' => $pesanan->id_pesanan, 'id_layanan' => $layanan->id_layanan,
            'nama_item' => $layanan->nama_layanan, 'harga' => $layanan->harga,
        ]);
        DetailPesanan::create([
            'id_pesanan' => $pesanan->id_pesanan, 'nama_item' => 'Isi Freon R32',
            'jenis_item' => DetailPesanan::JENIS_SUKU_CADANG, 'harga' => 150000,
        ]);
        $pesanan->update(['status_biaya' => Pesanan::BIAYA_DISETUJUI]);

        $total = $pesanan->hitungTotalBiaya();
        $this->assertSame(250000.0, $total);

        Pembayaran::create([
            'id_pesanan' => $pesanan->id_pesanan, 'jenis_pembayaran' => 'awal',
            'jumlah_bayar' => 100000, 'status_pembayaran' => 'berhasil',
        ]);

        $bagi = Pendapatan::hitung($total, (float) $layanan->persentase_platform);
        Pendapatan::create(array_merge([
            'id_pesanan' => $pesanan->id_pesanan,
            'id_teknisi' => $teknisi->id_pengguna,
            'persentase_platform' => $layanan->persentase_platform,
        ], $bagi));

        $this->assertSame(225000.0, $teknisi->saldo());

        PengajuanDana::create([
            'jenis' => PengajuanDana::PENCAIRAN, 'id_pemohon' => $teknisi->id_pengguna,
            'nominal' => 100000, 'nama_bank' => 'BNI', 'no_rekening' => '1234567890', 'atas_nama' => 'Teknisi Contoh',
        ]);
        PengajuanDana::create([
            'jenis' => PengajuanDana::PENCAIRAN, 'id_pemohon' => $teknisi->id_pengguna, 'status' => 'ditolak',
            'nominal' => 50000, 'nama_bank' => 'BNI', 'no_rekening' => '1234567890', 'atas_nama' => 'Teknisi Contoh',
        ]);

        // Pengajuan yang ditolak tidak mengurangi saldo.
        $this->assertSame(125000.0, $teknisi->saldo());
    }

    public function test_pendapatan_hanya_untuk_teknisi_pesanan_itu(): void
    {
        $pesanan = $this->buatPesanan(['id_teknisi' => $this->teknisi()->id_pengguna]);

        $lain = Pengguna::create([
            'nama' => 'Teknisi Lain', 'email' => 'lain@acare.id', 'no_telepon' => '081299999999',
            'kata_sandi' => 'password', 'role' => 'teknisi',
        ]);
        Teknisi::create([
            'id_pengguna' => $lain->id_pengguna, 'nama_bank' => 'BCA', 'no_rekening' => '1', 'atas_nama' => 'Lain',
        ]);

        $this->expectException(QueryException::class);
        Pendapatan::create([
            'id_pesanan' => $pesanan->id_pesanan, 'id_teknisi' => $lain->id_pengguna,
            'persentase_platform' => 10, 'pendapatan_platform' => 0, 'pendapatan_teknisi' => 0,
        ]);
    }

    public function test_pesanan_tidak_boleh_memakai_alamat_milik_orang_lain(): void
    {
        $orangLain = Pengguna::where('email', 'admin@acare.id')->firstOrFail();
        $alamatLain = Lokasi::create([
            'id_pengguna' => $orangLain->id_pengguna, 'label_alamat' => 'Kantor',
            'alamat_lengkap' => 'Nagoya, Batam', 'latitude' => 1.14, 'longitude' => 104.01,
        ]);

        $this->expectException(QueryException::class);
        $this->buatPesanan(['id_lokasi' => $alamatLain->id_lokasi]);
    }

    public function test_status_pelanggan_digabung_dan_aturan_pembatalan(): void
    {
        $pesanan = $this->buatPesanan();
        $this->assertTrue($pesanan->bisaDibatalkan());

        $pesanan->status_pesanan = Pesanan::TIBA;
        $this->assertSame('Teknisi Menuju Lokasi', $pesanan->label_status_pelanggan);
        $this->assertFalse($pesanan->bisaDibatalkan());

        $pesanan->status_pesanan = Pesanan::MENUNGGU_PERSETUJUAN_BIAYA;
        $this->assertSame('Pengecekan', $pesanan->label_status_pelanggan);

        $this->assertMatchesRegularExpression('/^AC-\d{6}$/', $pesanan->kode);
    }

    public function test_tawaran_menyimpan_daftar_teknisi_yang_menolak(): void
    {
        $pesanan = $this->buatPesanan(['teknisi_menolak' => [7, 9]]);

        $this->assertSame([7, 9], $pesanan->fresh()->teknisi_menolak);
    }

    public function test_pengaduan_sistem_tanpa_pesanan_dan_terlapor_dari_pesanan(): void
    {
        $pelanggan = $this->pelanggan();

        $aduanSistem = Pengaduan::create([
            'id_pelapor' => $pelanggan->id_pengguna, 'jenis_pengaduan' => 'Aplikasi Force Close',
            'deskripsi' => 'Aplikasi tertutup sendiri.', 'bukti' => ['a.png', 'b.png'],
        ]);
        $this->assertTrue($aduanSistem->isAduanSistem());
        $this->assertNull($aduanSistem->terlapor());
        $this->assertSame(['a.png', 'b.png'], $aduanSistem->fresh()->bukti);

        $teknisi = $this->teknisi();
        $pesanan = $this->buatPesanan(['id_teknisi' => $teknisi->id_pengguna]);
        $aduanLayanan = Pengaduan::create([
            'id_pelapor' => $pelanggan->id_pengguna, 'id_pesanan' => $pesanan->id_pesanan,
            'jenis_pengaduan' => 'Teknisi Datang Terlambat', 'deskripsi' => 'Terlambat 1 jam.',
        ]);
        $this->assertSame($teknisi->id_pengguna, $aduanLayanan->terlapor()->id_pengguna);
    }

    public function test_cek_ac_layanan_paling_ringan(): void
    {
        $cek = Layanan::where('nama_layanan', 'Cek AC')->firstOrFail();

        $this->assertSame(50000.0, (float) $cek->harga);
        $this->assertSame((float) Layanan::min('harga'), (float) $cek->harga);
    }

    public function test_biaya_teknisi_yang_ditolak_tidak_ditagih_tetapi_tersimpan(): void
    {
        $layanan = Layanan::where('nama_layanan', 'Cek AC')->firstOrFail();
        $pesanan = $this->buatPesanan(['id_teknisi' => $this->teknisi()->id_pengguna]);

        DetailPesanan::create([
            'id_pesanan' => $pesanan->id_pesanan, 'id_layanan' => $layanan->id_layanan,
            'nama_item' => $layanan->nama_layanan, 'harga' => $layanan->harga,
        ]);
        DetailPesanan::create([
            'id_pesanan' => $pesanan->id_pesanan, 'nama_item' => 'Las pipa',
            'jenis_item' => DetailPesanan::JENIS_JASA, 'harga' => 120000,
        ]);

        // Menunggu persetujuan: belum ditagih.
        $pesanan->update(['status_biaya' => Pesanan::BIAYA_MENUNGGU]);
        $this->assertSame(50000.0, $pesanan->hitungTotalBiaya());

        // Ditolak: tetap biaya awal, item teknisi tetap ada sebagai riwayat.
        $pesanan->update(['status_biaya' => Pesanan::BIAYA_DITOLAK, 'biaya_ditanggapi_pada' => now()]);
        $this->assertSame(50000.0, $pesanan->hitungTotalBiaya());
        $this->assertSame(2, $pesanan->detail()->count());
        $this->assertTrue($pesanan->detail()->where('jenis_item', 'jasa')->first()->dariTeknisi());

        // Disetujui: ikut ditagih.
        $pesanan->update(['status_biaya' => Pesanan::BIAYA_DISETUJUI]);
        $this->assertSame(170000.0, $pesanan->hitungTotalBiaya());
    }

    public function test_alamat_dihapus_lunak_dan_pesanan_lama_tetap_punya_alamat(): void
    {
        $pelanggan = $this->pelanggan();
        $alamat = $pelanggan->lokasi()->first();
        $pesanan = $this->buatPesanan(['status_pesanan' => Pesanan::MENUJU_LOKASI]);

        // Sedang dipakai pesanan berjalan: tidak boleh dihapus.
        $this->assertFalse($alamat->bisaDihapus());

        $pesanan->update(['status_pesanan' => Pesanan::SELESAI]);
        $this->assertTrue($alamat->bisaDihapus());

        $alamat->delete();
        $this->assertSame(0, $pelanggan->lokasi()->count());
        $this->assertNotNull(Lokasi::withTrashed()->find($alamat->id_lokasi)->dihapus_pada);
        $this->assertSame($alamat->alamat_lengkap, $pesanan->lokasi()->withTrashed()->first()->alamat_lengkap);
    }

    public function test_foto_kondisi_ac_dari_pelanggan(): void
    {
        $pesanan = $this->buatPesanan();

        $foto = FotoBuktiPengerjaan::create([
            'id_pesanan' => $pesanan->id_pesanan, 'tahap' => 'kondisi', 'path_foto' => 'kondisi/ac.jpg',
        ]);

        $this->assertSame('kondisi', $foto->fresh()->tahap);
    }

    public function test_penolakan_verifikasi_teknisi_menyimpan_alasan(): void
    {
        $admin = Pengguna::where('email', 'admin@acare.id')->firstOrFail();
        $teknisi = $this->teknisi();

        $teknisi->update([
            'status_verifikasi' => 'ditolak',
            'alasan_penolakan' => 'Foto KTP buram, mohon unggah ulang.',
            'diverifikasi_oleh' => $admin->id_pengguna,
            'diverifikasi_pada' => now(),
        ]);

        $teknisi->refresh();
        $this->assertSame('Foto KTP buram, mohon unggah ulang.', $teknisi->alasan_penolakan);
        $this->assertSame($admin->id_pengguna, $teknisi->verifikator->id_pengguna);
        $this->assertFalse($teknisi->isTerverifikasi());
    }

    public function test_login_api_memakai_token_sanctum_pada_tabel_pengguna(): void
    {
        $this->assertFalse(Schema::hasTable('users'));

        $token = $this->pelanggan()->createToken('mobile')->plainTextToken;

        $this->withToken($token)->getJson('/api/user')
            ->assertOk()
            ->assertJsonPath('email', 'pelanggan@acare.id')
            ->assertJsonMissingPath('kata_sandi');
    }

    public function test_pesanan_menyimpan_detail_lokasi_dan_isian_khusus_layanan(): void
    {
        $pesanan = $this->buatPesanan([
            'detail_lokasi' => 'Kamar tidur utama, lantai 2',
            'detail_layanan' => ['keluhan' => ['Tidak dingin', 'Bocor air']],
            'catatan_pelanggan' => 'Pagar warna hijau.',
        ])->fresh();

        $this->assertSame('Kamar tidur utama, lantai 2', $pesanan->detail_lokasi);
        $this->assertSame(['Tidak dingin', 'Bocor air'], $pesanan->detail_layanan['keluhan']);
        $this->assertSame('Pagar warna hijau.', $pesanan->catatan_pelanggan);
    }

    public function test_kendaraan_teknisi_terpisah_dan_tanpa_pengalaman(): void
    {
        $teknisi = $this->teknisi();

        $this->assertSame('Honda Beat', $teknisi->jenis_kendaraan);
        $this->assertSame('BP 1234 AC', $teknisi->plat_nomor);
        $this->assertFalse(Schema::hasColumn('teknisi', 'kendaraan'));
        $this->assertFalse(Schema::hasColumn('teknisi', 'pengalaman'));
    }

    public function test_batas_persetujuan_biaya_lima_menit(): void
    {
        // Database menyimpan waktu sampai detik.
        $this->freezeSecond();
        $pesanan = $this->buatPesanan(['id_teknisi' => $this->teknisi()->id_pengguna]);

        $pesanan->ajukanBiaya();
        $pesanan->save();

        $this->assertSame(Pesanan::MENUNGGU_PERSETUJUAN_BIAYA, $pesanan->status_pesanan);
        $this->assertTrue($pesanan->batas_persetujuan_biaya->equalTo(now()->addMinutes(5)));
        $this->assertFalse($pesanan->batasPersetujuanLewat());

        $this->travel(5)->minutes();
        $this->travel(1)->seconds();
        $this->assertTrue($pesanan->fresh()->batasPersetujuanLewat());
    }
}
