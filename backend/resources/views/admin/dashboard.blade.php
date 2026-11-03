@extends('layouts.admin')

@section('title', 'Beranda Dashboard - ACare Admin Portal')

@section('content')

<style>
    [x-cloak] { display: none !important; }

    .stat-gradient-1 { background: linear-gradient(135deg, #0284C7 0%, #0ea5e9 100%); }
    .stat-gradient-2 { background: linear-gradient(135deg, #059669 0%, #10b981 100%); }
    .stat-gradient-3 { background: linear-gradient(135deg, #7c3aed 0%, #a78bfa 100%); }
    .stat-gradient-4 { background: linear-gradient(135deg, #d97706 0%, #fbbf24 100%); }

    .shimmer {
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.22), transparent);
        background-size: 200% 100%;
        animation: shimmer 3s infinite;
    }
    @keyframes shimmer {
        0% { background-position: -200% 0; }
        100% { background-position: 200% 0; }
    }

    .badge-selesai     { background: #dcfce7; color: #15803d; }
    .badge-berlangsung { background: #fef3c7; color: #b45309; }
    .badge-dibatalkan  { background: #fee2e2; color: #dc2626; }
</style>

<script>
function initDashboard() {
    return {
        filterPeriode: 'Bulan Ini',
        filterStatus: 'Semua',
        showExportModal: false,
        periode: ['Minggu Ini', 'Bulan Ini', '3 Bulan', '6 Bulan', 'Tahun Ini'],
        transaksi: {!! json_encode($transaksi) !!},

        downloadCSV() {
            var headers = ['ID Transaksi', 'Tanggal', 'Pelanggan', 'Layanan', 'Teknisi', 'Harga', 'Status'];
            var rows = this.transaksi.map(function(t) {
                return [
                    t.id,
                    t.tanggal,
                    '"' + t.pelanggan + '"',
                    '"' + t.layanan + '"',
                    '"' + t.teknisi + '"',
                    t.harga,
                    t.status
                ];
            });
            var csvContent = 'data:text/csv;charset=utf-8,\uFEFF' + [headers.join(',')].concat(rows.map(function(e) { return e.join(','); })).join('\n');
            var encodedUri = encodeURI(csvContent);
            var link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            link.setAttribute('download', 'Laporan_Eksekutif_ACare_' + new Date().toISOString().slice(0, 10) + '.csv');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            this.showExportModal = false;
        },

        printReport() {
            this.showExportModal = false;
            setTimeout(function() { window.print(); }, 200);
        }
    };
}
</script>

<div class="min-h-full bg-slate-50/60" x-data="initDashboard()">

    <!-- Top Breadcrumb & Page Header -->
    <div class="px-8 pt-6 pb-4">
        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 text-xs font-medium text-slate-400 mb-2">
            <span class="text-slate-700 font-semibold flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5 text-[#0284C7]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                </svg>
                Beranda
            </span>
            <span>&gt;</span>
            <span class="text-slate-400">Ringkasan Statistik &amp; Transaksi</span>
        </div>

        <div class="flex items-start justify-between">
            <div>
                <h1 class="text-xl font-extrabold text-slate-900 tracking-tight">Beranda Dashboard</h1>
                <p class="text-xs text-slate-500 mt-0.5">Ringkasan transaksi, pendapatan, teknisi, dan performa layanan ACare secara real-time.</p>
            </div>

            <!-- Periode Filter & Action Buttons -->
            <div class="flex items-center gap-2.5">
                <div class="flex bg-white border border-slate-200 rounded-xl p-1 shadow-sm gap-0.5">
                    <template x-for="p in periode" :key="p">
                        <button @click="filterPeriode = p"
                            :class="filterPeriode === p
                                ? 'bg-[#0284C7] text-white shadow-sm font-bold'
                                : 'text-slate-500 hover:text-slate-800 font-semibold'"
                            class="px-3 py-1.5 rounded-lg text-xs transition-all duration-150"
                            x-text="p">
                        </button>
                    </template>
                </div>
                <button @click="showExportModal = true"
                        class="flex items-center gap-1.5 px-3.5 py-2 bg-[#0284C7] text-white text-xs font-bold rounded-xl shadow-sm hover:bg-[#0369a1] transition-all">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                    </svg>
                    <span>Ekspor Laporan</span>
                </button>
            </div>
        </div>
    </div>

    <!-- Alert Banner: 3 Teknisi Menunggu Verifikasi Segera (Direct Action Bridge ke Kelola Pengguna) -->
    <div class="px-8 mb-5">
        <div class="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200/80 rounded-2xl p-4 flex items-center justify-between shadow-sm">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-amber-500 text-white flex items-center justify-center font-bold text-lg shadow-sm flex-shrink-0">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                    </svg>
                </div>
                <div>
                    <div class="flex items-center gap-2">
                        <span class="text-xs font-bold text-amber-900">Perhatian: Ada 3 Pengajuan Teknisi Menunggu Verifikasi</span>
                        <span class="px-2 py-0.5 rounded-full bg-amber-200/70 text-amber-900 text-[10px] font-bold">Prioritas</span>
                    </div>
                    <p class="text-[11px] text-amber-800/90 mt-0.5">
                        Teknisi <span class="font-bold text-slate-800">GanAnWo</span>, <span class="font-bold text-slate-800">Rendi Kurniawan</span>, dan <span class="font-bold text-slate-800">Dian Pratama</span> telah mengunggah berkas sertifikasi dan menunggu persetujuan Anda.
                    </p>
                </div>
            </div>
            <a href="{{ route('admin.pengguna') }}"
               class="flex items-center gap-1.5 px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white font-bold text-xs rounded-xl shadow-sm transition-all flex-shrink-0">
                <span>Periksa &amp; Verifikasi Sekarang</span>
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                </svg>
            </a>
        </div>
    </div>

    <!-- 4 KARTU STATISTIK UTAMA -->
    <div class="px-8 pb-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">

        <!-- Card 1: Total Transaksi -->
        <div class="stat-gradient-1 rounded-2xl p-5 shadow-lg shadow-sky-500/10 relative overflow-hidden text-white">
            <div class="shimmer absolute inset-0 pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-3">
                    <div class="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/25 text-white px-2 py-0.5 rounded-full">▲ +24 bln ini</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Total Transaksi</p>
                <p class="text-white text-3xl font-black mt-0.5 tracking-tight">631</p>
                <p class="text-white/70 text-[11px] mt-1">Layanan selesai &amp; berlangsung</p>
            </div>
        </div>

        <!-- Card 2: Pendapatan Bulan Ini -->
        <div class="stat-gradient-2 rounded-2xl p-5 shadow-lg shadow-emerald-500/10 relative overflow-hidden text-white">
            <div class="shimmer absolute inset-0 pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-3">
                    <div class="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/25 text-white px-2 py-0.5 rounded-full">▲ +12%</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Pendapatan Bulan Ini</p>
                <p class="text-white text-3xl font-black mt-0.5 tracking-tight">Rp 18,4 Jt</p>
                <p class="text-white/70 text-[11px] mt-1">Naik dari Rp 16,3 Jt bulan lalu</p>
            </div>
        </div>

        <!-- Card 3: Teknisi Aktif -->
        <div class="stat-gradient-3 rounded-2xl p-5 shadow-lg shadow-violet-500/10 relative overflow-hidden text-white">
            <div class="shimmer absolute inset-0 pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-3">
                    <div class="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/25 text-white px-2 py-0.5 rounded-full">3 Menunggu</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Teknisi Terverifikasi</p>
                <p class="text-white text-3xl font-black mt-0.5 tracking-tight">28</p>
                <p class="text-white/70 text-[11px] mt-1">Siap melayani orderan aktif</p>
            </div>
        </div>

        <!-- Card 4: Pengguna Terdaftar -->
        <div class="stat-gradient-4 rounded-2xl p-5 shadow-lg shadow-amber-500/10 relative overflow-hidden text-white">
            <div class="shimmer absolute inset-0 pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-3">
                    <div class="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/25 text-white px-2 py-0.5 rounded-full">▲ +87 Baru</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Pengguna Terdaftar</p>
                <p class="text-white text-3xl font-black mt-0.5 tracking-tight">1.240</p>
                <p class="text-white/70 text-[11px] mt-1">Total akun pelanggan ACare</p>
            </div>
        </div>

    </div>

    <!-- AREA GRAFIK DUA KOLOM: TREN PENDAPATAN & DISTRIBUSI LAYANAN -->
    <div class="px-8 pb-6 grid grid-cols-1 lg:grid-cols-3 gap-5">

        <!-- Kolom Kiri: Tren Pendapatan & Jumlah Transaksi (2 Cols) -->
        <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6">
            <div class="flex items-center justify-between mb-5">
                <div>
                    <h2 class="text-sm font-extrabold text-slate-900 tracking-tight">Tren Pendapatan &amp; Pesanan AC (2026)</h2>
                    <p class="text-[11px] text-slate-400 mt-0.5">Statistik pertumbuhan omzet servis dan frekuensi pemesanan per bulan.</p>
                </div>
                <div class="flex items-center gap-4">
                    <div class="flex items-center gap-1.5 text-xs font-semibold text-slate-600">
                        <span class="w-3 h-3 rounded-md bg-[#0284C7] block"></span>
                        Pendapatan (Juta)
                    </div>
                    <div class="flex items-center gap-1.5 text-xs font-semibold text-slate-600">
                        <span class="w-3 h-3 rounded-full bg-amber-400 block"></span>
                        Jumlah Transaksi
                    </div>
                </div>
            </div>

            <div class="relative h-64">
                <canvas id="trendChart"></canvas>
            </div>
        </div>

        <!-- Kolom Kanan: Distribusi Kategori Layanan AC (1 Col) -->
        <div class="bg-white rounded-2xl border border-slate-200/80 shadow-sm p-6 flex flex-col justify-between">
            <div>
                <div class="flex items-center justify-between mb-2">
                    <h2 class="text-sm font-extrabold text-slate-900 tracking-tight">Distribusi Layanan</h2>
                    <span class="text-[10px] font-bold text-slate-400">Total 631 Order</span>
                </div>
                <p class="text-[11px] text-slate-400 mb-4">Porsi pesanan terbanyak berdasarkan jenis servis AC.</p>

                <div class="relative h-44 flex items-center justify-center">
                    <canvas id="donutChart"></canvas>
                    <div class="absolute text-center pointer-events-none">
                        <p class="text-2xl font-black text-slate-900 leading-none">631</p>
                        <p class="text-[10px] font-bold text-slate-400 mt-1 uppercase">Order</p>
                    </div>
                </div>
            </div>

            <!-- List Legend Persentase -->
            <div class="space-y-2 mt-4 pt-3 border-t border-slate-100">
                @foreach(array_slice($distribusiLayanan, 0, 5) as $d)
                <div class="flex items-center justify-between text-xs">
                    <div class="flex items-center gap-2">
                        <span class="w-2.5 h-2.5 rounded-full" style="background: {{ $d['warna'] }}"></span>
                        <span class="text-slate-600 font-medium">{{ $d['nama'] }}</span>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="text-slate-400 text-[10px]">{{ $d['jumlah'] }}x</span>
                        <span class="font-bold text-slate-800">{{ $d['persen'] }}%</span>
                    </div>
                </div>
                @endforeach
            </div>
        </div>

    </div>

    <!-- TABEL TRANSAKSI TERBARU -->
    <div class="px-8 pb-8">
        <div class="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">

            <!-- Table Header Bar -->
            <div class="px-6 py-4 flex items-center justify-between border-b border-slate-100">
                <div>
                    <h2 class="text-sm font-extrabold text-slate-900 tracking-tight">Transaksi Terbaru</h2>
                    <p class="text-[11px] text-slate-400 mt-0.5">Daftar transaksi pesanan servis AC pelanggan terkini.</p>
                </div>

                <!-- Status Filter Pills -->
                <div class="flex items-center gap-2">
                    <div class="flex bg-slate-100 p-1 rounded-xl text-xs font-semibold text-slate-600 gap-0.5">
                        @foreach(['Semua', 'Selesai', 'Berlangsung', 'Dibatalkan'] as $st)
                        <button @click="filterStatus = '{{ $st }}'"
                                :class="filterStatus === '{{ $st }}' ? 'bg-white text-slate-900 shadow-sm font-bold' : 'text-slate-500 hover:text-slate-800'"
                                class="px-3 py-1 rounded-lg transition-all">
                            {{ $st }}
                        </button>
                        @endforeach
                    </div>
                </div>
            </div>

            <!-- Table Content -->
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-[#EBF2FC] text-[11px] font-bold text-slate-600">
                            <th class="py-3 px-5">ID Transaksi</th>
                            <th class="py-3 px-4">Tanggal</th>
                            <th class="py-3 px-4">Pelanggan</th>
                            <th class="py-3 px-4">Layanan AC</th>
                            <th class="py-3 px-4">Teknisi</th>
                            <th class="py-3 px-4 text-right">Biaya</th>
                            <th class="py-3 px-5 text-center">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 text-xs">
                        @foreach($transaksi as $trx)
                        @php
                            $badgeStyle = match($trx['status']) {
                                'Selesai'     => 'bg-[#4ADE80] text-white',
                                'Berlangsung' => 'bg-[#FBBF24] text-white',
                                'Dibatalkan'  => 'bg-[#F87171] text-white',
                                default       => 'bg-slate-200 text-slate-700',
                            };
                        @endphp
                        <tr class="hover:bg-slate-50 transition-colors"
                            x-show="filterStatus === 'Semua' || filterStatus === '{{ $trx['status'] }}'">
                            <td class="py-3.5 px-5 font-mono font-bold text-[#0284C7]">{{ $trx['id'] }}</td>
                            <td class="py-3.5 px-4 text-slate-500">{{ $trx['tanggal'] }}</td>
                            <td class="py-3.5 px-4 font-bold text-slate-800">{{ $trx['pelanggan'] }}</td>
                            <td class="py-3.5 px-4 text-slate-700 font-medium">{{ $trx['layanan'] }}</td>
                            <td class="py-3.5 px-4 text-slate-600 flex items-center gap-1.5">
                                <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                                {{ $trx['teknisi'] }}
                            </td>
                            <td class="py-3.5 px-4 text-right font-extrabold text-slate-900">
                                Rp {{ number_format($trx['harga'], 0, ',', '.') }}
                            </td>
                            <td class="py-3.5 px-5 text-center">
                                <span class="inline-block px-3 py-1 rounded-full text-[10px] font-semibold {{ $badgeStyle }}">
                                    {{ $trx['status'] }}
                                </span>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <!-- Footer Pagination Summary -->
            <div class="px-6 py-3.5 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500 font-medium">
                <span>Menampilkan 8 transaksi terbaru dari total 631 transaksi</span>
                <a href="{{ route('admin.transaksi') }}" class="text-[#0284C7] font-bold hover:underline flex items-center gap-1.5">
                    <span>Lihat Seluruh Transaksi &amp; Bukti Pengerjaan Lengkap</span>
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                    </svg>
                </a>
            </div>

        </div>
    </div>

    <!-- ===================== MODAL EKSPOR LAPORAN ===================== -->
    <div x-show="showExportModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4"
         style="display: none;">
        <div @click.away="showExportModal = false"
             class="bg-white rounded-3xl max-w-md w-full overflow-hidden shadow-2xl border border-slate-200 p-6">
            
            <div class="w-12 h-12 bg-sky-100 text-[#0284C7] rounded-2xl flex items-center justify-center mx-auto mb-3">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                </svg>
            </div>

            <h3 class="text-base font-extrabold text-slate-900 text-center mb-1">Ekspor Laporan Kinerja &amp; Transaksi</h3>
            <p class="text-xs text-slate-500 text-center mb-5">Pilih format berkas laporan yang ingin Anda unduh atau cetak langsung:</p>

            <div class="space-y-3 mb-6">
                <!-- Opsi 1: Download CSV / Excel -->
                <button @click="downloadCSV()"
                        class="w-full p-4 rounded-2xl border border-slate-200 hover:border-emerald-500 hover:bg-emerald-50/50 transition-all text-left flex items-center gap-3.5 group">
                    <div class="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold text-sm flex-shrink-0 group-hover:scale-110 transition-transform">
                        XLS
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-xs font-bold text-slate-900 group-hover:text-emerald-800">Download Format Excel (CSV)</p>
                        <p class="text-[11px] text-slate-400">Data mentah transaksi lengkap untuk analisis spreadsheet</p>
                    </div>
                    <svg class="w-4 h-4 text-slate-400 group-hover:text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                    </svg>
                </button>

                <!-- Opsi 2: Cetak / Print PDF -->
                <button @click="printReport()"
                        class="w-full p-4 rounded-2xl border border-slate-200 hover:border-sky-500 hover:bg-sky-50/50 transition-all text-left flex items-center gap-3.5 group">
                    <div class="w-10 h-10 rounded-xl bg-sky-100 text-[#0284C7] flex items-center justify-center font-bold text-sm flex-shrink-0 group-hover:scale-110 transition-transform">
                        PDF
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-xs font-bold text-slate-900 group-hover:text-sky-800">Cetak Dokumen Resmi (PDF)</p>
                        <p class="text-[11px] text-slate-400">Tampilan cetak rapi dengan ringkasan eksekutif &amp; tanda tangan</p>
                    </div>
                    <svg class="w-4 h-4 text-slate-400 group-hover:text-sky-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                    </svg>
                </button>
            </div>

            <div class="flex justify-end">
                <button @click="showExportModal = false"
                        class="w-full py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs rounded-xl transition-all">
                    Batal
                </button>
            </div>

        </div>
    </div>

</div>

<!-- Chart.js CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function () {

    // 1. Chart Tren Pendapatan & Transaksi
    const trendCtx = document.getElementById('trendChart').getContext('2d');
    const skyGrad = trendCtx.createLinearGradient(0, 0, 0, 240);
    skyGrad.addColorStop(0, 'rgba(2, 132, 199, 0.25)');
    skyGrad.addColorStop(1, 'rgba(2, 132, 199, 0.00)');

    new Chart(trendCtx, {
        type: 'bar',
        data: {
            labels: {!! json_encode($chartLabels) !!},
            datasets: [
                {
                    label: 'Pendapatan (Juta Rp)',
                    data: {!! json_encode($chartPendapatan) !!},
                    backgroundColor: skyGrad,
                    borderColor: '#0284C7',
                    borderWidth: 2,
                    borderRadius: 8,
                    yAxisID: 'y',
                    order: 2,
                },
                {
                    label: 'Jumlah Transaksi',
                    data: {!! json_encode($chartTransaksi) !!},
                    borderColor: '#F59E0B',
                    backgroundColor: 'rgba(245, 158, 11, 0.1)',
                    borderWidth: 2.5,
                    pointBackgroundColor: '#FFFFFF',
                    pointBorderColor: '#F59E0B',
                    pointBorderWidth: 2.5,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    tension: 0.35,
                    fill: false,
                    type: 'line',
                    yAxisID: 'y1',
                    order: 1,
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { intersect: false, mode: 'index' },
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#0F172A',
                    padding: 10,
                    cornerRadius: 10,
                    titleFont: { size: 12, weight: 'bold' },
                    bodyFont: { size: 11 },
                    callbacks: {
                        label: function(ctx) {
                            if (ctx.datasetIndex === 0 && ctx.parsed.y !== null) {
                                return ' 💰 Pendapatan: Rp ' + ctx.parsed.y + ' Jt';
                            }
                            if (ctx.datasetIndex === 1 && ctx.parsed.y !== null) {
                                return ' 📦 Transaksi: ' + ctx.parsed.y + ' pesanan';
                            }
                            return null;
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: { display: false },
                    ticks: { font: { size: 10, weight: '600' }, color: '#64748B' }
                },
                y: {
                    position: 'left',
                    grid: { color: '#F1F5F9' },
                    ticks: {
                        font: { size: 10 },
                        color: '#64748B',
                        callback: v => v !== null ? 'Rp ' + v + 'Jt' : ''
                    }
                },
                y1: {
                    position: 'right',
                    grid: { display: false },
                    ticks: { font: { size: 10 }, color: '#D97706' }
                }
            }
        }
    });

    // 2. Chart Donut Distribusi Layanan
    const donutCtx = document.getElementById('donutChart').getContext('2d');
    new Chart(donutCtx, {
        type: 'doughnut',
        data: {
            labels: {!! json_encode(array_column($distribusiLayanan, 'nama')) !!},
            datasets: [{
                data: {!! json_encode(array_column($distribusiLayanan, 'persen')) !!},
                backgroundColor: {!! json_encode(array_column($distribusiLayanan, 'warna')) !!},
                borderWidth: 2,
                borderColor: '#ffffff',
                hoverOffset: 6,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '72%',
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#0F172A',
                    padding: 8,
                    cornerRadius: 8,
                    callbacks: {
                        label: ctx => ' ' + ctx.label + ': ' + ctx.parsed + '%'
                    }
                }
            }
        }
    });

});
</script>

@endsection
