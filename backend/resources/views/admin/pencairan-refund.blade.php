@extends('layouts.admin')

@section('title', 'Pencairan & Refund - ACare Admin Portal')

@section('content')

<script>
function initPencairan() {
    return {
        filterStatus: {!! json_encode($statusAwal) !!},
        filterJenis: 'semua',
        searchQuery: {!! json_encode((string) request('q', '')) !!},
        urutan: 'terbaru',
        halaman: 1,
        perHalaman: 10,
        dipilih: [],
        showDetailModal: false,
        selected: null,
        aksi: null,
        isianAlasan: '',
        isianReferensi: '',
        daftar: {!! json_encode($pengajuanList) !!},
        idTransaksi: {!! json_encode($idTransaksi) !!},

        init: function () {
            var self = this;
            ['filterStatus', 'filterJenis', 'searchQuery', 'urutan'].forEach(function (k) {
                self.$watch(k, function () { self.halaman = 1; self.dipilih = []; });
            });
            this.$watch('halaman', function () { self.dipilih = []; });
            this.$watch('showDetailModal', function (buka) { if (!buka) { self.aksi = null; } });
        },

        rupiah: function (n) { return 'Rp ' + Number(n).toLocaleString('id-ID'); },
        samar: function (nomor) { return '•••• ' + String(nomor).slice(-4); },
        adaTransaksi: function (id) { return this.idTransaksi.includes(id); },

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
                if (self.filterJenis !== 'semua' && p.jenis !== self.filterJenis) {
                    return false;
                }
                var q = self.searchQuery.trim().toLowerCase();
                if (q === '') {
                    return true;
                }
                return p.id.toLowerCase().includes(q)
                    || p.pemohon.toLowerCase().includes(q)
                    || p.tujuan.nama.toLowerCase().includes(q)
                    || p.pesanan.some(function (o) { return o.id.toLowerCase().includes(q); });
            });
            return hasil.sort(function (a, b) {
                if (self.urutan === 'terbesar') { return b.nominal - a.nominal; }
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
        // Hanya pengajuan yang menunggu yang bisa disetujui sekaligus.
        get bisaDisetujui() {
            var self = this;
            return this.daftar.filter(function (p) { return self.dipilih.includes(p.id) && p.status === 'Menunggu'; });
        },

        hitung: function (status) {
            if (status === 'Semua') {
                return this.daftar.length;
            }
            return this.daftar.filter(function (p) { return p.status === status; }).length;
        },
        menunggu: function (jenis) {
            return this.daftar.filter(function (p) { return p.status === 'Menunggu' && p.jenis === jenis; });
        },
        total: function (daftar) {
            return daftar.reduce(function (a, p) { return a + p.nominal; }, 0);
        },
        get selesai() {
            return this.daftar.filter(function (p) { return p.status === 'Selesai Ditransfer'; });
        },

        // Terapkan perubahan ke server, lalu ke tampilan. Toast menyediakan Batalkan.
        terapkan: function (daftarUbah, statusBaru, ekstra, pesanSelesai) {
            var self = this;
            if (daftarUbah.length === 0) {
                return;
            }
            ekstra = ekstra || {};
            var sebelum = daftarUbah.map(function (p) {
                return { id: p.id, status: p.status, alasan: p.alasan, referensi: p.referensi, waktu_transfer: p.waktu_transfer };
            });
            var sesudah = daftarUbah.map(function (p) {
                return { id: p.id, status: statusBaru, alasan: ekstra.alasan || null, referensi: ekstra.referensi || null };
            });

            window.kirimAdmin('{{ route('admin.pencairan.status') }}', { perubahan: sesudah }).then(function (r) {
                if (!r.ok) {
                    window.adminToast((r.data && r.data.pesan) || 'Perubahan gagal disimpan.', { tipe: 'error' });
                    return;
                }
                self.setLokal(r.data.catatan);
                window.setLencana('pencairan', r.data.menunggu);
                self.dipilih = [];
                self.showDetailModal = false;
                var pesan = daftarUbah.length === 1
                    ? 'Pengajuan ' + daftarUbah[0].id + ' ' + pesanSelesai + '.'
                    : daftarUbah.length + ' pengajuan ' + pesanSelesai + '.';
                window.adminToast(pesan, { batal: function () { self.pulihkan(sebelum); } });
            });
        },

        pulihkan: function (sebelum) {
            var self = this;
            window.kirimAdmin('{{ route('admin.pencairan.status') }}', { pulihkan: true, perubahan: sebelum }).then(function (r) {
                if (r.ok) {
                    self.setLokal(r.data.catatan);
                    window.setLencana('pencairan', r.data.menunggu);
                    window.adminToast('Perubahan dibatalkan.');
                } else {
                    window.adminToast('Pembatalan gagal. Muat ulang halaman.', { tipe: 'error' });
                }
            });
        },

        setLokal: function (catatan) {
            var self = this;
            Object.keys(catatan).forEach(function (id) {
                var p = self.daftar.find(function (x) { return x.id === id; });
                if (p) {
                    p.status = catatan[id].status;
                    p.alasan = catatan[id].alasan;
                    p.referensi = catatan[id].referensi;
                    p.waktu_transfer = catatan[id].waktu_transfer;
                }
            });
        },

        setujui: function () { this.terapkan([this.selected], 'Disetujui', {}, 'disetujui'); },
        tolak: function () {
            if (this.isianAlasan.trim() === '') { return; }
            this.terapkan([this.selected], 'Ditolak', { alasan: this.isianAlasan.trim() }, 'ditolak');
        },
        tandaiTransfer: function () {
            if (this.isianReferensi.trim() === '') { return; }
            this.terapkan([this.selected], 'Selesai Ditransfer', { referensi: this.isianReferensi.trim() }, 'ditandai selesai ditransfer');
        },

        bukaDetail: function (p) {
            this.selected = p;
            this.aksi = null;
            this.isianAlasan = '';
            this.isianReferensi = '';
            this.showDetailModal = true;
        },
        mulaiAksi: function (jenis) {
            this.aksi = jenis;
            this.isianAlasan = '';
            this.isianReferensi = '';
        },

        salinNomor: function (nomor) {
            var selesai = function () { window.adminToast('Nomor tujuan disalin.'); };
            if (navigator.clipboard) {
                navigator.clipboard.writeText(nomor).then(selesai, function () { window.adminToast('Gagal menyalin nomor.', { tipe: 'error' }); });
            }
        },

        badgeClass: function (status) {
            if (status === 'Menunggu') { return 'text-amber-700'; }
            if (status === 'Disetujui') { return 'text-brand-dark'; }
            if (status === 'Selesai Ditransfer') { return 'text-emerald-700'; }
            return 'text-rose-700';
        },
        jenisClass: function (jenis) {
            return jenis === 'Pencairan' ? 'bg-brand-50 text-brand-dark' : 'bg-amber-50 text-amber-700';
        }
    };
}
</script>

<div class="p-8" x-data="initPencairan()">

    <!-- Breadcrumb -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-500 mb-3">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-slate-700 transition-colors">Beranda</a>
        <span>&gt;</span>
        <span class="text-slate-600 font-semibold">Pencairan &amp; Refund</span>
    </div>

    <!-- Judul -->
    <div class="mb-6">
        <h1 class="text-2xl font-bold text-navy tracking-tight">Pencairan &amp; Refund</h1>
        <p class="text-sm text-slate-500 mt-0.5">Proses pengajuan pencairan pendapatan teknisi dan refund pelanggan. Transfer dilakukan manual, lalu dicatat di sini.</p>
    </div>

    <!-- 3 Kartu Ringkasan -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-5">
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Pencairan Menunggu</p>
            <p class="text-2xl font-bold text-navy mt-2" x-text="rupiah(total(menunggu('Pencairan')))"></p>
            <p class="text-xs text-slate-500 mt-1"><span x-text="menunggu('Pencairan').length"></span> pengajuan teknisi</p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Refund Menunggu</p>
            <p class="text-2xl font-bold text-navy mt-2" x-text="rupiah(total(menunggu('Refund')))"></p>
            <p class="text-xs text-slate-500 mt-1"><span x-text="menunggu('Refund').length"></span> pengajuan pelanggan</p>
        </div>
        <div class="bg-white border border-line rounded-lg px-4 py-4">
            <p class="text-xs text-slate-500">Sudah Ditransfer</p>
            <p class="text-2xl font-bold text-navy mt-2" x-text="rupiah(total(selesai))"></p>
            <p class="text-xs text-slate-500 mt-1"><span x-text="selesai.length"></span> pengajuan selesai</p>
        </div>
    </div>

    <!-- Filter Status & Pencarian -->
    <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
        <div class="flex bg-white border border-line rounded-lg p-1 gap-0.5">
            @foreach(['Semua', 'Menunggu', 'Disetujui', 'Selesai Ditransfer', 'Ditolak'] as $st)
            <button type="button"
                    @click="filterStatus = '{{ $st }}'"
                    :class="filterStatus === '{{ $st }}' ? 'bg-brand text-white font-bold' : 'text-slate-500 hover:text-slate-800 font-semibold'"
                    class="px-3.5 py-1.5 rounded-lg text-xs transition-all flex items-center gap-1.5 whitespace-nowrap">
                <span>{{ $st }}</span>
                <span class="text-xs opacity-80" x-text="hitung('{{ $st }}')"></span>
            </button>
            @endforeach
        </div>

        <div class="flex items-center gap-3">
            <select x-model="filterJenis" aria-label="Saring berdasarkan jenis"
                    class="py-2 pl-3 pr-8 bg-white border border-line rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
                <option value="semua">Semua jenis</option>
                <option value="Pencairan">Pencairan teknisi</option>
                <option value="Refund">Refund pelanggan</option>
            </select>
            <select x-model="urutan" aria-label="Urutkan pengajuan"
                    class="py-2 pl-3 pr-8 bg-white border border-line rounded-lg text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
                <option value="terbaru">Terbaru dulu</option>
                <option value="terlama">Terlama dulu</option>
                <option value="terbesar">Nominal terbesar</option>
            </select>
            <div class="relative w-56">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                    <iconify-icon icon="lucide:search" width="16" height="16" aria-hidden="true"></iconify-icon>
                </span>
                <input type="text"
                       x-model="searchQuery"
                       placeholder="Cari pengajuan..."
                       class="w-full pl-9 pr-3 py-2 bg-white border border-line rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
            </div>
        </div>
    </div>

    <!-- Bilah aksi massal: muncul hanya saat ada baris dipilih -->
    <div x-show="dipilih.length > 0" style="display: none;"
         class="mb-3 flex items-center justify-between gap-3 px-4 py-2.5 rounded-lg border border-brand bg-brand-50">
        <p class="text-sm font-semibold text-navy"><span x-text="dipilih.length"></span> pengajuan dipilih</p>
        <div class="flex items-center gap-2">
            <button type="button" @click="dipilih = []"
                    class="px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-white rounded-lg transition-colors">Batal pilih</button>
            <button type="button" x-show="bisaDisetujui.length > 0"
                    @click="terapkan(bisaDisetujui, 'Disetujui', {}, 'disetujui')"
                    class="px-3.5 py-1.5 bg-brand hover:bg-brand-dark text-white text-sm font-semibold rounded-lg transition-colors">
                Setujui <span x-text="bisaDisetujui.length"></span> pengajuan
            </button>
        </div>
    </div>

    <!-- Tabel Pengajuan -->
    <div class="bg-white rounded-lg border border-line overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="bg-brand-50 text-xs font-bold text-slate-600">
                        <th class="py-3 pl-5 pr-2 w-10">
                            <input type="checkbox" :checked="semuaTerpilih" @change="pilihSemua()"
                                   aria-label="Pilih semua pengajuan di halaman ini"
                                   class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand">
                        </th>
                        <th class="py-3 px-3">ID &amp; Waktu</th>
                        <th class="py-3 px-4">Pemohon</th>
                        <th class="py-3 px-4">Jenis</th>
                        <th class="py-3 px-4">Tujuan Transfer</th>
                        <th class="py-3 px-4 text-right">Nominal</th>
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
                                <p class="font-bold text-slate-800 whitespace-nowrap" x-text="p.pemohon"></p>
                                <p class="text-xs text-slate-500" x-text="p.peran"></p>
                            </td>
                            <td class="py-3.5 px-4">
                                <span class="inline-flex px-2 py-0.5 rounded text-xs font-semibold" :class="jenisClass(p.jenis)" x-text="p.jenis"></span>
                            </td>
                            <td class="py-3.5 px-4 whitespace-nowrap">
                                <p class="font-medium text-slate-700" x-text="p.tujuan.nama"></p>
                                <p class="text-xs text-slate-500 font-mono" x-text="samar(p.tujuan.nomor)"></p>
                            </td>
                            <td class="py-3.5 px-4 text-right font-bold text-navy whitespace-nowrap" x-text="rupiah(p.nominal)"></td>
                            <td class="py-3.5 px-4">
                                <span class="inline-flex items-center gap-1.5 text-xs font-semibold whitespace-nowrap" :class="badgeClass(p.status)"><span x-text="p.status"></span></span>
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
                            Tidak ada pengajuan yang cocok.
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        @include('admin.partials.paginasi')
    </div>

    <!-- Modal Detail Pengajuan -->
    <div x-show="showDetailModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4"
         style="display: none;">
        <div @click.away="showDetailModal = false"
             class="bg-white rounded-xl max-w-xl w-full max-h-[92vh] overflow-y-auto shadow-lg border border-line">

            <div class="px-6 py-4 border-b border-line flex items-center justify-between">
                <div>
                    <p class="font-mono text-xs font-bold text-brand-dark" x-text="selected ? selected.id : ''"></p>
                    <h3 class="text-base font-bold text-navy" x-text="selected ? (selected.jenis === 'Pencairan' ? 'Pencairan Pendapatan Teknisi' : 'Refund Pelanggan') : ''"></h3>
                </div>
                <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="selected ? badgeClass(selected.status) : ''"><span x-text="selected ? selected.status : ''"></span></span>
            </div>

            <div class="px-6 py-5 space-y-4 text-xs">
                <div class="rounded-lg bg-brand-50 border border-line px-4 py-3 flex items-center justify-between">
                    <span class="text-slate-600 font-semibold">Nominal yang ditransfer</span>
                    <span class="text-xl font-bold text-navy" x-text="selected ? rupiah(selected.nominal) : ''"></span>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <p class="text-slate-500 font-semibold">Pemohon</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.pemohon + ' (' + selected.peran + ')' : ''"></p>
                    </div>
                    <div>
                        <p class="text-slate-500 font-semibold">Waktu Pengajuan</p>
                        <p class="font-bold text-slate-800" x-text="selected ? selected.tanggal + ', ' + selected.jam : ''"></p>
                    </div>
                </div>

                <!-- Tujuan transfer -->
                <div>
                    <p class="text-slate-500 font-semibold mb-1">Tujuan Transfer</p>
                    <div class="rounded-lg border border-line p-3 flex items-center justify-between gap-3">
                        <div class="flex items-center gap-3 min-w-0">
                            <div class="w-9 h-9 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center flex-shrink-0">
                                <iconify-icon :icon="selected && selected.tujuan.jenis === 'Bank' ? 'lucide:landmark' : 'lucide:smartphone'" width="18" height="18" aria-hidden="true"></iconify-icon>
                            </div>
                            <div class="min-w-0">
                                <p class="font-bold text-slate-800" x-text="selected ? selected.tujuan.nama + ' (' + selected.tujuan.jenis + ')' : ''"></p>
                                <p class="font-mono text-slate-700" x-text="selected ? selected.tujuan.nomor : ''"></p>
                                <p class="text-slate-500" x-text="selected ? 'a.n. ' + selected.tujuan.atas_nama : ''"></p>
                            </div>
                        </div>
                        <button type="button" @click="salinNomor(selected.tujuan.nomor)"
                                class="flex items-center gap-1.5 px-3 py-1.5 border border-line text-slate-700 hover:bg-slate-50 rounded-lg font-semibold transition-colors flex-shrink-0">
                            <iconify-icon icon="lucide:copy" width="14" height="14" aria-hidden="true"></iconify-icon>
                            Salin
                        </button>
                    </div>
                </div>

                <!-- Alasan refund -->
                <div x-show="selected && selected.alasan_pengajuan">
                    <p class="text-slate-500 font-semibold mb-1">Alasan Refund</p>
                    <p class="text-slate-700 leading-relaxed bg-slate-50 border border-line rounded-lg p-3" x-text="selected ? selected.alasan_pengajuan : ''"></p>
                </div>

                <!-- Pesanan terkait -->
                <div>
                    <p class="text-slate-500 font-semibold mb-1" x-text="selected && selected.jenis === 'Pencairan' ? 'Pendapatan dari Pesanan (setelah potongan platform 15%)' : 'Pesanan Terkait'"></p>
                    <ul class="rounded-lg border border-line divide-y divide-line">
                        <template x-for="o in (selected ? selected.pesanan : [])" :key="o.id">
                            <li class="flex items-center justify-between gap-3 px-3 py-2">
                                <div class="min-w-0">
                                    <template x-if="adaTransaksi(o.id)">
                                        <button type="button" @click="$dispatch('buka-detail-transaksi', { id: o.id })"
                                                class="font-mono font-bold text-brand-dark hover:underline" x-text="o.id"></button>
                                    </template>
                                    <template x-if="!adaTransaksi(o.id)">
                                        <span class="font-mono font-bold text-slate-800" x-text="o.id"></span>
                                    </template>
                                    <span class="text-slate-500" x-text="' · ' + o.keterangan"></span>
                                </div>
                                <span class="font-semibold text-slate-800 whitespace-nowrap" x-text="rupiah(o.nominal)"></span>
                            </li>
                        </template>
                    </ul>
                </div>

                <!-- Hasil: selesai ditransfer -->
                <div x-show="selected && selected.status === 'Selesai Ditransfer'"
                     class="flex items-start gap-2 rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-emerald-800">
                    <iconify-icon icon="lucide:circle-check" width="16" height="16" class="mt-0.5 flex-shrink-0" aria-hidden="true"></iconify-icon>
                    <p>Ditransfer <span class="font-semibold" x-text="selected ? selected.waktu_transfer : ''"></span>.
                       Referensi transfer: <span class="font-mono font-semibold" x-text="selected ? selected.referensi : ''"></span></p>
                </div>

                <!-- Hasil: ditolak -->
                <div x-show="selected && selected.status === 'Ditolak'"
                     class="flex items-start gap-2 rounded-lg border border-rose-200 bg-rose-50 p-3 text-rose-800">
                    <iconify-icon icon="lucide:circle-x" width="16" height="16" class="mt-0.5 flex-shrink-0" aria-hidden="true"></iconify-icon>
                    <p>Pengajuan ditolak. Alasan: <span class="font-semibold" x-text="selected ? selected.alasan : ''"></span></p>
                </div>

                <!-- Isian: tolak -->
                <div x-show="aksi === 'tolak'" style="display: none;" class="rounded-lg border border-rose-200 p-3 space-y-2">
                    <label for="alasan-tolak" class="block font-semibold text-slate-700">Alasan penolakan (dikirim ke pemohon)</label>
                    <textarea id="alasan-tolak" x-model="isianAlasan" rows="2" maxlength="200"
                              placeholder="Contoh: Nomor rekening tidak sesuai dengan nama pemilik."
                              class="w-full px-3 py-2 bg-white border border-line rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand"></textarea>
                    <div class="flex justify-end gap-2">
                        <button type="button" @click="aksi = null"
                                class="px-3 py-1.5 text-slate-700 hover:bg-slate-100 rounded-lg font-semibold transition-colors">Batal</button>
                        <button type="button" @click="tolak()" :disabled="isianAlasan.trim() === ''"
                                class="px-3.5 py-1.5 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-semibold transition-colors disabled:opacity-40 disabled:cursor-not-allowed">Tolak pengajuan</button>
                    </div>
                </div>

                <!-- Isian: selesai ditransfer -->
                <div x-show="aksi === 'transfer'" style="display: none;" class="rounded-lg border border-line p-3 space-y-2">
                    <label for="referensi-transfer" class="block font-semibold text-slate-700">Referensi transfer</label>
                    <input id="referensi-transfer" type="text" x-model="isianReferensi" maxlength="60"
                           placeholder="Contoh: TF-BCA-261110-0021"
                           class="w-full px-3 py-2 bg-white border border-line rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
                    <p class="text-slate-500">Pastikan dana sudah ditransfer ke tujuan di atas sebelum menandai selesai. Waktu transfer dicatat otomatis.</p>
                    <div class="flex justify-end gap-2">
                        <button type="button" @click="aksi = null"
                                class="px-3 py-1.5 text-slate-700 hover:bg-slate-100 rounded-lg font-semibold transition-colors">Batal</button>
                        <button type="button" @click="tandaiTransfer()" :disabled="isianReferensi.trim() === ''"
                                class="px-3.5 py-1.5 bg-brand hover:bg-brand-dark text-white rounded-lg font-semibold transition-colors disabled:opacity-40 disabled:cursor-not-allowed">Tandai selesai ditransfer</button>
                    </div>
                </div>
            </div>

            <div class="px-6 py-4 border-t border-line flex items-center justify-between gap-3">
                <button type="button"
                        @click="showDetailModal = false"
                        class="px-4 py-2.5 border border-slate-400 text-slate-700 hover:bg-slate-50 font-semibold text-sm rounded-lg transition-colors">
                    Tutup
                </button>
                <div class="flex items-center gap-2" x-show="selected && (selected.status === 'Menunggu' || selected.status === 'Disetujui') && aksi === null">
                    <button type="button" @click="mulaiAksi('tolak')"
                            class="px-4 py-2.5 border border-rose-300 text-rose-700 hover:bg-rose-50 font-semibold text-sm rounded-lg transition-colors">
                        Tolak
                    </button>
                    <button type="button" x-show="selected && selected.status === 'Menunggu'"
                            @click="setujui()"
                            class="px-4 py-2.5 bg-brand hover:bg-brand-dark text-white font-semibold text-sm rounded-lg transition-colors">
                        Setujui
                    </button>
                    <button type="button" x-show="selected && selected.status === 'Disetujui'"
                            @click="mulaiAksi('transfer')"
                            class="px-4 py-2.5 bg-brand hover:bg-brand-dark text-white font-semibold text-sm rounded-lg transition-colors">
                        Tandai selesai ditransfer
                    </button>
                </div>
            </div>
        </div>
    </div>

    @include('admin.partials.detail-transaksi')

</div>

@endsection
