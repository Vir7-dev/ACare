@extends('layouts.admin')

@section('title', 'Statistik & Transaksi - ACare Admin Portal')

@section('content')

{{-- Extra styles for this page --}}
<style>
    [x-cloak] { display: none !important; }

    .glass-card {
        background: rgba(255,255,255,0.85);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
    }

    .stat-gradient-1 { background: linear-gradient(135deg, #0284C7 0%, #0ea5e9 100%); }
    .stat-gradient-2 { background: linear-gradient(135deg, #059669 0%, #10b981 100%); }
    .stat-gradient-3 { background: linear-gradient(135deg, #7c3aed 0%, #a78bfa 100%); }
    .stat-gradient-4 { background: linear-gradient(135deg, #d97706 0%, #fbbf24 100%); }

    .shimmer {
        background: linear-gradient(90deg, transparent, rgba(255,255,255,0.25), transparent);
        background-size: 200% 100%;
        animation: shimmer 2.5s infinite;
    }
    @keyframes shimmer {
        0% { background-position: -200% 0; }
        100% { background-position: 200% 0; }
    }

    .chart-wrapper canvas { display: block; }

    .badge-selesai     { background: #dcfce7; color: #15803d; }
    .badge-berlangsung { background: #fef3c7; color: #b45309; }
    .badge-dibatalkan  { background: #fee2e2; color: #dc2626; }

    @keyframes fadeUp {
        from { opacity: 0; transform: translateY(16px); }
        to   { opacity: 1; transform: translateY(0); }
    }
    .animate-fadeup { animation: fadeUp 0.4s ease both; }
    .delay-1 { animation-delay: .05s; }
    .delay-2 { animation-delay: .10s; }
    .delay-3 { animation-delay: .15s; }
    .delay-4 { animation-delay: .20s; }
</style>

<div class="min-h-full bg-gradient-to-br from-slate-50 via-sky-50/30 to-white"
     x-data="{
        filterPeriode: 'Bulan Ini',
        filterStatus: 'Semua',
        periode: ['Minggu Ini', 'Bulan Ini', '3 Bulan', '6 Bulan', 'Tahun Ini'],
     }">

    {{-- ===== TOP HERO BAND ===== --}}
    <div class="px-8 pt-7 pb-5">
        <div class="flex items-start justify-between">
            <div>
                <div class="flex items-center gap-2 mb-1">
                    <span class="w-1 h-5 bg-[#0284C7] rounded-full block"></span>
                    <h1 class="text-xl font-black text-slate-900 tracking-tight">Statistik & Transaksi</h1>
                </div>
                <p class="text-xs text-slate-500 pl-3">Pantau performa platform ACare secara real-time</p>
            </div>

            {{-- Period Pill Filter --}}
            <div class="flex items-center gap-2">
                <span class="text-xs text-slate-400 font-medium">Periode:</span>
                <div class="flex bg-white border border-slate-200 rounded-2xl p-1 shadow-sm gap-0.5">
                    <template x-for="p in periode" :key="p">
                        <button @click="filterPeriode = p"
                            :class="filterPeriode === p
                                ? 'bg-[#0284C7] text-white shadow-md'
                                : 'text-slate-500 hover:bg-slate-50 hover:text-slate-800'"
                            class="px-3 py-1.5 rounded-xl text-xs font-semibold transition-all duration-200"
                            x-text="p">
                        </button>
                    </template>
                </div>
                {{-- Export Button --}}
                <button class="flex items-center gap-1.5 px-4 py-2 bg-[#0284C7] text-white text-xs font-bold rounded-2xl shadow-lg shadow-sky-200 hover:bg-[#0369a1] hover:shadow-sky-300 transition-all duration-200">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                    </svg>
                    Ekspor
                </button>
            </div>
        </div>
    </div>

    {{-- ===== STATS CARDS ===== --}}
    <div class="px-8 pb-6 grid grid-cols-4 gap-4">

        {{-- Card 1: Total Transaksi --}}
        <div class="stat-gradient-1 rounded-3xl p-5 shadow-xl shadow-sky-200/60 animate-fadeup delay-1 relative overflow-hidden">
            <div class="shimmer absolute inset-0 rounded-3xl pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-4">
                    <div class="w-10 h-10 bg-white/20 rounded-2xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/20 text-white px-2.5 py-1 rounded-full">▲ +24</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Total Transaksi</p>
                <p class="text-white text-3xl font-black mt-1 tracking-tight">631</p>
                <p class="text-white/70 text-[11px] mt-1.5">bulan ini bertambah 24</p>
            </div>
        </div>

        {{-- Card 2: Pendapatan --}}
        <div class="stat-gradient-2 rounded-3xl p-5 shadow-xl shadow-emerald-200/60 animate-fadeup delay-2 relative overflow-hidden">
            <div class="shimmer absolute inset-0 rounded-3xl pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-4">
                    <div class="w-10 h-10 bg-white/20 rounded-2xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/20 text-white px-2.5 py-1 rounded-full">▲ +12%</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Pendapatan Bulan Ini</p>
                <p class="text-white text-3xl font-black mt-1 tracking-tight">18,4 Jt</p>
                <p class="text-white/70 text-[11px] mt-1.5">naik dari Rp 16,3 Jt</p>
            </div>
        </div>

        {{-- Card 3: Teknisi Aktif --}}
        <div class="stat-gradient-3 rounded-3xl p-5 shadow-xl shadow-violet-200/60 animate-fadeup delay-3 relative overflow-hidden">
            <div class="shimmer absolute inset-0 rounded-3xl pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-4">
                    <div class="w-10 h-10 bg-white/20 rounded-2xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/20 text-white px-2.5 py-1 rounded-full">3 pending</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Teknisi Aktif</p>
                <p class="text-white text-3xl font-black mt-1 tracking-tight">28</p>
                <p class="text-white/70 text-[11px] mt-1.5">3 menunggu verifikasi</p>
            </div>
        </div>

        {{-- Card 4: Pengguna --}}
        <div class="stat-gradient-4 rounded-3xl p-5 shadow-xl shadow-amber-200/60 animate-fadeup delay-4 relative overflow-hidden">
            <div class="shimmer absolute inset-0 rounded-3xl pointer-events-none"></div>
            <div class="relative z-10">
                <div class="flex items-start justify-between mb-4">
                    <div class="w-10 h-10 bg-white/20 rounded-2xl flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>
                        </svg>
                    </div>
                    <span class="text-[10px] font-bold bg-white/20 text-white px-2.5 py-1 rounded-full">▲ +87</span>
                </div>
                <p class="text-white/80 text-xs font-semibold">Pengguna Terdaftar</p>
                <p class="text-white text-3xl font-black mt-1 tracking-tight">1.240</p>
                <p class="text-white/70 text-[11px] mt-1.5">87 pengguna baru bulan ini</p>
            </div>
        </div>

    </div>

    {{-- ===== CHARTS ROW ===== --}}
    <div class="px-8 pb-6 grid grid-cols-3 gap-5">

        {{-- Main Chart --}}
        <div class="col-span-2 bg-white rounded-3xl border border-slate-100 shadow-sm p-6">
            <div class="flex items-center justify-between mb-5">
                <div>
                    <h2 class="text-sm font-black text-slate-900">Tren Pendapatan & Transaksi</h2>
                    <p class="text-[11px] text-slate-400 mt-0.5">Performa bulanan sepanjang tahun 2026</p>
                </div>
                <div class="flex items-center gap-4">
                    <div class="flex items-center gap-1.5 text-[11px] font-semibold text-slate-500">
                        <span class="w-8 h-2 rounded-full bg-gradient-to-r from-sky-400 to-sky-600 block"></span>
                        Pendapatan
                    </div>
                    <div class="flex items-center gap-1.5 text-[11px] font-semibold text-slate-500">
                        <span class="w-8 h-2 rounded-full bg-gradient-to-r from-amber-400 to-orange-500 block"></span>
                        Transaksi
                    </div>
                </div>
            </div>
            <div class="chart-wrapper h-56">
                <canvas id="trendChart"></canvas>
            </div>
        </div>

        {{-- Donut + Legend --}}
        <div class="bg-white rounded-3xl border border-slate-100 shadow-sm p-6">
            <div class="mb-4">
                <h2 class="text-sm font-black text-slate-900">Distribusi Layanan</h2>
                <p class="text-[11px] text-slate-400 mt-0.5">Berdasarkan jumlah pesanan</p>
            </div>
            <div class="chart-wrapper h-40 relative flex items-center justify-center mb-1">
                <canvas id="donutChart"></canvas>
                {{-- Center label --}}
                <div class="absolute text-center pointer-events-none">
                    <p class="text-2xl font-black text-slate-900">631</p>
                    <p class="text-[10px] text-slate-400 font-semibold">Total</p>
                </div>
            </div>
            <div class="space-y-2 mt-3">
                @foreach($distribusiLayanan as $d)
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2 min-w-0">
                        <span class="w-2.5 h-2.5 rounded-full flex-shrink-0" style="background:{{ $d['warna'] }}"></span>
                        <span class="text-[11px] text-slate-600 font-medium truncate">{{ $d['nama'] }}</span>
                    </div>
                    <div class="flex items-center gap-2 flex-shrink-0 ml-2">
                        <div class="w-16 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                            <div class="h-full rounded-full" style="width:{{ $d['persen'] }}%; background:{{ $d['warna'] }}"></div>
                        </div>
                        <span class="text-[11px] font-bold text-slate-700 w-8 text-right">{{ $d['persen'] }}%</span>
                    </div>
                </div>
                @endforeach
            </div>
        </div>

    </div>

    {{-- ===== TRANSAKSI TABLE ===== --}}
    <div class="px-8 pb-8">
        <div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">

            {{-- Table Header --}}
            <div class="px-6 py-4 flex items-center justify-between border-b border-slate-50">
                <div>
                    <h2 class="text-sm font-black text-slate-900">Transaksi Terbaru</h2>
                    <p class="text-[11px] text-slate-400 mt-0.5">8 transaksi terkini dari total 631</p>
                </div>
                <div class="flex items-center gap-2">
                    {{-- Status Filter Pills --}}
                    <div class="flex bg-slate-50 border border-slate-100 rounded-2xl p-1 gap-0.5">
                        @foreach(['Semua', 'Selesai', 'Berlangsung', 'Dibatalkan'] as $st)
                        <button @click="filterStatus = '{{ $st }}'"
                            :class="filterStatus === '{{ $st }}'
                                ? 'bg-white shadow text-slate-900 font-bold'
                                : 'text-slate-500 hover:text-slate-700'"
                            class="px-3 py-1 rounded-xl text-[11px] font-semibold transition-all">
                            {{ $st }}
                        </button>
                        @endforeach
                    </div>
                </div>
            </div>

            {{-- Table --}}
            <div class="overflow-x-auto">
                <table class="w-full">
                    <thead>
                        <tr class="bg-gradient-to-r from-[#EBF2FC] to-sky-50 text-[10px] font-black text-slate-500 uppercase tracking-widest">
                            <th class="px-6 py-3.5 text-left">ID Transaksi</th>
                            <th class="px-6 py-3.5 text-left">Tanggal</th>
                            <th class="px-6 py-3.5 text-left">Pelanggan</th>
                            <th class="px-6 py-3.5 text-left">Layanan</th>
                            <th class="px-6 py-3.5 text-left">Teknisi</th>
                            <th class="px-6 py-3.5 text-left">Harga</th>
                            <th class="px-6 py-3.5 text-left">Status</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-50">
                        @foreach($transaksi as $i => $trx)
                        @php
                            $badgeClass = match($trx['status']) {
                                'Selesai'     => 'badge-selesai',
                                'Berlangsung' => 'badge-berlangsung',
                                'Dibatalkan'  => 'badge-dibatalkan',
                                default       => 'bg-slate-100 text-slate-600',
                            };
                            $dot = match($trx['status']) {
                                'Selesai'     => 'bg-emerald-400',
                                'Berlangsung' => 'bg-amber-400',
                                'Dibatalkan'  => 'bg-red-400',
                                default       => 'bg-slate-400',
                            };
                            $initials = strtoupper(implode('', array_map(fn($w) => $w[0], array_slice(explode(' ', $trx['pelanggan']), 0, 2))));
                            $avatarColors = ['bg-sky-100 text-sky-700', 'bg-violet-100 text-violet-700', 'bg-emerald-100 text-emerald-700', 'bg-amber-100 text-amber-700', 'bg-rose-100 text-rose-700'];
                            $ac = $avatarColors[$i % count($avatarColors)];
                        @endphp
                        <tr class="hover:bg-sky-50/30 transition-colors duration-150 group"
                            x-show="filterStatus === 'Semua' || filterStatus === '{{ $trx['status'] }}'">
                            <td class="px-6 py-4">
                                <span class="text-xs font-black text-[#0284C7] font-mono tracking-wide">{{ $trx['id'] }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-1.5">
                                    <svg class="w-3 h-3 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                                    </svg>
                                    <span class="text-xs text-slate-600 font-medium">{{ $trx['tanggal'] }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-2.5">
                                    <div class="w-8 h-8 rounded-xl {{ $ac }} font-black text-[11px] flex items-center justify-center flex-shrink-0 shadow-sm">
                                        {{ $initials }}
                                    </div>
                                    <span class="text-xs font-semibold text-slate-800">{{ $trx['pelanggan'] }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-xs text-slate-700 font-medium">{{ $trx['layanan'] }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-1.5">
                                    <div class="w-1.5 h-1.5 rounded-full bg-emerald-400"></div>
                                    <span class="text-xs text-slate-600 font-medium">{{ $trx['teknisi'] }}</span>
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <span class="text-xs font-black text-slate-900">Rp {{ number_format($trx['harga'], 0, ',', '.') }}</span>
                            </td>
                            <td class="px-6 py-4">
                                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-bold {{ $badgeClass }}">
                                    <span class="w-1.5 h-1.5 rounded-full {{ $dot }} block"></span>
                                    {{ $trx['status'] }}
                                </span>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            {{-- Pagination --}}
            <div class="px-6 py-4 border-t border-slate-50 flex items-center justify-between">
                <span class="text-[11px] text-slate-400 font-medium">Menampilkan <span class="font-bold text-slate-700">8</span> dari <span class="font-bold text-slate-700">631</span> transaksi</span>
                <div class="flex items-center gap-1">
                    <button class="px-3 py-1.5 border border-slate-200 rounded-xl text-[11px] font-semibold text-slate-500 hover:bg-slate-50 transition-all">←</button>
                    <button class="px-3 py-1.5 bg-[#0284C7] text-white rounded-xl text-[11px] font-bold shadow-sm">1</button>
                    <button class="px-3 py-1.5 border border-slate-200 rounded-xl text-[11px] font-semibold text-slate-500 hover:bg-slate-50 transition-all">2</button>
                    <button class="px-3 py-1.5 border border-slate-200 rounded-xl text-[11px] font-semibold text-slate-500 hover:bg-slate-50 transition-all">3</button>
                    <span class="px-1 text-slate-400 text-xs">···</span>
                    <button class="px-3 py-1.5 border border-slate-200 rounded-xl text-[11px] font-semibold text-slate-500 hover:bg-slate-50 transition-all">79</button>
                    <button class="px-3 py-1.5 border border-slate-200 rounded-xl text-[11px] font-semibold text-slate-500 hover:bg-slate-50 transition-all">→</button>
                </div>
            </div>

        </div>
    </div>

</div>

{{-- ===== CHART.JS ===== --}}
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function () {

    /* ---- Trend Chart ---- */
    const trendCtx = document.getElementById('trendChart').getContext('2d');

    const skyGrad = trendCtx.createLinearGradient(0, 0, 0, 220);
    skyGrad.addColorStop(0,   'rgba(2,132,199,0.25)');
    skyGrad.addColorStop(1,   'rgba(2,132,199,0.00)');

    new Chart(trendCtx, {
        type: 'bar',
        data: {
            labels: {!! json_encode($chartLabels) !!},
            datasets: [
                {
                    label: 'Pendapatan (Jt)',
                    data: {!! json_encode($chartPendapatan) !!},
                    backgroundColor: skyGrad,
                    borderColor: '#0284C7',
                    borderWidth: 2,
                    borderRadius: 8,
                    borderSkipped: false,
                    type: 'bar',
                    yAxisID: 'y',
                    order: 2,
                },
                {
                    label: 'Transaksi',
                    data: {!! json_encode($chartTransaksi) !!},
                    borderColor: '#f59e0b',
                    backgroundColor: 'rgba(245,158,11,0.12)',
                    borderWidth: 2.5,
                    pointBackgroundColor: '#fff',
                    pointBorderColor: '#f59e0b',
                    pointBorderWidth: 2.5,
                    pointRadius: 4,
                    pointHoverRadius: 7,
                    tension: 0.4,
                    fill: true,
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
                    backgroundColor: '#0f172a',
                    titleFont: { size: 11, weight: 'bold', family: 'Plus Jakarta Sans' },
                    bodyFont:  { size: 11, family: 'Plus Jakarta Sans' },
                    padding: 12,
                    cornerRadius: 12,
                    callbacks: {
                        label: function(ctx) {
                            if (ctx.datasetIndex === 0 && ctx.parsed.y !== null)
                                return '  💰 Rp ' + ctx.parsed.y + ' Jt';
                            if (ctx.datasetIndex === 1 && ctx.parsed.y !== null)
                                return '  📦 ' + ctx.parsed.y + ' transaksi';
                            return null;
                        }
                    }
                }
            },
            scales: {
                x: {
                    grid: { display: false },
                    border: { display: false },
                    ticks: { font: { size: 10, weight: '700', family: 'Plus Jakarta Sans' }, color: '#94a3b8' }
                },
                y: {
                    position: 'left',
                    grid: { color: '#f1f5f9', drawBorder: false },
                    border: { display: false, dash: [4,4] },
                    ticks: {
                        font: { size: 10, family: 'Plus Jakarta Sans' }, color: '#94a3b8',
                        callback: v => v !== null ? 'Rp' + v + 'Jt' : ''
                    }
                },
                y1: {
                    position: 'right',
                    grid: { display: false },
                    border: { display: false },
                    ticks: { font: { size: 10, family: 'Plus Jakarta Sans' }, color: '#f59e0b' }
                }
            }
        }
    });

    /* ---- Donut Chart ---- */
    const donutCtx = document.getElementById('donutChart').getContext('2d');
    new Chart(donutCtx, {
        type: 'doughnut',
        data: {
            labels: {!! json_encode(array_column($distribusiLayanan, 'nama')) !!},
            datasets: [{
                data: {!! json_encode(array_column($distribusiLayanan, 'persen')) !!},
                backgroundColor: {!! json_encode(array_column($distribusiLayanan, 'warna')) !!},
                borderWidth: 3,
                borderColor: '#ffffff',
                hoverOffset: 8,
                hoverBorderColor: '#ffffff',
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '74%',
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#0f172a',
                    titleFont: { size: 11, weight: 'bold', family: 'Plus Jakarta Sans' },
                    bodyFont:  { size: 11, family: 'Plus Jakarta Sans' },
                    padding: 12,
                    cornerRadius: 12,
                    callbacks: {
                        label: ctx => '  ' + ctx.label + ': ' + ctx.parsed + '%'
                    }
                }
            }
        }
    });
});
</script>
@endsection
