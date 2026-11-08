@extends('layouts.admin')

@section('title', 'Kelola Layanan - ACare Admin Portal')

@section('content')
<script>
function initKelolaLayanan() {
    return {
        filterStatus: 'Semua',
        search: '',
        showModal: false,
        showDeleteModal: false,
        deleteTarget: null,
        editMode: false,
        form: { nama: '', harga_min: '', harga_max: '', durasi: '', deskripsi: '', status: 'Aktif' },
        layanan: {!! json_encode($layanan) !!},
        errors: {},
        urutKolom: 'nama',
        urutArah: 1,
        halaman: 1,
        perHalaman: 10,

        get totalLayanan() { return this.layanan.length; },
        get layananAktif() { return this.layanan.filter(function(l) { return l.status === 'Aktif'; }).length; },
        get layananNonaktif() { return this.layanan.filter(function(l) { return l.status !== 'Aktif'; }).length; },

        tampilkanToast(pesan, tipe, batal) {
            window.adminToast(pesan, { tipe: tipe || 'success', batal: batal || null });
        },

        // Simpan katalog ke server; bila gagal, tampilan dikembalikan. Berhasil -> toast dengan Batalkan.
        terapkan(daftarBaru, pesan, tipe) {
            var self = this;
            var sebelum = JSON.parse(JSON.stringify(this.layanan));
            this.layanan = daftarBaru;
            return window.kirimAdmin('{{ route('admin.layanan.sinkron') }}', { layanan: daftarBaru }).then(function (r) {
                if (!r.ok) {
                    self.layanan = sebelum;
                    var galat = (r.data && r.data.pesan) || 'Perubahan gagal disimpan.';
                    window.adminToast(galat, { tipe: 'error' });
                    return false;
                }
                self.tampilkanToast(pesan, tipe, function () {
                    window.kirimAdmin('{{ route('admin.layanan.sinkron') }}', { layanan: sebelum }).then(function (h) {
                        if (h.ok) { self.layanan = sebelum; window.adminToast('Perubahan dibatalkan.'); }
                    });
                });
                return true;
            });
        },

        validasiForm() {
            var galat = {};
            var nama = String(this.form.nama || '').trim();
            var min = Number(this.form.harga_min);
            var max = Number(this.form.harga_max);
            var self = this;
            if (nama === '') {
                galat.nama = 'Nama layanan wajib diisi.';
            } else if (this.layanan.some(function(l) { return l.id !== self.form.id && l.nama.toLowerCase() === nama.toLowerCase(); })) {
                galat.nama = 'Nama layanan sudah ada.';
            }
            if (!(min > 0)) {
                galat.harga_min = 'Harga minimum harus lebih dari 0.';
            }
            if (!(max > 0)) {
                galat.harga_max = 'Harga maksimum harus lebih dari 0.';
            } else if (max < min) {
                galat.harga_max = 'Harga maksimum tidak boleh lebih kecil dari harga minimum.';
            }
            if (String(this.form.durasi || '').trim() === '') {
                galat.durasi = 'Estimasi durasi wajib diisi.';
            }
            this.errors = galat;
            return Object.keys(galat).length === 0;
        },

        simpan() {
            if (!this.validasiForm()) {
                return;
            }
            var data = Object.assign({}, this.form, {
                nama: String(this.form.nama).trim(),
                harga_min: Number(this.form.harga_min),
                harga_max: Number(this.form.harga_max),
                durasi: String(this.form.durasi).trim()
            });
            var daftar = JSON.parse(JSON.stringify(this.layanan));
            var pesan;
            if (this.editMode) {
                var indeks = daftar.findIndex(function(l) { return l.id === data.id; });
                daftar.splice(indeks, 1, data);
                pesan = 'Layanan "' + data.nama + '" diperbarui.';
            } else {
                data.id = daftar.reduce(function(maks, l) { return Math.max(maks, l.id); }, 0) + 1;
                data.icon = 'lucide:settings';
                data.warna = 'bg-brand-50 text-brand-dark';
                data.total_pesanan = 0;
                daftar.push(data);
                pesan = 'Layanan "' + data.nama + '" ditambahkan.';
            }
            var self = this;
            this.terapkan(daftar, pesan).then(function (ok) {
                if (ok) { self.showModal = false; }
            });
        },

        hapus() {
            var nama = this.deleteTarget.nama;
            var id = this.deleteTarget.id;
            var daftar = this.layanan.filter(function(l) { return l.id !== id; });
            var self = this;
            this.terapkan(daftar, 'Layanan "' + nama + '" dihapus.', 'warning').then(function () {
                self.showDeleteModal = false;
            });
        },

        ubahStatus(item) {
            var baru = item.status === 'Aktif' ? 'Tidak Aktif' : 'Aktif';
            var daftar = JSON.parse(JSON.stringify(this.layanan));
            daftar.find(function(l) { return l.id === item.id; }).status = baru;
            this.terapkan(daftar, 'Layanan "' + item.nama + '" sekarang ' + baru + '.');
        },

        init() {
            var self = this;
            ['filterStatus', 'search'].forEach(function(k) {
                self.$watch(k, function() { self.halaman = 1; });
            });
        },

        urutkan(kolom) {
            if (this.urutKolom === kolom) {
                this.urutArah = -this.urutArah;
            } else {
                this.urutKolom = kolom;
                this.urutArah = 1;
            }
        },

        ariaUrut(kolom) {
            if (this.urutKolom !== kolom) { return 'none'; }
            return this.urutArah === 1 ? 'ascending' : 'descending';
        },

        get filtered() {
            var self = this;
            var hasil = this.layanan.filter(function(l) {
                var matchSts = self.filterStatus === 'Semua' || l.status === self.filterStatus;
                var matchQ   = self.search === '' || l.nama.toLowerCase().includes(self.search.toLowerCase()) ;
                return matchSts && matchQ;
            });
            var kolom = this.urutKolom, arah = this.urutArah;
            return hasil.sort(function(a, b) {
                var x = kolom === 'durasi' ? parseInt(a.durasi, 10) || 0 : a[kolom];
                var y = kolom === 'durasi' ? parseInt(b.durasi, 10) || 0 : b[kolom];
                if (typeof x === 'string') { return arah * x.localeCompare(y, 'id'); }
                return arah * (x - y);
            });
        },

        get totalTersaring() { return this.filtered.length; },
        get jumlahHalaman() { return Math.max(1, Math.ceil(this.totalTersaring / this.perHalaman)); },
        get halamanIni() {
            var mulai = (this.halaman - 1) * this.perHalaman;
            return this.filtered.slice(mulai, mulai + this.perHalaman);
        },

        openAdd() {
            this.editMode = false;
            this.errors = {};
            this.form = { nama: '', harga_min: '', harga_max: '', durasi: '', deskripsi: '', status: 'Aktif' };
            this.showModal = true;
        },

        openEdit(item) {
            this.editMode = true;
            this.errors = {};
            this.form = Object.assign({}, item);
            this.showModal = true;
        },

        confirmDelete(item) {
            this.deleteTarget = item;
            this.showDeleteModal = true;
        },

        formatRupiah(num) {
            if (!num) return '-';
            return 'Rp ' + Number(num).toLocaleString('id-ID');
        }
    };
}
</script>

<div class="h-full" x-data="initKelolaLayanan()" @keydown.escape.window="showModal = false; showDeleteModal = false">

    <!-- Page Header -->
    <div class="px-8 pt-6 pb-4">
        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 text-xs font-medium text-slate-500 mb-2">
            <a href="{{ route('admin.dashboard') }}" class="hover:text-brand-dark transition-colors flex items-center gap-1">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                </svg>
                Beranda
            </a>
            <span>&gt;</span>
            <span class="text-slate-600 font-semibold">Kelola Layanan</span>
        </div>

        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-2xl font-bold text-navy tracking-tight">Kelola Layanan</h1>
                <p class="text-sm text-slate-500 mt-0.5">Manajemen layanan AC yang tersedia di platform ACare</p>
            </div>
            <button @click="openAdd()"
                class="flex items-center gap-2 px-4 py-2.5 bg-brand text-white text-xs font-bold rounded-lg  hover:bg-brand-dark transition-all">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                Tambah Layanan
            </button>
        </div>
    </div>

    <!-- Filter Bar -->
    <div class="px-8 pb-4 flex flex-wrap items-center gap-3">
        <!-- Search -->
        <div class="relative flex-1 max-w-xs">
            <span class="absolute inset-y-0 left-3 flex items-center text-slate-500">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </span>
            <input type="text" x-model="search" placeholder="Cari layanan..."
                class="w-full pl-9 pr-3 py-2 bg-white border border-line rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent">
        </div>

        <!-- Status Filter -->
        <select x-model="filterStatus"
            class="px-3 py-2 bg-white border border-line rounded-lg text-sm font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
            <option value="Semua">Semua Status</option>
            <option value="Aktif">Aktif</option>
            <option value="Tidak Aktif">Tidak Aktif</option>
        </select>

        <p class="ml-auto text-sm text-slate-600 whitespace-nowrap">
            <span x-text="totalLayanan"></span> layanan ·
            <span x-text="layananAktif"></span> aktif ·
            <span x-text="layananNonaktif"></span> nonaktif
        </p>
    </div>

    <!-- Tabel Layanan -->
    <div class="px-8 pb-8">
        <div class="bg-white rounded-lg border border-line overflow-hidden">
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-brand-50 text-xs text-slate-600">
                        <th class="py-3 px-3 pl-5" :aria-sort="ariaUrut('nama')">
                            <button type="button" @click="urutkan('nama')" class="inline-flex items-center gap-1 font-bold hover:text-navy transition-colors">
                                <span>Layanan</span>
                                <iconify-icon :icon="urutKolom === 'nama' ? (urutArah === 1 ? 'lucide:arrow-up' : 'lucide:arrow-down') : 'lucide:arrow-up-down'"
                                              :class="urutKolom === 'nama' ? 'text-brand-dark' : 'text-slate-400'" width="13" height="13" aria-hidden="true"></iconify-icon>
                            </button>
                        </th>
                        <th class="py-3 px-3 text-right" :aria-sort="ariaUrut('harga_min')">
                            <button type="button" @click="urutkan('harga_min')" class="inline-flex items-center gap-1 font-bold hover:text-navy transition-colors">
                                <span>Harga (Rp)</span>
                                <iconify-icon :icon="urutKolom === 'harga_min' ? (urutArah === 1 ? 'lucide:arrow-up' : 'lucide:arrow-down') : 'lucide:arrow-up-down'"
                                              :class="urutKolom === 'harga_min' ? 'text-brand-dark' : 'text-slate-400'" width="13" height="13" aria-hidden="true"></iconify-icon>
                            </button>
                        </th>
                        <th class="py-3 px-3 " :aria-sort="ariaUrut('durasi')">
                            <button type="button" @click="urutkan('durasi')" class="inline-flex items-center gap-1 font-bold hover:text-navy transition-colors">
                                <span>Durasi (menit)</span>
                                <iconify-icon :icon="urutKolom === 'durasi' ? (urutArah === 1 ? 'lucide:arrow-up' : 'lucide:arrow-down') : 'lucide:arrow-up-down'"
                                              :class="urutKolom === 'durasi' ? 'text-brand-dark' : 'text-slate-400'" width="13" height="13" aria-hidden="true"></iconify-icon>
                            </button>
                        </th>
                        <th class="py-3 px-3 font-bold">Status</th>
                        <th class="py-3 px-4 font-bold text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-line text-sm">
                    <template x-for="item in halamanIni" :key="item.id">
                        <tr class="hover:bg-slate-50 transition-colors" :class="item.status === 'Aktif' ? '' : 'bg-slate-50/60'">
                            <td class="py-3 pl-5 pr-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0" :class="item.warna">
                                        <iconify-icon :icon="item.icon" width="18" height="18" aria-hidden="true"></iconify-icon>
                                    </div>
                                    <div class="min-w-0">
                                        <p class="font-bold text-navy whitespace-nowrap" x-text="item.nama" :title="item.deskripsi"></p>
                                    </div>
                                </div>
                            </td>
                            <td class="py-3 px-3 text-right whitespace-nowrap font-semibold text-slate-800"
                                x-text="Number(item.harga_min).toLocaleString('id-ID') + ' – ' + Number(item.harga_max).toLocaleString('id-ID')"></td>
                            <td class="py-3 px-3 whitespace-nowrap text-slate-700" x-text="String(item.durasi).replace(/ menit$/, '')"></td>
                            <td class="py-3 px-3">
                                <div class="flex items-center gap-2.5">
                                    <button type="button" role="switch" :aria-checked="item.status === 'Aktif'"
                                            :aria-label="'Layanan ' + item.nama + ' ' + (item.status === 'Aktif' ? 'aktif, klik untuk menonaktifkan' : 'nonaktif, klik untuk mengaktifkan')"
                                            @click="ubahStatus(item)"
                                            :class="item.status === 'Aktif' ? 'bg-brand' : 'bg-slate-300'"
                                            class="relative inline-flex h-5 w-9 flex-shrink-0 items-center rounded-full transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2">
                                        <span :class="item.status === 'Aktif' ? 'translate-x-4' : 'translate-x-0.5'"
                                              class="inline-block h-4 w-4 rounded-full bg-white transition-transform"></span>
                                    </button>
                                    <span class="sr-only" x-text="item.status"></span>
                                </div>
                            </td>
                            <td class="py-3 px-4">
                                <div class="flex items-center justify-end gap-1">
                                    <button type="button" @click="openEdit(item)"
                                            :aria-label="'Ubah layanan ' + item.nama"
                                            :title="'Ubah layanan ' + item.nama"
                                            class="p-2 text-brand-dark hover:bg-brand-50 rounded-lg transition-colors">
                                        <iconify-icon icon="lucide:pencil" width="16" height="16" aria-hidden="true"></iconify-icon>
                                    </button>
                                    <button type="button" @click="confirmDelete(item)"
                                            :aria-label="'Hapus layanan ' + item.nama" :title="'Hapus layanan ' + item.nama"
                                            class="p-2 text-rose-600 hover:bg-rose-50 rounded-lg transition-colors">
                                        <iconify-icon icon="lucide:trash-2" width="16" height="16" aria-hidden="true"></iconify-icon>
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </template>
                    <tr x-show="totalTersaring === 0" style="display: none;">
                        <td colspan="6" class="py-12 text-center">
                            <p class="text-sm font-bold text-slate-600">Layanan tidak ditemukan</p>
                            <p class="text-xs text-slate-500 mt-1">Coba ubah filter atau kata kunci pencarian.</p>
                        </td>
                    </tr>
                </tbody>
                </table>
            </div>
            @include('admin.partials.paginasi')
        </div>
    </div>

    <!-- ===================== MODAL TAMBAH/EDIT ===================== -->
    <div x-show="showModal" x-cloak
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0">
        <div class="absolute inset-0 bg-black/40" @click="showModal = false"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-lg z-10" @click.stop>
            <!-- Modal Header -->
            <div class="px-6 pt-6 pb-4 border-b border-line flex items-center justify-between">
                <div>
                    <h2 class="text-base font-bold text-navy" x-text="editMode ? 'Edit Layanan' : 'Tambah Layanan Baru'"></h2>
                    <p class="text-sm text-slate-500 mt-0.5">Isi informasi layanan AC dengan lengkap</p>
                </div>
                <button @click="showModal = false" aria-label="Tutup" class="p-2 hover:bg-slate-100 rounded-lg transition-all">
                    <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <!-- Modal Body -->
            <div class="px-6 py-5 space-y-4">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1.5">Nama Layanan</label>
                    <input type="text" x-model="form.nama" placeholder="Contoh: Cuci AC 1/2 PK"
                        class="w-full px-3 py-2.5 bg-slate-50 border border-line rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent">
                    <p x-show="errors.nama" x-text="errors.nama" class="mt-1 text-xs font-semibold text-rose-600" style="display: none;"></p>
                </div>
                <div class="grid grid-cols-1 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Status</label>
                        <select x-model="form.status"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-line rounded-lg text-sm font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-brand">
                            <option>Aktif</option>
                            <option>Tidak Aktif</option>
                        </select>
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Harga Minimum (Rp)</label>
                        <input type="number" min="0" x-model="form.harga_min" placeholder="80000"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-line rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
                        <p x-show="errors.harga_min" x-text="errors.harga_min" class="mt-1 text-xs font-semibold text-rose-600" style="display: none;"></p>
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Harga Maksimum (Rp)</label>
                        <input type="number" min="0" x-model="form.harga_max" placeholder="150000"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-line rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
                        <p x-show="errors.harga_max" x-text="errors.harga_max" class="mt-1 text-xs font-semibold text-rose-600" style="display: none;"></p>
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1.5">Estimasi Durasi</label>
                    <input type="text" x-model="form.durasi" placeholder="Contoh: 60–90 menit"
                        class="w-full px-3 py-2.5 bg-slate-50 border border-line rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand">
                    <p x-show="errors.durasi" x-text="errors.durasi" class="mt-1 text-xs font-semibold text-rose-600" style="display: none;"></p>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1.5">Deskripsi</label>
                    <textarea x-model="form.deskripsi" rows="3" placeholder="Deskripsi singkat layanan..."
                        class="w-full px-3 py-2.5 bg-slate-50 border border-line rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand resize-none"></textarea>
                </div>
            </div>
            <!-- Modal Footer -->
            <div class="px-6 pb-6 flex gap-3">
                <button @click="showModal = false"
                    class="flex-1 py-2.5 bg-slate-100 text-slate-700 text-xs font-bold rounded-lg hover:bg-slate-200 transition-all">
                    Batal
                </button>
                <button @click="simpan()"
                    class="flex-1 py-2.5 bg-brand text-white text-xs font-bold rounded-lg hover:bg-brand-dark transition-all ">
                    <span x-text="editMode ? 'Simpan Perubahan' : 'Tambah Layanan'"></span>
                </button>
            </div>
        </div>
    </div>

    <!-- ===================== MODAL HAPUS ===================== -->
    <div x-show="showDeleteModal" x-cloak
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100">
        <div class="absolute inset-0 bg-black/40" @click="showDeleteModal = false"></div>
        <div class="relative bg-white rounded-lg shadow-lg w-full max-w-sm z-10 p-6 text-center" @click.stop>
            <div class="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-7 h-7 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                </svg>
            </div>
            <h3 class="text-base font-bold text-navy mb-1">Hapus Layanan?</h3>
            <p class="text-xs text-slate-500 mb-5">Layanan "<span class="font-semibold text-slate-700" x-text="deleteTarget?.nama"></span>" akan dihapus permanen dan tidak dapat dikembalikan.
                <span x-show="deleteTarget && deleteTarget.total_pesanan > 0" class="block mt-2 font-semibold text-amber-800" x-text="'Layanan ini sudah dipakai di ' + (deleteTarget ? deleteTarget.total_pesanan : 0) + ' pesanan. Pertimbangkan untuk menonaktifkannya saja.'"></span>
            </p>
            <div class="flex gap-3">
                <button @click="showDeleteModal = false"
                    class="flex-1 py-2.5 bg-slate-100 text-slate-700 text-xs font-bold rounded-lg hover:bg-slate-200 transition-all">
                    Batal
                </button>
                <button @click="hapus()"
                    class="flex-1 py-2.5 bg-red-500 text-white text-xs font-bold rounded-lg hover:bg-red-600 transition-all ">
                    Hapus
                </button>
            </div>
        </div>
    </div>


</div>

<style>
[x-cloak] { display: none !important; }
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}
</style>
@endsection
