<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Kelola Pengguna - ACare Admin Portal')</title>

    <!-- Google Fonts: Plus Jakarta Sans -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">

    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
                    },
                    colors: {
                        brand: {
                            50: '#f0f9ff',
                            100: '#e0f2fe',
                            200: '#bae6fd',
                            500: '#0ea5e9',
                            600: '#0284c7',
                            700: '#0369a1',
                            800: '#075985',
                            900: '#0c4a6e',
                        }
                    }
                }
            }
        }
    </script>

    <!-- Alpine.js untuk interaktivitas -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>

    <style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
        }
        /* Custom scrollbar */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: #f1f5f9;
        }
        ::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 4px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: #94a3b8;
        }
    </style>
</head>
<body class="bg-[#F8FAFC] text-slate-800 antialiased flex h-screen overflow-hidden"
      x-data="{
          showLogoutModal: false,
          globalSearch: '',
          lakukanPencarian() {
              if (this.globalSearch.trim() === '') return;
              let q = encodeURIComponent(this.globalSearch.trim());
              window.location.href = '{{ route('admin.transaksi') }}?q=' + q;
          }
      }">

    <!-- 1. ASIDE - SIDEBAR SESUAI FIGMA RESMI -->
    <aside class="w-64 bg-white border-r border-slate-200 flex flex-col justify-between flex-shrink-0 z-20">
        <div>
            <!-- Header Brand Logo ACare Sesuai Gambar Figma -->
            <div class="px-6 py-5 border-b border-slate-100">
                <a href="{{ route('admin.dashboard') }}" class="block">
                    <img src="{{ asset('images/acare-logo.png') }}" 
                         alt="ACare ADMIN PORTAL" 
                         class="w-full max-w-[215px] h-auto object-contain">
                </a>
            </div>

            <!-- Menu Navigasi Sidebar (Beranda, Kelola Transaksi, Kelola Pengguna, Kelola Layanan) -->
            <nav class="p-4 space-y-1">
                @php
                    $currentRoute = request()->route() ? request()->route()->getName() : '';
                    $segment1 = request()->segment(1);
                    $segment2 = request()->segment(2);
                    $isBeranda = in_array($currentRoute, ['admin.dashboard', 'admin.dashboard.alias', 'admin.dashboard.main', 'admin.beranda']) || ($segment1 == '' || $segment2 == 'dashboard' || $segment2 == 'beranda');
                    $isTransaksi = $segment2 == 'transaksi' || str_contains($currentRoute, 'transaksi');
                    $isPengguna = $segment2 == 'pengguna' || str_contains($currentRoute, 'pengguna');
                    $isLayanan = $segment2 == 'layanan' || str_contains($currentRoute, 'layanan');
                @endphp

                <!-- 1. Beranda (Dashboard: Statistik, Pendapatan, Transaksi) -->
                <a href="{{ route('admin.dashboard') }}"
                   class="flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs transition-all {{ $isBeranda ? 'bg-sky-50 text-[#0284C7] font-bold' : 'text-slate-600 hover:bg-slate-50 font-semibold' }}">
                    <div class="flex items-center gap-3">
                        <svg class="w-4 h-4 {{ $isBeranda ? 'text-[#0284C7]' : 'text-slate-500' }}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                        </svg>
                        <span>Beranda</span>
                    </div>
                </a>

                <!-- 2. Kelola Transaksi (Monitoring Pesanan & Bukti Pengerjaan) -->
                <a href="{{ route('admin.transaksi') }}"
                   class="flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs transition-all {{ $isTransaksi ? 'bg-sky-50 text-[#0284C7] font-bold' : 'text-slate-600 hover:bg-slate-50 font-semibold' }}">
                    <div class="flex items-center gap-3">
                        <svg class="w-4 h-4 {{ $isTransaksi ? 'text-[#0284C7]' : 'text-slate-500' }}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                        </svg>
                        <span>Kelola Transaksi</span>
                    </div>
                    <span class="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">8</span>
                </a>

                <!-- 3. Kelola Pengguna (Dina: Pengguna & Verifikasi Teknisi dengan Badge 3) -->
                <a href="{{ route('admin.pengguna') }}"
                   class="flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs transition-all {{ $isPengguna ? 'bg-sky-50 text-[#0284C7] font-bold' : 'text-slate-600 hover:bg-slate-50 font-semibold' }}">
                    <div class="flex items-center gap-3">
                        <svg class="w-4 h-4 {{ $isPengguna ? 'text-[#0284C7]' : 'text-slate-500' }}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                        <span>Kelola Pengguna</span>
                    </div>
                    <!-- Badge 3 (Notifikasi 3 Teknisi Menunggu Verifikasi sesuai Figma) -->
                    <span class="px-2 py-0.5 rounded-full {{ $isPengguna ? 'bg-sky-100 text-[#0284C7]' : 'bg-amber-100 text-amber-700' }} text-[10px] font-bold">3</span>
                </a>

                <!-- 4. Kelola Layanan (Achmal: 6 Katalog Layanan Resmi ACare) -->
                <a href="{{ route('admin.layanan') }}"
                   class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs transition-all {{ $isLayanan ? 'bg-sky-50 text-[#0284C7] font-bold' : 'text-slate-600 hover:bg-slate-50 font-semibold' }}">
                    <svg class="w-4 h-4 {{ $isLayanan ? 'text-[#0284C7]' : 'text-slate-500' }}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                    <span>Kelola Layanan</span>
                </a>
            </nav>
        </div>

        <!-- Profil Admin Operasional di Bawah Sidebar (Sesuai Figma) -->
        <div class="p-4 border-t border-slate-100">
            <div class="flex items-center gap-3 p-1">
                <div class="w-9 h-9 rounded-xl bg-[#E0F2FE] text-[#0284C7] font-black italic flex items-center justify-center text-xs flex-shrink-0">
                    AO
                </div>
                <div class="flex-1 min-w-0">
                    <p class="text-xs font-bold text-slate-800 truncate">Admin Operasional</p>
                    <p class="text-[11px] text-slate-400 truncate">admin@acare.id</p>
                </div>
            </div>
            <!-- Tombol Keluar Portal dengan Modal Konfirmasi -->
            <button @click="showLogoutModal = true"
                    type="button"
                    class="mt-3 w-full flex items-center justify-center gap-2 py-2 px-3 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-600 hover:bg-rose-50 hover:text-rose-600 hover:border-rose-200 transition-all shadow-sm">
                <svg class="w-3.5 h-3.5 text-slate-400 group-hover:text-rose-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
                <span>Keluar Portal</span>
            </button>
        </div>
    </aside>

    <!-- 2. AREA KONTEN UTAMA DENGAN TOP BAR (SEARCH BAR SAJA SESUAI FIGMA) -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
        <!-- Top Search Bar Header -->
        <header class="h-16 bg-white border-b border-slate-200 px-8 flex items-center justify-between flex-shrink-0 z-10">
            <div class="w-full max-w-xl">
                <form @submit.prevent="lakukanPencarian()" class="relative">
                    <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                    </span>
                    <input type="text"
                           x-model="globalSearch"
                           placeholder="Cari transaksi, pelanggan, teknisi, atau ketik kata kunci lalu tekan Enter..."
                           class="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-2xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7] focus:bg-white transition-all shadow-sm">
                </form>
            </div>

            <!-- Status Indikator Sistem Online -->
            <div class="flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
                <span class="text-[11px] font-bold text-slate-600">Sistem Online (Port 8000)</span>
            </div>
        </header>

        <!-- Body Main Content -->
        <main class="flex-1 overflow-y-auto">
            @yield('content')
        </main>
    </div>

    <!-- ===================== MODAL KONFIRMASI LOGOUT ===================== -->
    <div x-show="showLogoutModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4"
         style="display: none;">
        <div @click.away="showLogoutModal = false"
             class="bg-white rounded-3xl max-w-sm w-full overflow-hidden shadow-2xl border border-slate-200 p-6 text-center">
            
            <div class="w-14 h-14 bg-rose-100 text-rose-600 rounded-full flex items-center justify-center mx-auto mb-3">
                <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                </svg>
            </div>

            <h3 class="text-base font-extrabold text-slate-900 mb-1">Keluar dari Portal Admin?</h3>
            <p class="text-xs text-slate-500 mb-5 leading-relaxed">
                Sesi login Admin Operasional Anda akan diakhiri. Anda perlu memasukkan email &amp; kata sandi kembali untuk masuk.
            </p>

            <div class="flex items-center gap-2.5">
                <button type="button"
                        @click="showLogoutModal = false"
                        class="flex-1 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                    Batal
                </button>
                <form action="{{ route('admin.logout') }}" method="POST" class="flex-1">
                    @csrf
                    <button type="submit"
                            class="w-full py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold shadow-md shadow-rose-500/20 transition-colors">
                        Ya, Keluar
                    </button>
                </form>
            </div>

        </div>
    </div>

</body>
</html>
