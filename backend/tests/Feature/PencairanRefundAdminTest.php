<?php

namespace Tests\Feature;

use App\Http\Controllers\Admin\PencairanController;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class PencairanRefundAdminTest extends TestCase
{
    /**
     * @param  array<string, mixed>  $ubah
     */
    private function kirim(array $ubah, bool $pulihkan = false): TestResponse
    {
        return $this->postJson(route('admin.pencairan.status'), [
            'pulihkan' => $pulihkan,
            'perubahan' => [$ubah],
        ]);
    }

    public function test_halaman_tampil_dengan_lencana_pengajuan_menunggu(): void
    {
        $response = $this->get(route('admin.pencairan'));

        $response->assertOk();
        $response->assertSee('Pencairan &amp; Refund', false);
        $response->assertSee('PCR-2611001');
        $response->assertSee('RFD-2611001');
        $response->assertSee('title="pengajuan menunggu keputusan">5</span>', false);
    }

    public function test_beranda_menampilkan_banner_pengajuan_menunggu(): void
    {
        $this->get(route('admin.dashboard'))
            ->assertOk()
            ->assertSee('5 pencairan &amp; refund menunggu', false);
    }

    public function test_nominal_pencairan_adalah_jumlah_pendapatan_pesanan(): void
    {
        $daftar = array_column(PencairanController::dataDasar(), null, 'id');

        $this->assertSame(739500, $daftar['PCR-2611001']['nominal']);
        $this->assertSame(365500, $daftar['PCR-2611002']['nominal']);
        $this->assertSame(100000, $daftar['RFD-2611001']['nominal']);
    }

    public function test_setujui_lalu_tandai_selesai_ditransfer_butuh_referensi(): void
    {
        $this->kirim(['id' => 'PCR-2611001', 'status' => 'Disetujui'])
            ->assertOk()->assertJson(['ok' => true, 'menunggu' => 4]);

        $sesi = ['admin_status' => ['pencairan' => [
            'PCR-2611001' => ['status' => 'Disetujui', 'alasan' => null, 'referensi' => null, 'waktu_transfer' => null],
        ]]];

        $this->withSession($sesi)
            ->postJson(route('admin.pencairan.status'), [
                'perubahan' => [['id' => 'PCR-2611001', 'status' => 'Selesai Ditransfer', 'referensi' => ' ']],
            ])
            ->assertStatus(422)
            ->assertJson(['pesan' => 'Referensi transfer wajib diisi.']);

        $selesai = $this->withSession($sesi)
            ->postJson(route('admin.pencairan.status'), [
                'perubahan' => [['id' => 'PCR-2611001', 'status' => 'Selesai Ditransfer', 'referensi' => 'TF-BCA-261110-0021']],
            ]);

        $selesai->assertOk();
        $selesai->assertJsonPath('catatan.PCR-2611001.referensi', 'TF-BCA-261110-0021');
        $selesai->assertJsonPath('catatan.PCR-2611001.status', 'Selesai Ditransfer');
        $this->assertStringContainsString('WIB', $selesai->json('catatan.PCR-2611001.waktu_transfer'));
    }

    public function test_tidak_bisa_melompat_dari_menunggu_ke_selesai_ditransfer(): void
    {
        $this->kirim(['id' => 'PCR-2611001', 'status' => 'Selesai Ditransfer', 'referensi' => 'TF-1'])
            ->assertStatus(422)
            ->assertJson(['pesan' => 'Pengajuan PCR-2611001 tidak bisa diubah dari Menunggu ke Selesai Ditransfer.']);
    }

    public function test_pengajuan_yang_sudah_selesai_tidak_bisa_diubah(): void
    {
        $this->kirim(['id' => 'PCR-2610008', 'status' => 'Ditolak', 'alasan' => 'Salah'])
            ->assertStatus(422);
        $this->kirim(['id' => 'PCR-2610003', 'status' => 'Disetujui'])
            ->assertStatus(422);
    }

    public function test_penolakan_wajib_disertai_alasan_dan_tersimpan(): void
    {
        $this->kirim(['id' => 'RFD-2611001', 'status' => 'Ditolak', 'alasan' => ''])
            ->assertStatus(422)
            ->assertJson(['pesan' => 'Alasan penolakan wajib diisi.']);

        $response = $this->kirim(['id' => 'RFD-2611001', 'status' => 'Ditolak', 'alasan' => 'Rekening tidak valid.']);

        $response->assertOk()->assertJson(['menunggu' => 4]);
        $response->assertSessionHas('admin_status.pencairan.RFD-2611001', [
            'status' => 'Ditolak',
            'alasan' => 'Rekening tidak valid.',
            'referensi' => null,
            'waktu_transfer' => null,
        ]);
    }

    public function test_pengajuan_tidak_dikenal_dan_status_tidak_valid_ditolak(): void
    {
        $this->kirim(['id' => 'PCR-0000000', 'status' => 'Disetujui'])->assertNotFound();
        $this->kirim(['id' => 'PCR-2611001', 'status' => 'Dibayar'])->assertStatus(422);
    }

    public function test_pulihkan_mengembalikan_status_sebelumnya(): void
    {
        $response = $this->kirim(
            ['id' => 'PCR-2611001', 'status' => 'Menunggu', 'alasan' => null, 'referensi' => null, 'waktu_transfer' => null],
            pulihkan: true,
        );

        $response->assertOk()->assertJson(['menunggu' => 5]);
        $response->assertJsonPath('catatan.PCR-2611001.status', 'Menunggu');
    }

    public function test_perubahan_session_diterapkan_ke_daftar(): void
    {
        $this->withSession(['admin_status' => ['pencairan' => [
            'PCR-2611001' => ['status' => 'Disetujui', 'alasan' => null, 'referensi' => null, 'waktu_transfer' => null],
        ]]]);

        $daftar = array_column(PencairanController::daftarPengajuan(), null, 'id');

        $this->assertSame('Disetujui', $daftar['PCR-2611001']['status']);
        $this->assertSame('Menunggu', $daftar['PCR-2611002']['status']);
        $this->assertSame(4, PencairanController::jumlahMenunggu());
    }
}
