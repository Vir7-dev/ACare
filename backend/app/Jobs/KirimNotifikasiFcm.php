<?php

namespace App\Jobs;

use App\Services\Fcm;
use Illuminate\Foundation\Bus\Dispatchable;

/**
 * Kirim satu notifikasi push. Dijalankan setelah respons dikirim
 * (dispatchAfterResponse), jadi tidak butuh queue worker.
 */
class KirimNotifikasiFcm
{
    use Dispatchable;

    /** @param  array<string, string|int>  $data */
    public function __construct(
        public int $idPengguna,
        public string $judul,
        public string $isi,
        public array $data = [],
    ) {}

    public function handle(Fcm $fcm): void
    {
        $fcm->kirimKePengguna($this->idPengguna, $this->judul, $this->isi, $this->data);
    }
}
