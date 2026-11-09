<?php

namespace Tests\Feature;

use App\Http\Controllers\Admin\UlasanController;
use Tests\TestCase;

class UlasanAdminTest extends TestCase
{
    public function test_halaman_moderasi_ulasan_tampil_dengan_menu_sidebar(): void
    {
        $response = $this->get(route('admin.ulasan'));

        $response->assertOk();
        $response->assertSee('Moderasi Ulasan');
        $response->assertSee('ULS-2611001');
        $response->assertSee('Disembunyikan');
        $response->assertSee('data-lencana="pencairan"', false);
    }

    public function test_status_awal_mengikuti_parameter_url(): void
    {
        $this->get(route('admin.ulasan', ['status' => 'Disembunyikan']))
            ->assertOk()
            ->assertSee('filterStatus: "Disembunyikan"', false);

        $this->get(route('admin.ulasan', ['status' => 'tidak-dikenal']))
            ->assertSee('filterStatus: "Semua"', false);
    }

    public function test_menyembunyikan_ulasan_tersimpan_beserta_alasan(): void
    {
        $response = $this->postJson(route('admin.ulasan.status'), [
            'perubahan' => [
                ['id' => 'ULS-2611005', 'status' => 'Disembunyikan', 'alasan' => 'Kata kasar atau menghina'],
            ],
        ]);

        $response->assertOk()->assertJson(['ok' => true, 'disembunyikan' => 2]);
        $response->assertSessionHas('admin_status.ulasan.ULS-2611005', [
            'status' => 'Disembunyikan',
            'alasan' => 'Kata kasar atau menghina',
        ]);
    }

    public function test_alasan_wajib_saat_menyembunyikan(): void
    {
        $this->postJson(route('admin.ulasan.status'), [
            'perubahan' => [['id' => 'ULS-2611005', 'status' => 'Disembunyikan', 'alasan' => '  ']],
        ])->assertStatus(422)->assertJson(['pesan' => 'Alasan menyembunyikan ulasan wajib diisi.']);

        $this->postJson(route('admin.ulasan.status'), [
            'perubahan' => [['id' => 'ULS-2611005', 'status' => 'Disembunyikan']],
        ])->assertStatus(422);
    }

    public function test_ulasan_tidak_dikenal_ditolak_dan_status_tidak_valid_gagal(): void
    {
        $this->postJson(route('admin.ulasan.status'), [
            'perubahan' => [['id' => 'ULS-0000000', 'status' => 'Tayang']],
        ])->assertNotFound();

        $this->postJson(route('admin.ulasan.status'), [
            'perubahan' => [['id' => 'ULS-2611005', 'status' => 'Dihapus']],
        ])->assertStatus(422);
    }

    public function test_tayangkan_kembali_menghapus_alasan(): void
    {
        $response = $this->postJson(route('admin.ulasan.status'), [
            'perubahan' => [
                ['id' => 'ULS-2610011', 'status' => 'Tayang', 'alasan' => 'sisa lama'],
            ],
        ]);

        $response->assertOk()->assertJson(['disembunyikan' => 0]);
        $response->assertSessionHas('admin_status.ulasan.ULS-2610011', [
            'status' => 'Tayang',
            'alasan' => null,
        ]);
    }

    public function test_perubahan_session_diterapkan_ke_daftar_dan_halaman(): void
    {
        $sesi = ['admin_status' => ['ulasan' => [
            'ULS-2611001' => ['status' => 'Disembunyikan', 'alasan' => 'Spam atau promosi'],
        ]]];

        $this->withSession($sesi)->get(route('admin.ulasan'))
            ->assertOk()
            ->assertSee('Spam atau promosi');

        $this->withSession($sesi);
        $daftar = array_column(UlasanController::daftarUlasan(), null, 'id');
        $this->assertSame('Disembunyikan', $daftar['ULS-2611001']['status']);
        $this->assertSame('Tayang', $daftar['ULS-2611002']['status']);
    }

    public function test_pencarian_global_memuat_ulasan(): void
    {
        $this->get(route('admin.ulasan'))
            ->assertSee('ULS-2611005 · Wahyu Nugroho', false);
    }
}
