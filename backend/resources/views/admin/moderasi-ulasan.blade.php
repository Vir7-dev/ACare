@extends('layouts.admin')

@section('title', 'Moderasi Ulasan - ACare Admin Portal')

@section('content')

<script>
function initUlasan() {
    return {
        filterStatus: {!! json_encode($statusAwal) !!},
        filterRating: 'semua',
        searchQuery: {!! json_encode((string) request('q', '')) !!},
        urutan: 'terbaru',
        halaman: 1,
        perHalaman: 10,
        dipilih: [],
        showDetailModal: false,
        showSembunyiModal: false,
        selected: null,
        target: [],
        alasan: '',
        daftar: {!! json_encode($ulasanList) !!},
        idTransaksi: {!! json_encode($idTransaksi) !!},

        init: function () {
            var self = this;
            ['filterStatus', 'filterRating', 'searchQuery', 'urutan'].forEach(function (k) {
                self.$watch(k, function () { self.halaman = 1; self.dipilih = []; });
            });
            this.$watch('halaman', function () { self.dipilih = []; });
        },

        waktu: function (u) {
            var bulan = { jan: 0, feb: 1, mar: 2, apr: 3, mei: 4, jun: 5, jul: 6, agu: 7, sep: 8, okt: 9, nov: 10, des: 11 };
            var b = u.tanggal.split(' ');
            var j = u.jam.split(' ')[0].split(':');
            return Date.UTC(parseInt(b[2], 10), bulan[b[1].slice(0, 3).toLowerCase()], parseInt(b[0], 10), parseInt(j[0], 10), parseInt(j[1], 10));
        },

        get daftarTersaring() {
            var self = this;
            var hasil = this.daftar.filter(function (u) {
                if (self.filterStatus !== 'Semua' && u.status !== self.filterStatus) {
                    return false;
                }
                if (self.filterRating !== 'semua' && String(u.rating) !== self.filterRating) {
                    return false;
                }
                var q = self.searchQuery.trim().toLowerCase();
                if (q === '') {
                    return true;
                }
                return u.id.toLowerCase().includes(q)
                    || u.pelanggan.toLowerCase().includes(q)
                    || u.teknisi.toLowerCase().includes(q)
                    || u.order_id.toLowerCase().includes(q)
                    || u.ulasan.toLowerCase().includes(q);
            });
            return hasil.sort(function (a, b) {
                if (self.urutan === 'rendah') { return a.rating - b.rating || self.waktu(b) - self.waktu(a); }
                if (self.urutan === 'tinggi') { return b.rating - a.rating || self.waktu(b) - self.waktu(a); }
                var selisih = self.waktu(b) - self.waktu(a);
                return self.urutan === 'terbaru' ? selisih : -selisih;
            });
        },

        get totalTersaring() { return this.daftarTersaring.length; },
        get jumlahHalaman() { return Math.max(1, Math.ceil(this.totalTersaring / this.perHalaman)); },
        get halamanIni() {
            var mulai = (this.halaman - 1) * this.perHalaman;
            return this.daftarTersaring.slice(mulai, mulai + this.perHalaman);
        },

        get semuaTerpilih() {
            return this.halamanIni.length > 0 && this.dipilih.length === this.halamanIni.length;
        },
        pilihSemua: function () {
            this.dipilih = this.semuaTerpilih ? [] : this.halamanIni.map(function (u) { return u.id; });
        },
        terpilihDengan: function (status) {
            var self = this;
            return this.daftar.filter(function (u) { return self.dipilih.includes(u.id) && u.status === status; });
        },

        hitung: function (status) {
            if (status === 'Semua') {
                return this.daftar.length;
            }
            return this.daftar.filter(function (u) { return u.status === status; }).length;
        },

        // Rata-rata hanya dari ulasan yang tayang.
        get ratingRata() {
            var tayang = this.daftar.filter(function (u) { return u.status === 'Tayang'; });
            if (tayang.length === 0) { return '-'; }
            var total = tayang.reduce(function (a, u) { return a + u.rating; }, 0);
            return (total / tayang.length).toFixed(1).replace('.', ',');
        },

        adaTransaksi: function (id) { return this.idTransaksi.includes(id); },

        // Terapkan perubahan ke server, lalu ke tampilan. Toast menyediakan Batalkan.
        terapkan: function (daftarUbah, statusBaru, alasan) {
            var self = this;
            if (daftarUbah.length === 0) {
                return;
            }
            var sebelum = daftarUbah.map(function (u) { return { id: u.id, status: u.status, alasan: u.alasan }; });
            var sesudah = daftarUbah.map(function (u) { return { id: u.id, status: statusBaru, alasan: statusBaru === 'Disembunyikan' ? alasan : null }; });

            window.kirimAdmin('{{ route('admin.ulasan.status') }}', { perubahan: sesudah }).then(function (r) {
                if (!r.ok) {
                    window.adminToast((r.data && r.data.pesan) || 'Perubahan gagal disimpan.', { tipe: 'error' });
                    return;
                }
                self.setLokal(sesudah);
                self.dipilih = [];
                self.showSembunyiModal = false;
                self.showDetailModal = false;
                var kata = statusBaru === 'Disembunyikan' ? 'disembunyikan' : 'ditayangkan kembali';
                var pesan = daftarUbah.length === 1
                    ? 'Ulasan ' + daftarUbah[0].id + ' ' + kata + '.'
                    : daftarUbah.length + ' ulasan ' + kata + '.';
                window.adminToast(pesan, { batal: function () { self.pulihkan(sebelum); } });
            });
        },

        pulihkan: function (sebelum) {
            var self = this;
            window.kirimAdmin('{{ route('admin.ulasan.status') }}', { perubahan: sebelum }).then(function (r) {
                if (r.ok) {
                    self.setLokal(sebelum);
                    window.adminToast('Perubahan dibatalkan.');
                } else {
                    window.adminToast('Pembatalan gagal. Muat ulang halaman.', { tipe: 'error' });
                }
            });
        },

        setLokal: function (daftarUbah) {
            var self = this;
            daftarUbah.forEach(function (u) {
                var item = self.daftar.find(function (x) { return x.id === u.id; });
                if (item) { item.status = u.status; item.alasan = u.alasan; }
            });
        },

        // Menyembunyikan selalu meminta alasan lebih dulu.
        mintaSembunyi: function (daftarUbah) {
            if (daftarUbah.length === 0) { return; }
            this.target = daftarUbah;
            this.alasan = '';
            this.showSembunyiModal = true;
        },
        konfirmasiSembunyi: function () {
            if (this.alasan === '') { return; }
            this.terapkan(this.target, 'Disembunyikan', this.alasan);
        },

        bukaDetail: function (u) {
            this.selected = u;
            this.showDetailModal = true;
        },

        badgeClass: function (status) {
            return status === 'Tayang' ? 'text-emerald-700' : 'text-slate-600';
        }
    };
}
</script>

<div class="p-8" x-data="initUlasan()">

    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-500 mb-3">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-slate-700 transition-colors">Beranda</a>
        <span>&gt;</span>
        <span class="text-slate-600 font-semibold">Moderasi Ulasan</span>
    </div>

    <!-- Judul -->
    <div class="mb-6">
        <h1 class="text-2xl font-bold text-navy tracking-tight">Moderasi Ulasan</h1>
        <p class="text-sm text-slate-500 mt-0.5">Tinjau rating dan ulasan pelanggan, lalu sembunyikan ulasan yang melanggar ketentuan.</p>
    </div>

    <!-- 3 Kartu Ringkasan -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-5">
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Rating Rata-rata (ulasan tayang)</p>
            <p class="text-2xl font-bold text-navy mt-2 flex items-center gap-2">
                <iconify-icon icon="mdi:star" width="22" height="22" class="text-amber-400" aria-hidden="true"></iconify-icon>
                <span x-text="ratingRata"></span>
            </p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Total Ulasan</p>
            <p class="text-2xl font-bold text-navy mt-2" x-text="daftar.length"></p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Disembunyikan</p>
            <p class="text-2xl font-bold text-navy mt-2" x-text="hitung('Disembunyikan')"></p>
        </div>
    </div>

    <!-- Filter Status & Pencarian -->
    <div class="flex items-center justify-between gap-4 mb-4">
        <div class="flex bg-white border border-line rounded-lg p-1 gap-0.5">
            @foreach(['Semua', 'Tayang', 'Disembunyikan'] as $st)
            <button type="button"
                    @click="filterStatus = '{{ $st }}'"
                    :class="filterStatus === '{{ $st }}' ? 'bg-brand text-white font-bold' : 'text-slate-500 hover:text-slate-800 font-semibold'"
                    class="px-3.5 py-1.5 rounded-lg text-xs transition-all flex items-center gap-1.5">
                <span>{{ $st }}</span>
                <span class="text-xs opacity-80" x-text="hitung('{{ $st }}')"></span>
            </button>
            @endforeach
        </div>

        <div class="flex items-center gap-3">
            <select x-model="filterRating" aria-label="Saring berdasarkan rating"
                    class="py-2 pl-3 pr-8 bg-white border border-line rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
                <option value="semua">Semua rating</option>
                @foreach([5, 4, 3, 2, 1] as $bintang)
                <option value="{{ $bintang }}">Rating {{ $bintang }}</option>
                @endforeach
            </select>
            <select x-model="urutan" aria-label="Urutkan ulasan"
                    class="py-2 pl-3 pr-8 bg-white border border-line rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
                <option value="terbaru">Terbaru dulu</option>
                <option value="terlama">Terlama dulu</option>
                <option value="rendah">Rating terendah</option>
                <option value="tinggi">Rating tertinggi</option>
            </select>
            <div class="relative w-72">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                    <iconify-icon icon="lucide:search" width="16" height="16" aria-hidden="true"></iconify-icon>
                </span>
                <input type="text"
                       x-model="searchQuery"
                       placeholder="Cari ulasan..."
                       class="w-full pl-9 pr-3 py-2 bg-white border border-line rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
            </div>
        </div>
    </div>

    <!-- Bilah aksi massal: muncul hanya saat ada baris dipilih -->
    <div x-show="dipilih.length > 0" style="display: none;"
         class="mb-3 flex items-center justify-between gap-3 px-4 py-2.5 rounded-lg border border-brand bg-brand-50">
        <p class="text-sm font-semibold text-navy"><span x-text="dipilih.length"></span> ulasan dipilih</p>
        <div class="flex items-center gap-2">
            <button type="button" @click="dipilih = []"
                    class="px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-white rounded-lg transition-colors">Batal pilih</button>
            <button type="button" x-show="terpilihDengan('Disembunyikan').length > 0"
                    @click="terapkan(terpilihDengan('Disembunyikan'), 'Tayang', null)"
                    class="px-3.5 py-1.5 border border-brand bg-white text-brand-dark hover:bg-brand-50 text-sm font-semibold rounded-lg transition-colors">
                Tayangkan <span x-text="terpilihDengan('Disembunyikan').length"></span> ulasan
            </button>
            <button type="button" x-show="terpilihDengan('Tayang').length > 0"
                    @click="mintaSembunyi(terpilihDengan('Tayang'))"
                    class="px-3.5 py-1.5 bg-brand hover:bg-brand-dark text-white text-sm font-semibold rounded-lg transition-colors">
                Sembunyikan <span x-text="terpilihDengan('Tayang').length"></span> ulasan
            </button>
        </div>
    </div>

    <!-- Tabel Ulasan -->
    <div class="bg-white rounded-lg border border-line overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-brand-50 text-xs font-bold text-slate-600">
                        <th class="py-3 pl-5 pr-2 w-10">
                            <input type="checkbox" :checked="semuaTerpilih" @change="pilihSemua()"
                                   aria-label="Pilih semua ulasan di halaman ini"
                                   class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand">
                        </th>
                        <th class="py-3 px-3">ID &amp; Waktu</th>
                        <th class="py-3 px-4">Pelanggan</th>
                        <th class="py-3 px-4">Teknisi</th>
                        <th class="py-3 px-4">Rating</th>
                        <th class="py-3 px-4">Ulasan</th>
                        <th class="py-3 px-4">Status</th>
                        <th class="py-3 px-5 text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-line text-sm">
                    <template x-for="u in halamanIni" :key="u.id">
                        <tr class="hover:bg-slate-50 transition-colors" :class="dipilih.includes(u.id) ? 'bg-brand-50/60' : ''">
                            <td class="py-3.5 pl-5 pr-2">
                                <input type="checkbox" :value="u.id" x-model="dipilih"
                                       :aria-label="'Pilih ' + u.id"
                                       class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand">
                            </td>
                            <td class="py-3.5 px-3">
                                <p class="font-mono font-bold text-brand-dark" x-text="u.id"></p>
                                <p class="text-xs text-slate-500 whitespace-nowrap" x-text="u.tanggal + ', ' + u.jam"></p>
                            </td>
                            <td class="py-3.5 px-4 font-bold text-slate-800 whitespace-nowrap" x-text="u.pelanggan"></td>
                            <td class="py-3.5 px-4 text-slate-600 whitespace-nowrap" x-text="u.teknisi"></td>
                            <td class="py-3.5 px-4">
                                <span class="inline-flex items-center gap-0.5" :aria-label="'Rating ' + u.rating + ' dari 5'">
                                    <template x-for="i in 5" :key="i">
                                        <iconify-icon :icon="i <= u.rating ? 'mdi:star' : 'mdi:star-outline'" width="16" height="16"
                                                      :class="i <= u.rating ? 'text-amber-400' : 'text-slate-300'" aria-hidden="true"></iconify-icon>
                                    </template>
                                </span>
                            </td>
                            <td class="py-3.5 px-4 text-slate-600 max-w-xs">
                                <p class="line-clamp-2" x-text="u.ulasan"></p>
                            </td>
                            <td class="py-3.5 px-4">
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="badgeClass(u.status)"><span x-text="u.status"></span></span>
                            </td>
                            <td class="py-3.5 px-5 text-center">
                                <button type="button"
                                        @click="bukaDetail(u)"
                                        class="px-3 py-1.5 border border-brand text-brand-dark hover:bg-brand-50 rounded-lg text-xs font-bold transition-all">
                                    Detail
                                </button>
                            </td>
                        </tr>
                    </template>
                    <tr x-show="daftarTersaring.length === 0" style="display: none;">
                        <td colspan="8" class="py-10 text-center text-slate-500 text-xs font-medium">
                            Tidak ada ulasan yang cocok.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        @include('admin.partials.paginasi')
    </div>

    <!-- Modal Detail Ulasan -->
    <div x-show="showDetailModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4"
         style="display: none;">
        <div @click.away="showDetailModal = false"
             class="bg-white rounded-xl max-w-lg w-full overflow-hidden shadow-lg border border-line">

            <div class="px-6 py-4 border-b border-line flex items-center justify-between">
                <div>
                    <p class="font-mono text-xs font-bold text-brand-dark" x-text="selected ? selected.id : ''"></p>
                    <h3 class="text-base font-bold text-navy" x-text="selected ? selected.layanan : ''"></h3>
                </div>
                <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="selected ? badgeClass(selected.status) : ''"><span x-text="selected ? selected.status : ''"></span></span>
            </div>

            <div class="px-6 py-5 space-y-4 text-xs">
                <div class="flex items-center gap-2">
                    <span class="inline-flex items-center gap-0.5" x-show="selected">
                        <template x-for="i in 5" :key="i">
                            <iconify-icon :icon="selected && i <= selected.rating ? 'mdi:star' : 'mdi:star-outline'" width="20" height="20"
                                          :class="selected && i <= selected.rating ? 'text-amber-400' : 'text-slate-300'" aria-hidden="true"></iconify-icon>
                        </template>
                    </span>
                    <span class="text-sm font-bold text-navy" x-text="selected ? selected.rating + ' / 5' : ''"></span>
                </div>

                <div>
                    <p class="text-slate-500 font-semibold mb-1">Isi Ulasan</p>
                    <p class="text-slate-700 leading-relaxed bg-slate-50 border border-line rounded-lg p-3" x-text="selected ? selected.ulasan : ''"></p>
                </div>

                <div x-show="selected && selected.pilihan.length > 0">
                    <p class="text-slate-500 font-semibold mb-1.5">Hal yang disukai</p>
                    <div class="flex flex-wrap gap-1.5">
                        <template x-for="p in (selected ? selected.pilihan : [])" :key="p">
                            <span class="px-2.5 py-1 rounded-full bg-brand-50 text-brand-dark font-semibold" x-text="p"></span>
                        </template>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <p class="text-slate-500 font-semibold">Pelanggan</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.pelanggan : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Teknisi yang Dinilai</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.teknisi : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Waktu Ulasan</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.tanggal + ', ' + selected.jam : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Transaksi Terkait</p>
                        <template x-if="selected && adaTransaksi(selected.order_id)">
                            <button type="button"
                                    @click="$dispatch('buka-detail-transaksi', { id: selected.order_id })"
                                    class="font-mono font-bold text-brand-dark hover:underline"
                                    x-text="selected.order_id"></button>
                        </template>
                        <template x-if="selected && !adaTransaksi(selected.order_id)">
                            <p class="font-mono font-bold text-slate-800" x-text="selected.order_id"></p>
                        </template>
                    </div>
                </div>

                <div x-show="selected && selected.status === 'Disembunyikan'"
                     class="flex items-start gap-2 rounded-lg border border-line bg-slate-50 p-3 text-slate-600">
                    <iconify-icon icon="lucide:eye-off" width="16" height="16" class="mt-0.5 flex-shrink-0" aria-hidden="true"></iconify-icon>
                    <p>Disembunyikan dari aplikasi. Alasan: <span class="font-semibold text-slate-800" x-text="selected ? selected.alasan : ''"></span></p>
                </div>
            </div>

            <div class="px-6 py-4 border-t border-line flex items-center justify-between gap-3">
                <button type="button"
                        @click="showDetailModal = false"
                        class="px-4 py-2.5 border border-slate-400 text-slate-700 hover:bg-slate-50 font-semibold text-sm rounded-lg transition-colors">
                    Tutup
                </button>
                <div class="flex items-center gap-2">
                    <button type="button" x-show="selected && selected.status === 'Tayang'"
                            @click="mintaSembunyi([selected])"
                            class="px-4 py-2.5 bg-brand hover:bg-brand-dark text-white font-semibold text-sm rounded-lg transition-colors">
                        Sembunyikan
                    </button>
                    <button type="button" x-show="selected && selected.status === 'Disembunyikan'"
                            @click="terapkan([selected], 'Tayang', null)"
                            class="px-4 py-2.5 border border-brand text-brand-dark hover:bg-brand-50 font-semibold text-sm rounded-lg transition-colors">
                        Tayangkan kembali
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Alasan Menyembunyikan -->
    <div x-show="showSembunyiModal"
         x-transition.opacity
         class="fixed inset-0 z-[60] flex items-center justify-center bg-navy/60 p-4"
         role="dialog" aria-modal="true" aria-labelledby="judul-sembunyi"
         style="display: none;">
        <div @click.away="showSembunyiModal = false"
             class="bg-white rounded-xl max-w-sm w-full overflow-hidden shadow-lg border border-line p-6">
            <div class="w-12 h-12 bg-brand-50 text-brand-dark rounded-full flex items-center justify-center mx-auto mb-3">
                <iconify-icon icon="lucide:eye-off" width="22" height="22" aria-hidden="true"></iconify-icon>
            </div>
            <h3 id="judul-sembunyi" class="text-base font-bold text-navy text-center mb-1">
                Sembunyikan <span x-text="target.length"></span> ulasan?
            </h3>
            <p class="text-sm text-slate-600 text-center mb-4 leading-relaxed">
                Ulasan tidak lagi tampil di aplikasi, tetapi datanya tetap tersimpan dan bisa ditayangkan kembali.
            </p>
            <label for="alasan-sembunyi" class="block text-xs font-semibold text-slate-600 mb-1.5">Alasan</label>
            <select id="alasan-sembunyi" x-model="alasan"
                    class="w-full py-2.5 px-3 bg-white border border-line rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
                <option value="">Pilih alasan</option>
                @foreach($alasanList as $a)
                <option value="{{ $a }}">{{ $a }}</option>
                @endforeach
            </select>
            <div class="flex items-center gap-2.5 mt-5">
                <button type="button"
                        @click="showSembunyiModal = false"
                        class="flex-1 py-2.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm font-semibold transition-colors">
                    Batal
                </button>
                <button type="button"
                        @click="konfirmasiSembunyi()"
                        :disabled="alasan === ''"
                        class="flex-1 py-2.5 rounded-lg bg-brand hover:bg-brand-dark text-white text-sm font-semibold transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                    Ya, Sembunyikan
                </button>
            </div>
        </div>
    </div>

    @include('admin.partials.detail-transaksi')

</div>

@endsection
