<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'ACare Admin Portal')</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">

    @include('layouts.partials.tema')

    <!-- Alpine.js untuk interaktivitas -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <script>
        // Kirim perubahan ke server (JSON + CSRF). Mengembalikan { ok, data }.
        window.kirimAdmin = function (url, body) {
            var token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
            return fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-TOKEN': token },
                body: JSON.stringify(body)
            }).then(function (res) {
                return res.json().catch(function () { return {}; }).then(function (data) {
                    return { ok: res.ok, data: data };
                });
            }).catch(function () {
                return { ok: false, data: { pesan: 'Tidak dapat terhubung ke server. Coba lagi.' } };
            });
        };

        // Toast global. opsi: { tipe: 'success'|'warning'|'error', batal: function }
        window.adminToast = function (pesan, opsi) {
            window.dispatchEvent(new CustomEvent('admin-toast', { detail: { pesan: pesan, opsi: opsi || {} } }));
        };

        // Menyegarkan lencana sidebar setelah perubahan status
        window.setLencana = function (kunci, jumlah) {
            document.querySelectorAll('[data-lencana="' + kunci + '"]').forEach(function (el) {
                el.textContent = jumlah;
                el.style.display = jumlah > 0 ? '' : 'none';
            });
        };

        function toastAdmin() {
            return {
                tampil: false, pesan: '', tipe: 'success', adaBatal: false, timer: null,
                buka: function (e) {
                    var self = this;
                    this.pesan = e.detail.pesan;
                    this.tipe = e.detail.opsi.tipe || 'success';
                    this.fnBatal = e.detail.opsi.batal || null; this.adaBatal = !!this.fnBatal;
                    this.tampil = true;
                    clearTimeout(this.timer);
                    this.timer = setTimeout(function () { self.tampil = false; self.fnBatal = null; self.adaBatal = false; }, this.adaBatal ? 8000 : 4000);
                },
                batalkan: function () {
                    var fn = this.fnBatal;
                    this.tampil = false;
                    this.fnBatal = null; this.adaBatal = false;
                    if (fn) { fn(); }
                }
            };
        }

        function pencarianGlobal(indeks, bisaBukaDetail) {
            return {
                terbuka: false, q: '', aktif: 0, indeks: indeks,
                buka: function () {
                    this.terbuka = true; this.q = ''; this.aktif = 0;
                    var self = this;
                    this.$nextTick(function () { self.$refs.kotak.focus(); });
                },
                tutup: function () { this.terbuka = false; },
                tekanGaris: function (e) {
                    var el = document.activeElement;
                    var mengetik = el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT' || el.isContentEditable);
                    if (!mengetik && !this.terbuka) { e.preventDefault(); this.buka(); }
                },
                get hasil() {
                    var q = this.q.trim().toLowerCase();
                    if (q.length < 2) { return []; }
                    var cacah = {};
                    return this.indeks.filter(function (r) {
                        if (!(r.judul + ' ' + r.info).toLowerCase().includes(q)) { return false; }
                        cacah[r.jenis] = (cacah[r.jenis] || 0) + 1;
                        return cacah[r.jenis] <= 5;
                    });
                },
                gerak: function (arah) {
                    var n = this.hasil.length;
                    if (n === 0) { return; }
                    this.aktif = (this.aktif + arah + n) % n;
                },
                pilih: function (r) {
                    if (!r) { return; }
                    this.tutup();
                    var peta = {
                        Transaksi: '{{ route('admin.transaksi') }}?detail=',
                        Pengguna: '{{ route('admin.pengguna') }}?q=',
                        Pengaduan: '{{ route('admin.pengaduan') }}?q='
                    };
                    if (r.jenis === 'Transaksi' && bisaBukaDetail) {
                        window.dispatchEvent(new CustomEvent('buka-detail-transaksi', { detail: { id: r.id } }));
                        return;
                    }
                    window.location.href = peta[r.jenis] + encodeURIComponent(r.id);
                }
            };
        }
    </script>
</head>
<body class="bg-surface text-slate-800 antialiased flex h-screen overflow-hidden"
      x-data="{ showLogoutModal: false }"
      @keydown.escape.window="showLogoutModal = false">

    @php
        $currentRoute = request()->route() ? request()->route()->getName() : '';
        $segment2 = request()->segment(2);
        $isTransaksi = $segment2 == 'transaksi' || str_contains($currentRoute, 'transaksi');
        $isPengaduan = $segment2 == 'pengaduan';
        $isBeranda = $isTransaksi || $currentRoute === 'admin.dashboard';
        $isPengguna = $segment2 == 'pengguna' || str_contains($currentRoute, 'pengguna');
        $isLayanan = $segment2 == 'layanan' || str_contains($currentRoute, 'layanan');

        $bisaBukaDetail = in_array($currentRoute, ['admin.dashboard', 'admin.transaksi', 'admin.pengaduan'], true);

        $menu = [
            ['rute' => 'admin.dashboard', 'label' => 'Beranda', 'ikon' => 'lucide:layout-dashboard', 'aktif' => $isBeranda, 'lencana' => 0],
            ['rute' => 'admin.pengguna', 'label' => 'Kelola Pengguna', 'ikon' => 'lucide:users', 'aktif' => $isPengguna, 'lencana' => $jumlahTeknisiMenunggu, 'kunci' => 'pengguna', 'keterangan' => 'teknisi menunggu verifikasi'],
            ['rute' => 'admin.pengaduan', 'label' => 'Pengaduan', 'ikon' => 'lucide:message-square-warning', 'aktif' => $isPengaduan, 'lencana' => $jumlahPengaduanBaru, 'kunci' => 'pengaduan', 'keterangan' => 'pengaduan baru'],
            ['rute' => 'admin.layanan', 'label' => 'Kelola Layanan', 'ikon' => 'lucide:clipboard-list', 'aktif' => $isLayanan, 'lencana' => 0],
        ];
    @endphp

    <!-- SIDEBAR -->
    <aside class="w-64 flex flex-col justify-between flex-shrink-0 z-20 text-white"
           style="background: linear-gradient(180deg, #0A2350 0%, #0A2350 60%, #123766 100%);">
        <div>
            <!-- Logo -->
            <div class="px-6 pt-6 pb-5">
                <a href="{{ route('admin.dashboard') }}" class="block" aria-label="ACare Admin Portal, ke Beranda">
                    <img src="{{ asset('images/logo-acare-putih.png') }}" alt="ACare" class="w-32 h-auto">
                </a>
                <p class="mt-2 text-sm font-semibold text-white/70">Admin Portal</p>
            </div>

            <!-- Pencarian global -->
            <div class="px-3 mb-3">
                <button type="button" @click="$dispatch('buka-pencarian')"
                        class="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg border border-white/15 text-sm text-white/75 hover:bg-white/5 hover:text-white transition-colors">
                    <iconify-icon icon="lucide:search" width="16" height="16" aria-hidden="true"></iconify-icon>
                    <span class="flex-1 text-left">Cari...</span>
                    <kbd class="px-1.5 py-0.5 rounded border border-white/25 text-xs font-semibold text-white/70">/</kbd>
                </button>
            </div>

            <!-- Menu: Beranda, Kelola Pengguna, Pengaduan, Kelola Layanan. Transaksi dibuka dari Beranda atau pencarian. -->
            <nav class="px-3 space-y-1" aria-label="Menu utama">
                @foreach($menu as $item)
                    <a href="{{ route($item['rute']) }}"
                       @if($item['aktif']) aria-current="page" @endif
                       class="relative flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors {{ $item['aktif'] ? 'bg-white/10 text-white font-semibold' : 'text-white/75 hover:bg-white/5 hover:text-white font-medium' }}">
                        @if($item['aktif'])
                            <span class="absolute left-0 top-2 bottom-2 w-1 rounded-r bg-brand-light" aria-hidden="true"></span>
                        @endif
                        <span class="flex items-center gap-3">
                            <iconify-icon icon="{{ $item['ikon'] }}" width="18" height="18" aria-hidden="true"></iconify-icon>
                            <span>{{ $item['label'] }}</span>
                        </span>
                        @if(isset($item['kunci']))
                            <span data-lencana="{{ $item['kunci'] }}"
                                  @if($item['lencana'] < 1) style="display: none;" @endif
                                  class="px-2 py-0.5 rounded-full bg-amber-400 text-navy text-xs font-bold"
                                  title="{{ $item['keterangan'] }}">{{ $item['lencana'] }}</span>
                        @endif
                    </a>
                @endforeach
            </nav>
        </div>

        <!-- Profil admin & keluar -->
        <div class="p-4 border-t border-white/10">
            <div class="flex items-center gap-3 p-1">
                <div class="w-9 h-9 rounded-full bg-white/10 text-white font-semibold flex items-center justify-center text-xs flex-shrink-0">
                    AO
                </div>
                <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-white truncate">Admin Operasional</p>
                    <p class="text-xs text-white/65 truncate">admin@acare.id</p>
                </div>
            </div>
            <button @click="showLogoutModal = true"
                    type="button"
                    class="mt-3 w-full flex items-center justify-center gap-2 py-2 px-3 border border-white/20 rounded-lg text-sm font-medium text-white/85 hover:bg-white/10 hover:text-white transition-colors">
                <iconify-icon icon="lucide:log-out" width="16" height="16" aria-hidden="true"></iconify-icon>
                <span>Keluar Portal</span>
            </button>
        </div>
    </aside>

    <!-- AREA KONTEN -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
        <main class="flex-1 overflow-y-auto">
            @yield('content')
        </main>
    </div>

    <!-- MODAL KONFIRMASI KELUAR -->
    <div x-show="showLogoutModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4"
         role="dialog" aria-modal="true" aria-labelledby="judul-keluar"
         style="display: none;">
        <div @click.away="showLogoutModal = false"
             class="bg-white rounded-xl max-w-sm w-full overflow-hidden shadow-lg border border-line p-6 text-center">

            <div class="w-12 h-12 bg-rose-50 text-rose-600 rounded-full flex items-center justify-center mx-auto mb-3">
                <iconify-icon icon="lucide:log-out" width="22" height="22" aria-hidden="true"></iconify-icon>
            </div>

            <h3 id="judul-keluar" class="text-base font-bold text-navy mb-1">Keluar dari Portal Admin?</h3>
            <p class="text-sm text-slate-600 mb-5 leading-relaxed">
                Sesi login Anda akan diakhiri. Anda perlu memasukkan email &amp; kata sandi kembali untuk masuk.
            </p>

            <div class="flex items-center gap-2.5">
                <button type="button"
                        @click="showLogoutModal = false"
                        class="flex-1 py-2.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm font-semibold transition-colors">
                    Batal
                </button>
                <form action="{{ route('admin.logout') }}" method="POST" class="flex-1">
                    @csrf
                    <button type="submit"
                            class="w-full py-2.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-sm font-semibold transition-colors">
                        Ya, Keluar
                    </button>
                </form>
            </div>

        </div>
    </div>

    <!-- Toast global (mendukung Batalkan) -->
    <div x-data="toastAdmin()" @admin-toast.window="buka($event)">
        <div x-show="tampil" x-transition.opacity role="status" aria-live="polite"
             class="fixed bottom-6 right-6 z-[90] max-w-md flex items-center gap-4 pl-5 pr-3 py-3 rounded-lg border border-slate-700 bg-slate-900 text-white text-sm font-medium"
             style="display: none;">
            <iconify-icon :icon="tipe === 'error' ? 'lucide:circle-alert' : (tipe === 'warning' ? 'lucide:triangle-alert' : 'lucide:circle-check')"
                          width="18" height="18" aria-hidden="true"
                          :class="tipe === 'error' ? 'text-rose-400' : (tipe === 'warning' ? 'text-amber-400' : 'text-emerald-400')"></iconify-icon>
            <span x-text="pesan" class="flex-1"></span>
            <button type="button" x-show="adaBatal" @click="batalkan()"
                    class="px-3 py-1.5 rounded-lg text-sm font-bold text-brand-light hover:bg-white/10 transition-colors">Batalkan</button>
        </div>
    </div>

    <!-- Pencarian global: tekan / untuk membuka. Hanya membaca, tidak mengubah data atau halaman di belakangnya. -->
    <div x-data="pencarianGlobal(@js($indeksCari), @js($bisaBukaDetail))"
         @buka-pencarian.window="buka()"
         @keydown.window.slash="tekanGaris($event)"
         @keydown.escape.window="tutup()">
        <div x-show="terbuka" x-transition.opacity
             class="fixed inset-0 z-[95] flex items-start justify-center bg-navy/60 p-4 pt-[14vh]"
             role="dialog" aria-modal="true" aria-label="Pencarian"
             style="display: none;">
            <div @click.away="tutup()" class="w-full max-w-xl bg-white rounded-xl border border-line overflow-hidden">
                <div class="flex items-center gap-3 px-4 border-b border-line">
                    <iconify-icon icon="lucide:search" width="18" height="18" class="text-slate-500" aria-hidden="true"></iconify-icon>
                    <input x-ref="kotak" x-model="q" type="text" autocomplete="off"
                           @keydown.arrow-down.prevent="gerak(1)" @keydown.arrow-up.prevent="gerak(-1)"
                           @keydown.enter.prevent="pilih(hasil[aktif])"
                           placeholder="Cari ID transaksi, nama pengguna, atau ID pengaduan"
                           aria-label="Kata kunci pencarian"
                           class="flex-1 py-3.5 text-sm text-slate-800 placeholder-slate-500 focus:outline-none bg-transparent">
                    <kbd class="px-1.5 py-0.5 rounded border border-line text-xs font-semibold text-slate-500">Esc</kbd>
                </div>
                <ul class="max-h-80 overflow-y-auto py-1" role="listbox">
                    <template x-for="(r, i) in hasil" :key="r.jenis + r.id">
                        <li role="option" :aria-selected="i === aktif">
                            <button type="button" @click="pilih(r)" @mousemove="aktif = i"
                                    :class="i === aktif ? 'bg-brand-50' : ''"
                                    class="w-full flex items-center justify-between gap-3 px-4 py-2.5 text-left">
                                <span class="min-w-0">
                                    <span class="block text-sm font-semibold text-navy truncate" x-text="r.judul"></span>
                                    <span class="block text-xs text-slate-500 truncate" x-text="r.info"></span>
                                </span>
                                <span class="flex-shrink-0 text-xs font-semibold text-slate-500" x-text="r.jenis"></span>
                            </button>
                        </li>
                    </template>
                    <li x-show="q.trim().length >= 2 && hasil.length === 0" class="px-4 py-6 text-center text-sm text-slate-500">Tidak ada hasil untuk &quot;<span x-text="q"></span>&quot;.</li>
                    <li x-show="q.trim().length < 2" class="px-4 py-6 text-center text-sm text-slate-500">Ketik minimal 2 huruf. Hasil dibatasi 5 per kelompok.</li>
                </ul>
            </div>
        </div>
    </div>

</body>
</html>
