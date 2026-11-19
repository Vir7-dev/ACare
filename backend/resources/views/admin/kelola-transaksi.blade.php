@extends('layouts.admin')

@section('title', 'Kelola Transaksi - ACare Admin Portal')

@section('content')

<script>
function initKelolaTransaksi() {
    return {
        filterStatus: 'Semua',
        urutan: 'terbaru',
        halaman: 1,
        perHalaman: 10,
        searchQuery: {!! json_encode((string) request('q', '')) !!},
        transaksiList: {!! json_encode($transaksiList) !!},
        daftarStatus: ['Semua', 'Selesai', 'Berlangsung', 'Dibatalkan'],

        hitung: function (status) {
            if (status === 'Semua') {
                return this.transaksiList.length;
            }
            return this.transaksiList.filter(function (t) { return t.status === status; }).length;
        },

        init: function () {
            var self = this;
            ['filterStatus', 'searchQuery', 'urutan'].forEach(function (k) {
                self.$watch(k, function () { self.halaman = 1; });
            });
        },

        waktu: function (t) {
            var bulan = { jan: 0, feb: 1, mar: 2, apr: 3, mei: 4, jun: 5, jul: 6, agu: 7, sep: 8, okt: 9, nov: 10, des: 11 };
            var b = t.tanggal.split(' ');
            var j = t.jam.split(' ')[0].split(':');
            return Date.UTC(parseInt(b[2], 10), bulan[b[1].slice(0, 3).toLowerCase()], parseInt(b[0], 10), parseInt(j[0], 10), parseInt(j[1], 10));
        },

        get totalTersaring() { return this.filteredList.length; },
        get jumlahHalaman() { return Math.max(1, Math.ceil(this.totalTersaring / this.perHalaman)); },
        get halamanIni() {
            var mulai = (this.halaman - 1) * this.perHalaman;
            return this.filteredList.slice(mulai, mulai + this.perHalaman);
        },

        get filteredList() {
            var self = this;
            var hasil = this.transaksiList.filter(function (t) {
                if (self.filterStatus !== 'Semua' && t.status !== self.filterStatus) {
                    return false;
                }
                var q = self.searchQuery.trim().toLowerCase();
                if (q === '') {
                    return true;
                }
                return t.id.toLowerCase().includes(q)
                    || t.pelanggan.toLowerCase().includes(q)
                    || t.teknisi.toLowerCase().includes(q)
                    || t.layanan.toLowerCase().includes(q)
                    || t.alamat.toLowerCase().includes(q)
                    || t.unit_ac.toLowerCase().includes(q);
            });
            return hasil.sort(function (a, b) {
                if (self.urutan === 'biaya_tinggi') { return b.total_biaya - a.total_biaya; }
                if (self.urutan === 'biaya_rendah') { return a.total_biaya - b.total_biaya; }
                var selisih = self.waktu(b) - self.waktu(a);
                return self.urutan === 'terlama' ? -selisih : selisih;
            });
        },

        kelasStatus: function (status) {
            if (status === 'Selesai') { return 'text-emerald-700'; }
            if (status === 'Berlangsung') { return 'text-amber-700'; }
            return 'text-rose-700';
        }
    };
}
</script>

<div class="p-8" x-data="initKelolaTransaksi()">

    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-500 mb-2">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-brand-dark transition-colors flex items-center gap-1">
            <iconify-icon icon="lucide:house" width="14" height="14" aria-hidden="true"></iconify-icon>
            Beranda
        </a>
        <span>&gt;</span>
        <span class="text-slate-600 font-semibold">Kelola Transaksi</span>
    </div>

    <div class="mb-6">
        <h1 class="text-2xl font-bold text-navy tracking-tight">Kelola Transaksi</h1>
        <p class="text-sm text-slate-500 mt-0.5">Pantau pesanan, progres teknisi, dan bukti pengerjaan.</p>
    </div>

    <!-- Filter status & pencarian -->
    <div class="bg-white rounded-lg border border-line p-4 mb-5 flex items-center justify-between gap-4">
        <div class="flex items-center gap-1 bg-slate-100 p-1 rounded-lg text-sm font-semibold">
            <template x-for="st in daftarStatus" :key="st">
                <button type="button" @click="filterStatus = st"
                        :class="filterStatus === st ? 'bg-white text-navy font-bold' : 'text-slate-600 hover:text-slate-900'"
                        class="px-3.5 py-1.5 rounded-lg transition-colors flex items-center gap-1.5">
                    <span x-text="st"></span>
                    <span class="text-xs text-slate-500" x-text="hitung(st)"></span>
                </button>
            </template>
        </div>

        <div class="flex items-center gap-3">
        <select x-model="urutan" aria-label="Urutkan transaksi"
                class="py-2 pl-3 pr-8 bg-white border border-slate-400 rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
            <option value="terbaru">Terbaru dulu</option>
            <option value="terlama">Terlama dulu</option>
            <option value="biaya_tinggi">Biaya tertinggi</option>
            <option value="biaya_rendah">Biaya terendah</option>
        </select>
        <div class="relative w-80">
            <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                <iconify-icon icon="lucide:search" width="16" height="16" aria-hidden="true"></iconify-icon>
            </span>
            <input type="text"
                   x-model="searchQuery"
                   placeholder="Cari ID, pelanggan, teknisi, atau alamat..."
                   aria-label="Cari transaksi"
                   class="w-full pl-9 pr-3 py-2 bg-white border border-slate-400 rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent">
        </div>
        </div>
    </div>

    <!-- Tabel -->
    <div class="bg-white rounded-lg border border-line overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full min-w-[960px] text-left border-collapse">
                <thead>
                    <tr class="bg-brand-50 text-xs font-bold text-slate-600">
                        <th class="py-3 px-4">ID &amp; Waktu</th>
                        <th class="py-3 px-3">Pelanggan</th>
                        <th class="py-3 px-3">Layanan &amp; Unit</th>
                        <th class="py-3 px-3">Teknisi</th>
                        <th class="py-3 px-3 text-right">Biaya</th>
                        <th class="py-3 px-3 text-center">Status</th>
                        <th class="py-3 px-4 text-center sticky right-0 bg-brand-50 border-l border-line">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-line text-sm">
                    <template x-for="trx in halamanIni" :key="trx.id">
                        <tr class="hover:bg-slate-50 transition-colors">
                            <td class="py-3.5 px-4 whitespace-nowrap">
                                <p class="font-mono font-bold text-brand-dark" x-text="trx.id"></p>
                                <p class="text-xs text-slate-500" x-text="trx.tanggal + ', ' + trx.jam"></p>
                            </td>
                            <td class="py-3.5 px-3">
                                <p class="font-bold text-navy" x-text="trx.pelanggan"></p>
                                <p class="text-xs text-slate-500 truncate max-w-[115px]" x-text="trx.alamat" :title="trx.alamat"></p>
                            </td>
                            <td class="py-3.5 px-3">
                                <span class="font-semibold text-slate-800 whitespace-nowrap" x-text="trx.layanan"></span>
                                <p class="text-xs text-slate-500 mt-0.5 truncate max-w-[115px]" x-text="trx.unit_ac" :title="trx.unit_ac"></p>
                            </td>
                            <td class="py-3.5 px-3 whitespace-nowrap text-slate-700 font-semibold" x-text="trx.teknisi"></td>
                            <td class="py-3.5 px-3 text-right whitespace-nowrap">
                                <p class="font-bold text-navy" x-text="'Rp ' + Number(trx.total_biaya).toLocaleString('id-ID')"></p>
                                <p class="text-xs text-slate-500" x-text="trx.metode_bayar"></p>
                            </td>
                            <td class="py-3.5 px-3 text-center whitespace-nowrap">
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="kelasStatus(trx.status)"><span x-text="trx.status"></span></span>
                            </td>
                            <td class="py-3.5 px-4 text-center whitespace-nowrap sticky right-0 bg-white border-l border-line">
                                <button type="button"
                                        @click="$dispatch('buka-detail-transaksi', { id: trx.id })"
                                        :aria-label="'Lihat detail ' + trx.id"
                                        class="px-3 py-1.5 border border-brand text-brand-dark hover:bg-brand-50 font-semibold text-xs rounded-lg transition-colors inline-flex items-center gap-1.5">
                                    <iconify-icon icon="lucide:eye" width="14" height="14" aria-hidden="true"></iconify-icon>
                                    <span>Detail</span>
                                </button>
                            </td>
                        </tr>
                    </template>
                    <tr x-show="filteredList.length === 0" style="display: none;">
                        <td colspan="7" class="py-12 text-center">
                            <p class="text-sm font-bold text-slate-600">Transaksi tidak ditemukan</p>
                            <p class="text-xs text-slate-500 mt-1">Coba ubah filter status atau kata kunci pencarian.</p>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div x-show="jumlahHalaman <= 1" class="px-6 py-3.5 border-t border-line text-xs text-slate-500 font-medium">
            <span x-text="'Menampilkan ' + totalTersaring + ' dari ' + transaksiList.length + ' transaksi'"></span>
        </div>
        @include('admin.partials.paginasi')
    </div>

    @include('admin.partials.detail-transaksi')

</div>

@endsection
