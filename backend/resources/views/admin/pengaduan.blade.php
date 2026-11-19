@extends('layouts.admin')

@section('title', 'Pengaduan - ACare Admin Portal')

@section('content')

<script>
function initPengaduan() {
    return {
        filterStatus: {!! json_encode($statusAwal) !!},
        searchQuery: {!! json_encode((string) request('q', '')) !!},
        urutan: 'terbaru',
        halaman: 1,
        perHalaman: 10,
        dipilih: [],
        showDetailModal: false,
        selected: null,
        daftar: {!! json_encode($pengaduanList) !!},

        init: function () {
            var self = this;
            ['filterStatus', 'searchQuery', 'urutan'].forEach(function (k) {
                self.$watch(k, function () { self.halaman = 1; self.dipilih = []; });
            });
            this.$watch('halaman', function () { self.dipilih = []; });
        },

        waktu: function (p) {
            var bulan = { jan: 0, feb: 1, mar: 2, apr: 3, mei: 4, jun: 5, jul: 6, agu: 7, sep: 8, okt: 9, nov: 10, des: 11 };
            var b = p.tanggal.split(' ');
            var j = p.jam.split(' ')[0].split(':');
            return Date.UTC(parseInt(b[2], 10), bulan[b[1].slice(0, 3).toLowerCase()], parseInt(b[0], 10), parseInt(j[0], 10), parseInt(j[1], 10));
        },

        get daftarTersaring() {
            var self = this;
            var hasil = this.daftar.filter(function (p) {
                if (self.filterStatus !== 'Semua' && p.status !== self.filterStatus) {
                    return false;
                }
                var q = self.searchQuery.trim().toLowerCase();
                if (q === '') {
                    return true;
                }
                return p.id.toLowerCase().includes(q)
                    || p.pelapor.toLowerCase().includes(q)
                    || p.terlapor.toLowerCase().includes(q)
                    || p.order_id.toLowerCase().includes(q)
                    || p.kategori.toLowerCase().includes(q);
            });
            return hasil.sort(function (a, b) {
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
            this.dipilih = this.semuaTerpilih ? [] : this.halamanIni.map(function (p) { return p.id; });
        },
        bisaDiubah: function (statusBaru) {
            var self = this;
            return this.daftar.filter(function (p) {
                return self.dipilih.includes(p.id) && p.status !== statusBaru && !(statusBaru === 'Diproses' && p.status === 'Selesai');
            });
        },

        hitung: function (status) {
            if (status === 'Semua') {
                return this.daftar.length;
            }
            return this.daftar.filter(function (p) { return p.status === status; }).length;
        },

        // Terapkan perubahan ke server, lalu ke tampilan. Toast menyediakan Batalkan.
        terapkan: function (daftarUbah, statusBaru, tutupModal) {
            var self = this;
            if (daftarUbah.length === 0) {
                return;
            }
            var sebelum = daftarUbah.map(function (p) { return { id: p.id, status: p.status }; });
            var sesudah = daftarUbah.map(function (p) { return { id: p.id, status: statusBaru }; });

            window.kirimAdmin('{{ route('admin.pengaduan.status') }}', { perubahan: sesudah }).then(function (r) {
                if (!r.ok) {
                    window.adminToast((r.data && r.data.pesan) || 'Perubahan gagal disimpan.', { tipe: 'error' });
                    return;
                }
                self.setLokal(sesudah);
                window.setLencana('pengaduan', r.data.baru);
                self.dipilih = [];
                if (tutupModal) { self.showDetailModal = false; }
                var pesan = daftarUbah.length === 1
                    ? 'Pengaduan ' + daftarUbah[0].id + ' ditandai ' + statusBaru + '.'
                    : daftarUbah.length + ' pengaduan ditandai ' + statusBaru + '.';
                window.adminToast(pesan, { batal: function () { self.pulihkan(sebelum); } });
            });
        },

        pulihkan: function (sebelum) {
            var self = this;
            window.kirimAdmin('{{ route('admin.pengaduan.status') }}', { perubahan: sebelum }).then(function (r) {
                if (r.ok) {
                    self.setLokal(sebelum);
                    window.setLencana('pengaduan', r.data.baru);
                    window.adminToast('Perubahan dibatalkan.');
                } else {
                    window.adminToast('Pembatalan gagal. Muat ulang halaman.', { tipe: 'error' });
                }
            });
        },

        setLokal: function (daftarUbah) {
            var self = this;
            daftarUbah.forEach(function (u) {
                var p = self.daftar.find(function (x) { return x.id === u.id; });
                if (p) { p.status = u.status; }
            });
        },

        ubahStatus: function (statusBaru) {
            if (!this.selected) {
                return;
            }
            this.terapkan([this.selected], statusBaru, statusBaru === 'Selesai');
        },

        bukaDetail: function (p) {
            this.selected = p;
            this.showDetailModal = true;
        },

        badgeClass: function (status) {
            if (status === 'Baru') { return 'text-amber-700'; }
            if (status === 'Diproses') { return 'text-brand-dark'; }
            return 'text-emerald-700';
        }
    };
}
</script>

<div class="p-8" x-data="initPengaduan()">

    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-500 mb-3">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-slate-700 transition-colors">Beranda</a>
        <span>&gt;</span>
        <span class="text-slate-600 font-semibold">Pengaduan</span>
    </div>

    <!-- Judul -->
    <div class="mb-6">
        <h1 class="text-2xl font-bold text-navy tracking-tight">Pengaduan</h1>
        <p class="text-sm text-slate-500 mt-0.5">Pengaduan kendala servis &amp; sistem dari pelanggan dan teknisi yang butuh penanganan.</p>
    </div>

    <!-- Filter Status & Pencarian -->
    <div class="flex items-center justify-between gap-4 mb-4">
        <div class="flex bg-white border border-line rounded-lg p-1 gap-0.5">
            @foreach(['Semua', 'Baru', 'Diproses', 'Selesai'] as $st)
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
        <select x-model="urutan" aria-label="Urutkan pengaduan"
                class="py-2 pl-3 pr-8 bg-white border border-line rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
            <option value="terbaru">Terbaru dulu</option>
            <option value="terlama">Terlama dulu</option>
        </select>
        <div class="relative w-72">
            <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </span>
            <input type="text"
                   x-model="searchQuery"
                   placeholder="Cari pengaduan..."
                   class="w-full pl-9 pr-3 py-2 bg-white border border-line rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
        </div>
        </div>
    </div>

    <!-- Bilah aksi massal: muncul hanya saat ada baris dipilih -->
    <div x-show="dipilih.length > 0" style="display: none;"
         class="mb-3 flex items-center justify-between gap-3 px-4 py-2.5 rounded-lg border border-brand bg-brand-50">
        <p class="text-sm font-semibold text-navy"><span x-text="dipilih.length"></span> pengaduan dipilih</p>
        <div class="flex items-center gap-2">
            <button type="button" @click="dipilih = []"
                    class="px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-white rounded-lg transition-colors">Batal pilih</button>
            <button type="button" x-show="bisaDiubah('Diproses').length > 0"
                    @click="terapkan(bisaDiubah('Diproses'), 'Diproses', false)"
                    class="px-3.5 py-1.5 border border-brand bg-white text-brand-dark hover:bg-brand-50 text-sm font-semibold rounded-lg transition-colors">
                Tandai <span x-text="bisaDiubah('Diproses').length"></span> diproses
            </button>
            <button type="button" x-show="bisaDiubah('Selesai').length > 0"
                    @click="terapkan(bisaDiubah('Selesai'), 'Selesai', false)"
                    class="px-3.5 py-1.5 bg-brand hover:bg-brand-dark text-white text-sm font-semibold rounded-lg transition-colors">
                Tandai <span x-text="bisaDiubah('Selesai').length"></span> selesai
            </button>
        </div>
    </div>

    <!-- Tabel Pengaduan -->
    <div class="bg-white rounded-lg border border-line overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-brand-50 text-xs font-bold text-slate-600">
                        <th class="py-3 pl-5 pr-2 w-10">
                            <input type="checkbox" :checked="semuaTerpilih" @change="pilihSemua()"
                                   aria-label="Pilih semua pengaduan di halaman ini"
                                   class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand">
                        </th>
                        <th class="py-3 px-3">ID &amp; Waktu</th>
                        <th class="py-3 px-4">Pelapor</th>
                        <th class="py-3 px-4">Dilaporkan</th>
                        <th class="py-3 px-4">Kategori</th>
                        <th class="py-3 px-4">Ringkasan</th>
                        <th class="py-3 px-4">Status</th>
                        <th class="py-3 px-5 text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-line text-sm">
                    <template x-for="p in halamanIni" :key="p.id">
                        <tr class="hover:bg-slate-50 transition-colors" :class="dipilih.includes(p.id) ? 'bg-brand-50/60' : ''">
                            <td class="py-3.5 pl-5 pr-2">
                                <input type="checkbox" :value="p.id" x-model="dipilih"
                                       :aria-label="'Pilih ' + p.id"
                                       class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand">
                            </td>
                            <td class="py-3.5 px-3">
                                <p class="font-mono font-bold text-brand-dark" x-text="p.id"></p>
                                <p class="text-xs text-slate-500 whitespace-nowrap" x-text="p.tanggal + ', ' + p.jam"></p>
                            </td>
                            <td class="py-3.5 px-4">
                                <p class="font-bold text-slate-800 whitespace-nowrap" x-text="p.pelapor"></p>
                                <p class="text-xs text-slate-500" x-text="p.peran"></p>
                            </td>
                            <td class="py-3.5 px-4 text-slate-600 whitespace-nowrap" x-text="p.terlapor"></td>
                            <td class="py-3.5 px-4 text-slate-700 font-medium" x-text="p.kategori"></td>
                            <td class="py-3.5 px-4 text-slate-600 max-w-xs" x-text="p.ringkasan"></td>
                            <td class="py-3.5 px-4">
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="badgeClass(p.status)"><span x-text="p.status"></span></span>
                            </td>
                            <td class="py-3.5 px-5 text-center">
                                <button type="button"
                                        @click="bukaDetail(p)"
                                        class="px-3 py-1.5 border border-brand text-brand-dark hover:bg-brand-50 rounded-lg text-xs font-bold transition-all">
                                    Detail
                                </button>
                            </td>
                        </tr>
                    </template>
                    <tr x-show="daftarTersaring.length === 0" style="display: none;">
                        <td colspan="8" class="py-10 text-center text-slate-500 text-xs font-medium">
                            Tidak ada pengaduan yang cocok.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        @include('admin.partials.paginasi')
    </div>

    <!-- Modal Detail Pengaduan -->
    <div x-show="showDetailModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4"
         style="display: none;">
        <div @click.away="showDetailModal = false"
             class="bg-white rounded-xl max-w-lg w-full overflow-hidden shadow-lg border border-line">

            <div class="px-6 py-4 border-b border-line flex items-center justify-between">
                <div>
                    <p class="font-mono text-xs font-bold text-brand-dark" x-text="selected ? selected.id : ''"></p>
                    <h3 class="text-base font-bold text-navy" x-text="selected ? selected.kategori : ''"></h3>
                </div>
                <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="selected ? badgeClass(selected.status) : ''"><span x-text="selected ? selected.status : ''"></span></span>
            </div>

            <div class="px-6 py-5 space-y-4 text-xs">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <p class="text-slate-500 font-semibold">Pelapor</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.pelapor + ' (' + selected.peran + ')' : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Dilaporkan</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.terlapor : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Waktu Laporan</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.tanggal + ', ' + selected.jam : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Transaksi Terkait</p>
                        <button type="button"
                                @click="$dispatch('buka-detail-transaksi', { id: selected.order_id })"
                                class="font-mono font-bold text-brand-dark hover:underline"
                                x-text="selected ? selected.order_id : ''"></button>
                    </div>
                </div>

                <div>
                    <p class="text-slate-500 font-semibold mb-1">Isi Pengaduan</p>
                    <p class="text-slate-700 leading-relaxed bg-slate-50 border border-line rounded-lg p-3" x-text="selected ? selected.deskripsi : ''"></p>
                </div>
            </div>

            <div class="px-6 py-4 border-t border-line flex items-center justify-between gap-3">
                <button type="button"
                        @click="showDetailModal = false"
                        class="px-4 py-2.5 border border-slate-400 text-slate-700 hover:bg-slate-50 font-semibold text-sm rounded-lg transition-colors">
                    Tutup
                </button>
                <div class="flex items-center gap-2">
                    <button type="button" x-show="selected && selected.status === 'Baru'"
                            @click="ubahStatus('Diproses')"
                            class="px-4 py-2.5 border border-brand text-brand-dark hover:bg-brand-50 font-semibold text-sm rounded-lg transition-colors">
                        Tandai diproses
                    </button>
                    <button type="button" x-show="selected && selected.status !== 'Selesai'"
                            @click="ubahStatus('Selesai')"
                            class="px-4 py-2.5 bg-brand hover:bg-brand-dark text-white font-semibold text-sm rounded-lg transition-colors">
                        Tandai selesai
                    </button>
                </div>
            </div>
        </div>
    </div>

    @include('admin.partials.detail-transaksi')

</div>

@endsection
