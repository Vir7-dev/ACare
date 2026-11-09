@extends('layouts.admin')

@section('title', 'Beranda - ACare Admin Portal')

@section('content')

<!-- Chart.js CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
function initDashboard() {
    // Instance Chart disimpan di luar state Alpine agar tidak dibungkus proxy reaktif.
    var grafik = null;

    return {
        periodeAktif: '30hari',
        periode: {!! json_encode($periode) !!},
        transaksi: {!! json_encode($transaksi) !!},
        daftarPeriode: [
            { kunci: 'hari', label: 'Hari Ini' },
            { kunci: '7hari', label: '7 Hari' },
            { kunci: '30hari', label: '30 Hari' }
        ],
        kustomTerbuka: false,
        kustomDari: '',
        kustomSampai: '',
        rentangKustom: '',
        cariTransaksi: '',
        filterStatus: 'Semua',

        init: function () {
            var self = this;
            this.$nextTick(function () { self.gambarGrafik(); });
        },

        get data() {
            return this.periode[this.periodeAktif === 'kustom' ? '30hari' : this.periodeAktif];
        },

        get rentangTampil() {
            if (this.periodeAktif === 'kustom' && this.rentangKustom !== '') {
                return this.rentangKustom;
            }
            return this.data.rentang;
        },

        pilihPeriode: function (kunci) {
            this.periodeAktif = kunci;
            this.kustomTerbuka = false;
            this.gambarGrafik();
        },

        terapkanKustom: function () {
            if (this.kustomDari === '' || this.kustomSampai === '') {
                return;
            }
            this.rentangKustom = this.formatTanggal(this.kustomDari) + ' – ' + this.formatTanggal(this.kustomSampai);
            this.periodeAktif = 'kustom';
            this.kustomTerbuka = false;
            this.gambarGrafik();
        },

        formatTanggal: function (iso) {
            var bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
            var bagian = iso.split('-');
            return parseInt(bagian[2], 10) + ' ' + bulan[parseInt(bagian[1], 10) - 1] + ' ' + bagian[0];
        },

        rupiah: function (angka) {
            return 'Rp ' + Number(angka).toLocaleString('id-ID');
        },

        angka: function (nilai) {
            return Number(nilai).toLocaleString('id-ID');
        },

        get transaksiTersaring() {
            var self = this;
            var q = this.cariTransaksi.trim().toLowerCase();
            return this.transaksi.filter(function (t) {
                if (self.filterStatus !== 'Semua' && t.status !== self.filterStatus) {
                    return false;
                }
                if (q === '') {
                    return true;
                }
                return t.id.toLowerCase().includes(q)
                    || t.pelanggan.toLowerCase().includes(q)
                    || t.teknisi.toLowerCase().includes(q)
                    || t.layanan.toLowerCase().includes(q);
            });
        },

        badgeStatus: function (status) {
            if (status === 'Selesai') { return 'text-emerald-600'; }
            if (status === 'Berlangsung') { return 'text-amber-600'; }
            return 'text-rose-600';
        },

        titikStatus: function (status) {
            if (status === 'Selesai') { return 'bg-emerald-500'; }
            if (status === 'Berlangsung') { return 'bg-amber-500'; }
            return 'bg-rose-500';
        },

        labelStatus: function (status) {
            return status === 'Selesai' ? 'Berhasil' : status;
        },

        gambarGrafik: function () {
            var kanvas = this.$refs.kanvasGrafik;
            if (!kanvas || typeof Chart === 'undefined') {
                return;
            }
            var d = this.data.grafik;
            if (grafik) {
                grafik.destroy();
            }
            grafik = new Chart(kanvas.getContext('2d'), {
                type: 'bar',
                data: {
                    labels: d.labels,
                    datasets: [
                        { label: 'Selesai', data: d.selesai, backgroundColor: '#0472FD', barPercentage: 0.6, categoryPercentage: 0.7 },
                        { label: 'Berlangsung', data: d.berlangsung, backgroundColor: '#F59E0B', barPercentage: 0.6, categoryPercentage: 0.7 },
                        { label: 'Dibatalkan', data: d.dibatalkan, backgroundColor: '#F43F5E', barPercentage: 0.6, categoryPercentage: 0.7 }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            backgroundColor: '#0F172A',
                            padding: 10,
                            cornerRadius: 8,
                            callbacks: {
                                label: function (ctx) { return ' ' + ctx.dataset.label + ': ' + ctx.parsed.y + ' pesanan'; }
                            }
                        }
                    },
                    scales: {
                        x: { stacked: true, grid: { display: false }, ticks: { font: { size: 11 }, color: '#475569' } },
                        y: {
                            stacked: true,
                            beginAtZero: true,
                            grid: { color: '#F1F5F9' },
                            ticks: { font: { size: 11 }, color: '#475569' }
                        }
                    }
                }
            });
        }
    };
}
</script>

<div class="min-h-full bg-surface" x-data="initDashboard()" @click.outside="kustomTerbuka = false">

    <!-- Header Halaman -->
    <div class="px-8 pt-6 pb-5 flex flex-wrap items-start justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-navy tracking-tight">Beranda</h1>
            <p class="text-sm text-slate-500 mt-0.5">Ringkasan statistik dan transaksi ACare.</p>
        </div>

        <div class="flex flex-wrap items-center gap-3">
            <!-- Filter Periode -->
            <div class="relative flex items-center bg-white border border-slate-400 rounded-lg p-0.5">
                <template x-for="p in daftarPeriode" :key="p.kunci">
                    <button type="button"
                            @click="pilihPeriode(p.kunci)"
                            :class="periodeAktif === p.kunci ? 'bg-brand-50 text-brand-dark font-bold' : 'text-slate-600 hover:text-navy font-medium'"
                            class="px-3 py-1.5 rounded-md text-xs transition-all"
                            x-text="p.label"></button>
                </template>
                <button type="button"
                        @click.stop="kustomTerbuka = !kustomTerbuka"
                        :class="periodeAktif === 'kustom' ? 'bg-brand-50 text-brand-dark font-bold' : 'text-slate-600 hover:text-navy font-medium'"
                        class="px-3 py-1.5 rounded-md text-xs transition-all flex items-center gap-1">
                    <span>Kustom</span>
                    <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                    </svg>
                </button>

                <!-- Dropdown Rentang Kustom -->
                <div x-show="kustomTerbuka"
                     @click.stop
                     x-transition.opacity
                     class="absolute right-0 top-full mt-2 w-64 bg-white border border-line rounded-lg p-4 z-30"
                     style="display: none;">
                    <label class="block text-xs font-bold text-slate-600 mb-1">Dari tanggal</label>
                    <input type="date" x-model="kustomDari" class="w-full mb-3 px-3 py-2 border border-slate-400 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand">
                    <label class="block text-xs font-bold text-slate-600 mb-1">Sampai tanggal</label>
                    <input type="date" x-model="kustomSampai" :min="kustomDari" class="w-full mb-3 px-3 py-2 border border-slate-400 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand">
                    <button type="button"
                            @click="terapkanKustom()"
                            :disabled="kustomDari === '' || kustomSampai === ''"
                            class="w-full py-2 bg-brand hover:bg-brand-dark disabled:opacity-40 disabled:cursor-not-allowed text-white text-xs font-bold rounded-lg transition-all">
                        Terapkan
                    </button>
                </div>
            </div>

            <!-- Rentang Tanggal -->
            <div class="flex items-center gap-2 text-xs font-medium text-slate-600">
                <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
                <span x-text="rentangTampil"></span>
            </div>
        </div>
    </div>

    <!-- Banner antrean: Verifikasi Teknisi, Pengaduan, Pencairan & Refund -->
    <div class="px-8 pb-5 grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
        <div class="bg-white border border-line border-l-4 border-l-brand rounded-lg px-5 py-4 flex items-center justify-between gap-4">
            <div class="flex items-start gap-3">
                <svg class="w-5 h-5 text-brand-dark flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                </svg>
                <div>
                    <p class="text-sm font-bold text-navy">{{ count($teknisiMenungguVerifikasi) }} teknisi menunggu verifikasi</p>
                    <p class="text-sm text-slate-500 mt-0.5">Berkas identitas dan sertifikat siap divalidasi.</p>
                </div>
            </div>
            <a href="{{ route('admin.pengguna', ['status' => 'menunggu']) }}"
               class="px-4 py-2 bg-brand hover:bg-brand-dark text-white text-xs font-bold rounded-md whitespace-nowrap transition-all">
                Tinjau Sekarang
            </a>
        </div>

        <div class="bg-white border border-line border-l-4 border-l-amber-500 rounded-lg px-5 py-4 flex items-center justify-between gap-4">
            <div class="flex items-start gap-3">
                <svg class="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                </svg>
                <div>
                    <p class="text-sm font-bold text-navy">{{ $jumlahPengaduanBaru }} pengaduan baru</p>
                    <p class="text-sm text-slate-500 mt-0.5">Butuh penanganan dari pelanggan dan teknisi.</p>
                </div>
            </div>
            <a href="{{ route('admin.pengaduan', ['status' => 'Baru']) }}"
               class="px-4 py-2 border border-amber-500 text-amber-700 hover:bg-amber-50 text-xs font-bold rounded-md whitespace-nowrap transition-all">
                Tinjau
            </a>
        </div>

        <div class="bg-white border border-line border-l-4 border-l-emerald-500 rounded-lg px-5 py-4 flex items-center justify-between gap-4">
            <div class="flex items-start gap-3">
                <iconify-icon icon="lucide:wallet" width="20" height="20" class="text-emerald-600 flex-shrink-0 mt-0.5" aria-hidden="true"></iconify-icon>
                <div>
                    <p class="text-sm font-bold text-navy">{{ $jumlahPengajuanMenunggu }} pencairan &amp; refund menunggu</p>
                    <p class="text-sm text-slate-500 mt-0.5">Pengajuan dana teknisi dan pelanggan.</p>
                </div>
            </div>
            <a href="{{ route('admin.pencairan', ['status' => 'Menunggu']) }}"
               class="px-4 py-2 border border-emerald-600 text-emerald-700 hover:bg-emerald-50 text-xs font-bold rounded-md whitespace-nowrap transition-all">
                Tinjau
            </a>
        </div>
    </div>

    <!-- 4 Kartu Ringkasan -->
    <div class="px-8 pb-5 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Total Pesanan</p>
            <p class="text-2xl font-bold text-navy mt-2 truncate" x-text="angka(data.ringkasan.pesanan)"></p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Pesanan Selesai</p>
            <p class="text-2xl font-bold text-navy mt-2 truncate" x-text="angka(data.ringkasan.selesai)"></p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Total Nilai Transaksi</p>
            <p class="text-2xl font-bold text-navy mt-2 truncate" :title="rupiah(data.ringkasan.nilai)" x-text="rupiah(data.ringkasan.nilai)"></p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Teknisi Aktif</p>
            <p class="text-2xl font-bold text-navy mt-2" x-text="angka(data.ringkasan.teknisi)"></p>
        </div>
    </div>

    <!-- Grafik Jumlah Pesanan per Periode -->
    <div class="px-8 pb-5">
        <div class="bg-white border border-line rounded-lg p-6">
            <div class="flex items-start justify-between mb-4">
                <div>
                    <h2 class="text-base font-bold text-navy tracking-tight">Jumlah Pesanan per Periode</h2>
                    <p class="text-sm text-slate-500 mt-0.5">Pesanan selesai, berlangsung, dan dibatalkan.</p>
                </div>
                <div class="flex items-center gap-5 text-xs font-medium text-slate-700">
                    <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-sm bg-brand block"></span>Selesai</span>
                    <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-sm bg-amber-500 block"></span>Berlangsung</span>
                    <span class="flex items-center gap-1.5"><span class="w-3 h-3 rounded-sm bg-rose-500 block"></span>Dibatalkan</span>
                </div>
            </div>
            <div class="relative h-72">
                <canvas x-ref="kanvasGrafik"></canvas>
            </div>
        </div>
    </div>

    <!-- Transaksi Terbaru -->
    <div class="px-8 pb-8">
        <div class="bg-white border border-line rounded-lg overflow-hidden">

            <div class="px-6 py-5 flex items-center justify-between gap-4">
                <div>
                    <h2 class="text-base font-bold text-navy tracking-tight">Transaksi Terbaru</h2>
                    <p class="text-sm text-slate-500 mt-0.5">Daftar transaksi pesanan layanan terkini.</p>
                </div>
                <div class="flex items-center gap-3">
                    <div class="relative w-52">
                        <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                        </span>
                        <input type="text"
                               x-model="cariTransaksi"
                               placeholder="Cari transaksi..."
                               class="w-full pl-9 pr-3 py-2 bg-white border border-slate-400 rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
                    </div>
                    <select x-model="filterStatus"
                            class="px-3 py-2 bg-white border border-slate-400 rounded-lg text-sm font-medium text-slate-800 focus:outline-none focus:ring-2 focus:ring-brand">
                        <option value="Semua">Semua Status</option>
                        <option value="Selesai">Berhasil</option>
                        <option value="Berlangsung">Berlangsung</option>
                        <option value="Dibatalkan">Dibatalkan</option>
                    </select>
                </div>
            </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-slate-50 border-y border-line text-xs font-bold text-slate-600">
                            <th class="py-3 px-6">ID &amp; Waktu</th>
                            <th class="py-3 px-4">Pelanggan</th>
                            <th class="py-3 px-4">Teknisi</th>
                            <th class="py-3 px-4">Layanan</th>
                            <th class="py-3 px-4 text-right">Nominal</th>
                            <th class="py-3 px-4">Status</th>
                            <th class="py-3 px-6 text-center">Aksi</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-line text-sm">
                        <template x-for="t in transaksiTersaring" :key="t.id">
                            <tr class="hover:bg-slate-50 transition-colors">
                                <td class="py-3.5 px-6">
                                    <p class="font-bold text-navy" x-text="'#' + t.id"></p>
                                    <p class="text-xs text-slate-500" x-text="t.tanggal + ', ' + t.jam"></p>
                                </td>
                                <td class="py-3.5 px-4 font-bold text-slate-800" x-text="t.pelanggan"></td>
                                <td class="py-3.5 px-4 text-slate-600" x-text="t.teknisi"></td>
                                <td class="py-3.5 px-4 text-slate-700" x-text="t.layanan"></td>
                                <td class="py-3.5 px-4 text-right font-bold text-navy whitespace-nowrap" x-text="rupiah(t.harga)"></td>
                                <td class="py-3.5 px-4">
                                    <span class="inline-flex items-center gap-1.5 font-semibold" :class="badgeStatus(t.status)">
                                        <span x-text="labelStatus(t.status)"></span>
                                    </span>
                                </td>
                                <td class="py-3.5 px-6 text-center">
                                    <button type="button"
                                            @click="$dispatch('buka-detail-transaksi', { id: t.id })"
                                            :aria-label="'Lihat detail ' + t.id"
                                            class="inline-block px-3 py-1.5 border border-brand text-brand-dark hover:bg-brand-50 rounded-lg text-xs font-semibold transition-colors">
                                        Detail
                                    </button>
                                </td>
                            </tr>
                        </template>
                        <tr x-show="transaksiTersaring.length === 0" style="display: none;">
                            <td colspan="7" class="py-10 text-center text-slate-500 text-xs font-medium">
                                Tidak ada transaksi yang cocok.
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="px-6 py-3.5 border-t border-line flex items-center justify-between text-xs text-slate-500 font-medium">
                <span x-show="transaksiTersaring.length !== transaksi.length" x-text="'Menampilkan ' + transaksiTersaring.length + ' dari ' + transaksi.length + ' transaksi terbaru'"></span>
                <span x-show="transaksiTersaring.length === transaksi.length"></span>
                <a href="{{ route('admin.transaksi') }}" class="text-brand-dark font-bold hover:underline flex items-center gap-1.5">
                    <span>Lihat semua transaksi</span>
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                    </svg>
                </a>
            </div>
        </div>
    </div>

    @include('admin.partials.detail-transaksi')

</div>

@endsection
