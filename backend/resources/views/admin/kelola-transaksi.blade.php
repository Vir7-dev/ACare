@extends('layouts.admin')

@section('title', 'Kelola Transaksi & Bukti Pengerjaan - ACare Admin Portal')

@section('content')

<style>
    [x-cloak] { display: none !important; }

    @media print {
        body * { visibility: hidden; }
        #printableInvoice, #printableInvoice * { visibility: visible; }
        #printableInvoice {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            background: white !important;
            padding: 20px;
        }
    }
</style>

<script>
function initKelolaTransaksi() {
    return {
        filterStatus: 'Semua',
        searchQuery: '',
        transaksiList: {!! json_encode($transaksiList) !!},
        selectedTrx: null,
        showDetailModal: false,
        showInvoiceModal: false,

        get filteredList() {
            var self = this;
            return this.transaksiList.filter(function(t) {
                if (self.filterStatus !== 'Semua' && t.status !== self.filterStatus) return false;
                if (self.searchQuery.trim() !== '') {
                    var q = self.searchQuery.toLowerCase();
                    var match = t.id.toLowerCase().includes(q) ||
                                t.pelanggan.toLowerCase().includes(q) ||
                                t.teknisi.toLowerCase().includes(q) ||
                                t.layanan.toLowerCase().includes(q) ||
                                t.alamat.toLowerCase().includes(q) ||
                                t.unit_ac.toLowerCase().includes(q);
                    if (!match) return false;
                }
                return true;
            });
        },

        bukaDetail(trx) {
            this.selectedTrx = trx;
            this.showDetailModal = true;
        },

        bukaInvoice(trx) {
            this.selectedTrx = trx;
            this.showInvoiceModal = true;
        },

        cetakInvoice() {
            window.print();
        },

        eksporCSV() {
            var headers = ['ID Transaksi', 'Tanggal', 'Jam', 'Pelanggan', 'Telepon', 'Alamat', 'Layanan', 'Unit AC', 'Teknisi', 'Biaya', 'Metode Bayar', 'Status'];
            var rows = this.transaksiList.map(function(t) {
                return [
                    t.id,
                    t.tanggal,
                    t.jam,
                    '"' + t.pelanggan + '"',
                    '"' + t.telepon_pelanggan + '"',
                    '"' + t.alamat + '"',
                    '"' + t.layanan + '"',
                    '"' + t.unit_ac + '"',
                    '"' + t.teknisi + '"',
                    t.total_biaya,
                    '"' + t.metode_bayar + '"',
                    t.status
                ];
            });

            var csvContent = 'data:text/csv;charset=utf-8,\uFEFF' + [headers.join(',')].concat(rows.map(function(e) { return e.join(','); })).join('\n');
            var encodedUri = encodeURI(csvContent);
            var link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            link.setAttribute('download', 'Laporan_Transaksi_ACare_' + new Date().toISOString().slice(0, 10) + '.csv');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    };
}
</script>

<div class="p-8" x-data="initKelolaTransaksi()">

    <!-- Breadcrumb: Beranda > Kelola Transaksi -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-400 mb-2">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-[#0284C7] transition-colors flex items-center gap-1">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            Beranda
        </a>
        <span>&gt;</span>
        <span class="text-slate-600 font-semibold">Kelola Transaksi &amp; Bukti Pengerjaan</span>
    </div>

    <!-- Title & Action Buttons -->
    <div class="mb-6 flex items-start justify-between">
        <div>
            <h1 class="text-xl font-extrabold text-slate-900 tracking-tight">Kelola Transaksi Layanan AC</h1>
            <p class="text-xs text-slate-400 font-medium mt-0.5">Monitoring pesanan masuk, progres teknisi di lapangan, serta bukti foto pengerjaan servis AC.</p>
        </div>

        <div class="flex items-center gap-2.5">
            <button @click="eksporCSV()"
                    class="flex items-center gap-2 px-3.5 py-2 bg-white border border-slate-200 text-slate-700 font-bold text-xs rounded-xl shadow-sm hover:bg-slate-50 transition-all">
                <svg class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
                <span>Download Excel (CSV)</span>
            </button>
            <button @click="window.print()"
                    class="flex items-center gap-2 px-3.5 py-2 bg-[#0284C7] hover:bg-[#0369a1] text-white font-bold text-xs rounded-xl shadow-md shadow-sky-500/20 transition-all">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
                </svg>
                <span>Cetak Rekap PDF</span>
            </button>
        </div>
    </div>

    <!-- 4 RINGKASAN METRIC CARDS -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center gap-3.5">
            <div class="w-11 h-11 bg-sky-50 rounded-xl flex items-center justify-center text-[#0284C7] flex-shrink-0">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] font-semibold text-slate-400">Total Transaksi</p>
                <p class="text-xl font-extrabold text-slate-900 leading-tight">{{ $stats['total'] }} Order</p>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center gap-3.5">
            <div class="w-11 h-11 bg-emerald-50 rounded-xl flex items-center justify-center text-emerald-600 flex-shrink-0">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] font-semibold text-slate-400">Pesanan Selesai</p>
                <p class="text-xl font-extrabold text-emerald-700 leading-tight">{{ $stats['selesai'] }} Selesai</p>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center gap-3.5">
            <div class="w-11 h-11 bg-amber-50 rounded-xl flex items-center justify-center text-amber-600 flex-shrink-0">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] font-semibold text-slate-400">Sedang Dikerjakan</p>
                <p class="text-xl font-extrabold text-amber-700 leading-tight">{{ $stats['berlangsung'] }} Aktif</p>
            </div>
        </div>

        <div class="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center gap-3.5">
            <div class="w-11 h-11 bg-violet-50 rounded-xl flex items-center justify-center text-violet-600 flex-shrink-0">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] font-semibold text-slate-400">Total Omzet Lunas</p>
                <p class="text-xl font-extrabold text-slate-900 leading-tight">Rp {{ number_format($stats['omzet'], 0, ',', '.') }}</p>
            </div>
        </div>
    </div>

    <!-- FILTER BAR & SEARCH -->
    <div class="bg-white rounded-2xl border border-slate-200/80 p-4 mb-5 shadow-sm flex items-center justify-between gap-4">
        
        <!-- Filter Tabs -->
        <div class="flex items-center gap-1 bg-slate-100 p-1 rounded-xl text-xs font-semibold">
            <template x-for="st in ['Semua', 'Selesai', 'Berlangsung', 'Dibatalkan']" :key="st">
                <button @click="filterStatus = st"
                        :class="filterStatus === st ? 'bg-white text-slate-900 shadow-sm font-bold' : 'text-slate-500 hover:text-slate-800'"
                        class="px-3.5 py-1.5 rounded-lg transition-all"
                        x-text="st">
                </button>
            </template>
        </div>

        <!-- Search Input -->
        <div class="relative w-80">
            <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </span>
            <input type="text"
                   x-model="searchQuery"
                   placeholder="Cari ID, pelanggan, teknisi, atau alamat..."
                   class="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0284C7] focus:bg-white transition-all">
        </div>
    </div>

    <!-- TABEL TRANSAKSI -->
    <div class="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-[#EBF2FC] text-[11px] font-bold text-slate-600">
                        <th class="py-3 px-5">ID Order</th>
                        <th class="py-3 px-4">Tanggal &amp; Jam</th>
                        <th class="py-3 px-4">Pelanggan &amp; Alamat</th>
                        <th class="py-3 px-4">Layanan &amp; Unit</th>
                        <th class="py-3 px-4">Teknisi</th>
                        <th class="py-3 px-4 text-right">Biaya</th>
                        <th class="py-3 px-4 text-center">Status</th>
                        <th class="py-3 px-5 text-center">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 text-xs">
                    <template x-for="trx in filteredList" :key="trx.id">
                        <tr class="hover:bg-slate-50/80 transition-colors">
                            <!-- ID -->
                            <td class="py-3.5 px-5 font-mono font-bold text-[#0284C7]" x-text="trx.id"></td>

                            <!-- Tanggal & Jam -->
                            <td class="py-3.5 px-4 text-slate-600">
                                <p class="font-bold text-slate-800" x-text="trx.tanggal"></p>
                                <p class="text-[10px] text-slate-400" x-text="trx.jam"></p>
                            </td>

                            <!-- Pelanggan & Alamat -->
                            <td class="py-3.5 px-4">
                                <p class="font-bold text-slate-900" x-text="trx.pelanggan"></p>
                                <p class="text-[10px] text-slate-400 truncate max-w-xs" x-text="trx.alamat"></p>
                            </td>

                            <!-- Layanan & Unit AC -->
                            <td class="py-3.5 px-4">
                                <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-sky-50 text-[#0284C7]" x-text="trx.layanan"></span>
                                <p class="text-[10px] text-slate-500 font-medium mt-0.5 truncate max-w-xs" x-text="trx.unit_ac"></p>
                            </td>

                            <!-- Teknisi -->
                            <td class="py-3.5 px-4">
                                <div class="flex items-center gap-1.5 text-slate-700 font-semibold">
                                    <span class="w-2 h-2 rounded-full bg-emerald-500 flex-shrink-0"></span>
                                    <span x-text="trx.teknisi"></span>
                                </div>
                            </td>

                            <!-- Biaya -->
                            <td class="py-3.5 px-4 text-right">
                                <p class="font-extrabold text-slate-900" x-text="'Rp ' + Number(trx.total_biaya).toLocaleString('id-ID')"></p>
                                <p class="text-[9px] text-slate-400" x-text="trx.metode_bayar"></p>
                            </td>

                            <!-- Status Badge -->
                            <td class="py-3.5 px-4 text-center">
                                <template x-if="trx.status === 'Selesai'">
                                    <span class="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#4ADE80] text-white">
                                        Selesai
                                    </span>
                                </template>
                                <template x-if="trx.status === 'Berlangsung'">
                                    <span class="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#FBBF24] text-white">
                                        Berlangsung
                                    </span>
                                </template>
                                <template x-if="trx.status === 'Dibatalkan'">
                                    <span class="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#F87171] text-white">
                                        Dibatalkan
                                    </span>
                                </template>
                            </td>

                            <!-- Aksi -->
                            <td class="py-3.5 px-5 text-center">
                                <button @click="bukaDetail(trx)"
                                        class="px-3 py-1.5 bg-sky-50 hover:bg-sky-100 text-[#0284C7] font-bold text-[11px] rounded-xl border border-sky-200 transition-all flex items-center gap-1 mx-auto">
                                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                    </svg>
                                    <span>Bukti &amp; Detail</span>
                                </button>
                            </td>
                        </tr>
                    </template>
                </tbody>
            </table>
        </div>

        <div class="px-6 py-3.5 border-t border-slate-100 flex items-center justify-between text-xs text-slate-400 font-medium">
            <span x-text="'Menampilkan ' + filteredList.length + ' dari total ' + transaksiList.length + ' transaksi ACare'"></span>
            <span>Update Real-time dari Teknisi Lapangan</span>
        </div>
    </div>

    <!-- ===================== MODAL DETAIL TRANSAKSI & BUKTI PENGERJAAN ===================== -->
    <div x-show="showDetailModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 overflow-y-auto"
         style="display: none;">
        
        <div @click.away="showDetailModal = false"
             class="bg-white rounded-3xl max-w-2xl w-full overflow-hidden shadow-2xl border border-slate-200 my-8">
            
            <!-- Modal Header -->
            <div class="bg-[#0284C7] text-white p-5 flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                        </svg>
                    </div>
                    <div>
                        <div class="flex items-center gap-2">
                            <span class="text-sm font-black font-mono tracking-wider" x-text="selectedTrx ? selectedTrx.id : ''"></span>
                            <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-white text-[#0284C7]" x-text="selectedTrx ? selectedTrx.status : ''"></span>
                        </div>
                        <p class="text-xs text-sky-100" x-text="(selectedTrx ? selectedTrx.layanan : '') + ' • ' + (selectedTrx ? selectedTrx.tanggal : '')"></p>
                    </div>
                </div>

                <div class="flex items-center gap-2">
                    <button @click="bukaInvoice(selectedTrx)"
                            class="px-3 py-1.5 bg-white/20 hover:bg-white/30 text-white rounded-xl text-xs font-bold transition-all flex items-center gap-1.5">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
                        </svg>
                        <span>Kuitansi</span>
                    </button>
                    <button @click="showDetailModal = false" class="text-sky-100 hover:text-white p-1">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
            </div>

            <!-- Modal Content Body -->
            <div class="p-6 space-y-5 max-h-[80vh] overflow-y-auto text-xs" x-if="selectedTrx">

                <!-- 1. INFO PELANGGAN & TEKNISI -->
                <div class="grid grid-cols-2 gap-4">
                    <div class="bg-slate-50 p-4 rounded-2xl border border-slate-200">
                        <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Data Pelanggan</p>
                        <p class="font-extrabold text-sm text-slate-900" x-text="selectedTrx ? selectedTrx.pelanggan : ''"></p>
                        <p class="text-slate-600 mt-1 flex items-center gap-1.5">
                            <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                            </svg>
                            <span x-text="selectedTrx ? selectedTrx.telepon_pelanggan : ''"></span>
                        </p>
                        <p class="text-slate-500 mt-1" x-text="selectedTrx ? selectedTrx.alamat : ''"></p>
                    </div>

                    <div class="bg-slate-50 p-4 rounded-2xl border border-slate-200">
                        <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Teknisi Bertugas</p>
                        <p class="font-extrabold text-sm text-[#0284C7]" x-text="selectedTrx ? selectedTrx.teknisi : ''"></p>
                        <p class="text-slate-600 mt-1 flex items-center gap-1.5">
                            <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                            </svg>
                            <span x-text="selectedTrx ? selectedTrx.telepon_teknisi : ''"></span>
                        </p>
                        <p class="text-slate-500 mt-1" x-text="'Durasi Pengerjaan: ' + (selectedTrx ? selectedTrx.durasi : '')"></p>
                    </div>
                </div>

                <!-- 2. DETAIL UNIT AC & KELUHAN -->
                <div class="bg-sky-50/70 p-4 rounded-2xl border border-sky-100">
                    <p class="text-[10px] font-bold text-sky-800 uppercase tracking-wider mb-1">Unit AC &amp; Keluhan Awal Pelanggan</p>
                    <p class="font-bold text-slate-900" x-text="selectedTrx ? selectedTrx.unit_ac : ''"></p>
                    <p class="text-slate-600 mt-1 italic" x-text="'\"' + (selectedTrx ? selectedTrx.keluhan : '') + '\"'"></p>
                </div>

                <!-- 3. BUKTI FOTO & PROGRES PENGERJAAN TEKNISI -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wider">Bukti Pengerjaan Teknisi Lapangan</h4>
                        <span class="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-2.5 py-0.5 rounded-full">✓ Tuntas Diverifikasi</span>
                    </div>

                    <div class="grid grid-cols-3 gap-3">
                        <!-- Sebelum -->
                        <div class="bg-slate-50 rounded-xl p-3 border border-slate-200 text-center">
                            <div class="h-24 bg-slate-200 rounded-lg flex flex-col items-center justify-center p-2 mb-2 text-slate-500 border border-slate-300">
                                <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                                </svg>
                                <span class="text-[9px] font-black uppercase mt-1 text-slate-600">[FOTO SEBELUM]</span>
                            </div>
                            <p class="text-[10px] font-bold text-rose-600 uppercase">1. Sebelum Servis</p>
                            <p class="text-[10px] text-slate-600 mt-1 line-clamp-2" x-text="selectedTrx && selectedTrx.bukti ? selectedTrx.bukti.sebelum : ''"></p>
                        </div>

                        <!-- Saat Pengerjaan -->
                        <div class="bg-slate-50 rounded-xl p-3 border border-slate-200 text-center">
                            <div class="h-24 bg-sky-100 rounded-lg flex flex-col items-center justify-center p-2 mb-2 text-sky-700 border border-sky-300">
                                <svg class="w-8 h-8 text-[#0284C7]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M14.121 14.121L19 19m-7-7l7-7m-7 7l-2.879 2.879a3 3 0 11-4.242-4.242L10.757 7.757"/>
                                </svg>
                                <span class="text-[9px] font-black uppercase mt-1 text-sky-800">[FOTO PROSES STEAM]</span>
                            </div>
                            <p class="text-[10px] font-bold text-[#0284C7] uppercase">2. Proses Servis</p>
                            <p class="text-[10px] text-slate-600 mt-1 line-clamp-2" x-text="selectedTrx && selectedTrx.bukti ? selectedTrx.bukti.proses : ''"></p>
                        </div>

                        <!-- Sesudah -->
                        <div class="bg-slate-50 rounded-xl p-3 border border-slate-200 text-center">
                            <div class="h-24 bg-emerald-100 rounded-lg flex flex-col items-center justify-center p-2 mb-2 text-emerald-700 border border-emerald-300">
                                <svg class="w-8 h-8 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                                <span class="text-[9px] font-black uppercase mt-1 text-emerald-800">[FOTO SELESAI &amp; SUHU 16°C]</span>
                            </div>
                            <p class="text-[10px] font-bold text-emerald-700 uppercase">3. Sesudah Servis</p>
                            <p class="text-[10px] text-slate-600 mt-1 line-clamp-2" x-text="selectedTrx && selectedTrx.bukti ? selectedTrx.bukti.sesudah : ''"></p>
                        </div>
                    </div>

                    <!-- Catatan Teknis Lapangan -->
                    <div class="mt-3 p-3 bg-amber-50/70 border border-amber-200 rounded-xl">
                        <p class="text-[10px] font-bold text-amber-900 uppercase">Catatan &amp; Diagnosa Pengujian Teknisi:</p>
                        <p class="text-xs text-amber-950 mt-0.5" x-text="selectedTrx && selectedTrx.bukti ? selectedTrx.bukti.catatan_teknisi : ''"></p>
                    </div>
                </div>

                <!-- 4. RINCIAN BIAYA & PEMBAYARAN -->
                <div>
                    <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wider mb-2">Rincian Biaya Servis</h4>
                    <div class="border border-slate-200 rounded-xl divide-y divide-slate-100 overflow-hidden">
                        <template x-for="item in (selectedTrx ? selectedTrx.rincian : [])" :key="item.item">
                            <div class="p-2.5 flex items-center justify-between text-xs">
                                <span class="text-slate-700 font-medium" x-text="item.item"></span>
                                <span class="font-bold text-slate-900" x-text="'Rp ' + Number(item.biaya).toLocaleString('id-ID')"></span>
                            </div>
                        </template>
                        <div class="p-3 bg-slate-50 flex items-center justify-between font-extrabold text-sm">
                            <span class="text-slate-900">Total Pembayaran (<span class="text-emerald-600 font-bold" x-text="selectedTrx ? selectedTrx.status_bayar : ''"></span>)</span>
                            <span class="text-[#0284C7]" x-text="'Rp ' + (selectedTrx ? Number(selectedTrx.total_biaya).toLocaleString('id-ID') : 0)"></span>
                        </div>
                    </div>
                </div>

            </div>

            <!-- Modal Footer -->
            <div class="p-4 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
                <button @click="bukaInvoice(selectedTrx)"
                        class="px-4 py-2 bg-white border border-slate-300 text-slate-700 hover:bg-slate-100 font-bold rounded-xl text-xs transition-all flex items-center gap-1.5 shadow-sm">
                    <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
                    </svg>
                    <span>Cetak Invoice / Kuitansi</span>
                </button>
                <button @click="showDetailModal = false"
                        class="px-5 py-2 bg-slate-900 text-white font-bold rounded-xl text-xs hover:bg-slate-800 transition-all">
                    Tutup
                </button>
            </div>

        </div>
    </div>

    <!-- ===================== MODAL KUITANSI / INVOICE CETAK RESMI ===================== -->
    <div x-show="showInvoiceModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 overflow-y-auto"
         style="display: none;">
        
        <div @click.away="showInvoiceModal = false"
             class="bg-white rounded-3xl max-w-lg w-full overflow-hidden shadow-2xl border border-slate-200 my-8">
            
            <div id="printableInvoice" class="p-8 text-slate-800">
                <!-- Header Invoice Resmi -->
                <div class="flex items-start justify-between border-b-2 border-slate-900 pb-4 mb-4">
                    <div>
                        <img src="{{ asset('images/acare-logo.png') }}" alt="ACare" class="h-8 w-auto mb-1">
                        <p class="text-[10px] text-slate-500">PT ACare Solusi Sejuk Indonesia</p>
                        <p class="text-[10px] text-slate-500">Batam Center, Kepulauan Riau • support@acare.id</p>
                    </div>
                    <div class="text-right">
                        <h2 class="text-lg font-black uppercase text-slate-900 tracking-wider">KUITANSI RESMI</h2>
                        <p class="text-xs font-mono font-bold text-[#0284C7]" x-text="selectedTrx ? selectedTrx.id : ''"></p>
                        <p class="text-[10px] text-slate-500" x-text="selectedTrx ? selectedTrx.tanggal : ''"></p>
                    </div>
                </div>

                <!-- Info Pelanggan & Teknisi -->
                <div class="grid grid-cols-2 gap-4 text-xs mb-5">
                    <div>
                        <p class="text-[10px] font-bold text-slate-400 uppercase">Diterbitkan Untuk:</p>
                        <p class="font-bold text-slate-900" x-text="selectedTrx ? selectedTrx.pelanggan : ''"></p>
                        <p class="text-slate-600 text-[11px]" x-text="selectedTrx ? selectedTrx.telepon_pelanggan : ''"></p>
                        <p class="text-slate-500 text-[11px]" x-text="selectedTrx ? selectedTrx.alamat : ''"></p>
                    </div>
                    <div class="text-right">
                        <p class="text-[10px] font-bold text-slate-400 uppercase">Teknisi Bertugas:</p>
                        <p class="font-bold text-slate-900" x-text="selectedTrx ? selectedTrx.teknisi : ''"></p>
                        <p class="text-slate-600 text-[11px]" x-text="selectedTrx ? selectedTrx.layanan : ''"></p>
                        <p class="text-slate-500 text-[11px]" x-text="selectedTrx ? selectedTrx.unit_ac : ''"></p>
                    </div>
                </div>

                <!-- Tabel Item Biaya -->
                <table class="w-full text-xs text-left border-collapse mb-5">
                    <thead>
                        <tr class="border-b border-slate-300 text-[10px] uppercase font-bold text-slate-500">
                            <th class="py-2">Deskripsi Layanan / Part</th>
                            <th class="py-2 text-right">Jumlah</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        <template x-for="item in (selectedTrx ? selectedTrx.rincian : [])" :key="item.item">
                            <tr>
                                <td class="py-2.5 text-slate-800 font-medium" x-text="item.item"></td>
                                <td class="py-2.5 text-right font-bold text-slate-900" x-text="'Rp ' + Number(item.biaya).toLocaleString('id-ID')"></td>
                            </tr>
                        </template>
                    </tbody>
                    <tfoot>
                        <tr class="border-t-2 border-slate-900">
                            <td class="py-3 font-extrabold text-slate-900 text-sm">TOTAL PEMBAYARAN</td>
                            <td class="py-3 text-right font-black text-[#0284C7] text-base" x-text="'Rp ' + (selectedTrx ? Number(selectedTrx.total_biaya).toLocaleString('id-ID') : 0)"></td>
                        </tr>
                    </tfoot>
                </table>

                <!-- Info Lunas Stamp -->
                <div class="flex items-center justify-between pt-2 border-t border-dashed border-slate-200">
                    <div class="inline-block px-3 py-1 bg-emerald-100 border border-emerald-300 rounded-lg text-emerald-800 font-extrabold text-xs uppercase tracking-wider">
                        ✓ LUNAS VIA <span x-text="selectedTrx ? selectedTrx.metode_bayar : ''"></span>
                    </div>
                    <div class="text-center text-[10px] text-slate-500">
                        <p class="font-bold text-slate-800">Admin Operasional ACare</p>
                        <p class="italic text-[9px] mt-4">(Tervalidasi Digital)</p>
                    </div>
                </div>
            </div>

            <!-- Footer Action -->
            <div class="p-4 bg-slate-50 border-t border-slate-100 flex items-center justify-end gap-2.5">
                <button @click="showInvoiceModal = false" class="px-4 py-2 bg-slate-200 hover:bg-slate-300 text-slate-700 font-bold rounded-xl text-xs transition-all">
                    Tutup
                </button>
                <button @click="cetakInvoice()" class="px-5 py-2 bg-[#0284C7] hover:bg-[#0369a1] text-white font-bold rounded-xl text-xs shadow transition-all flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
                    </svg>
                    <span>Cetak Sekarang</span>
                </button>
            </div>

        </div>
    </div>

</div>

@endsection
