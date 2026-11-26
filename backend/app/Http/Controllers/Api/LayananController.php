<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LayananResource;
use App\Models\Layanan;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class LayananController extends Controller
{
    /** Katalog layanan aktif beserta harga awal. */
    public function index(): AnonymousResourceCollection
    {
        return LayananResource::collection(
            Layanan::query()->where('status_layanan', 'aktif')->orderBy('id_layanan')->get(),
        );
    }
}
