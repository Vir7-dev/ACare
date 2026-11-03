@extends('layouts.admin')

@section('title', 'Kelola Layanan - ACare Admin Portal')

@section('content')
<script>
function initKelolaLayanan() {
    return {
        filterKategori: 'Semua',
        filterStatus: 'Semua',
        search: '',
        showModal: false,
        showDeleteModal: false,
        deleteTarget: null,
        editMode: false,
        form: { nama: '', kategori: 'Perawatan', harga_min: '', harga_max: '', durasi: '', deskripsi: '', status: 'Aktif' },
        layanan: {!! json_encode($layanan) !!},

        get filtered() {
            var self = this;
            return this.layanan.filter(function(l) {
                var matchKat = self.filterKategori === 'Semua' || l.kategori === self.filterKategori;
                var matchSts = self.filterStatus === 'Semua' || l.status === self.filterStatus;
                var matchQ   = self.search === '' || l.nama.toLowerCase().includes(self.search.toLowerCase()) || l.kategori.toLowerCase().includes(self.search.toLowerCase());
                return matchKat && matchSts && matchQ;
            });
        },

        openAdd() {
            this.editMode = false;
            this.form = { nama: '', kategori: 'Perawatan', harga_min: '', harga_max: '', durasi: '', deskripsi: '', status: 'Aktif' };
            this.showModal = true;
        },

        openEdit(item) {
            this.editMode = true;
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

<div class="h-full" x-data="initKelolaLayanan()">

    <!-- Page Header -->
    <div class="px-8 pt-6 pb-4">
        <!-- Breadcrumb -->
        <div class="flex items-center gap-2 text-xs font-medium text-slate-400 mb-2">
            <a href="{{ route('admin.dashboard') }}" class="hover:text-[#0284C7] transition-colors flex items-center gap-1">
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
                <h1 class="text-xl font-extrabold text-slate-900 tracking-tight">Kelola Layanan</h1>
                <p class="text-xs text-slate-500 mt-0.5">Manajemen layanan AC yang tersedia di platform ACare</p>
            </div>
            <button @click="openAdd()"
                class="flex items-center gap-2 px-4 py-2.5 bg-[#0284C7] text-white text-xs font-bold rounded-xl shadow hover:bg-[#0369a1] transition-all">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                Tambah Layanan
            </button>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="px-8 pb-5 grid grid-cols-4 gap-4">
        <div class="bg-white rounded-2xl p-4 border border-slate-100 shadow-sm flex items-center gap-3">
            <div class="w-10 h-10 bg-sky-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5 text-[#0284C7]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] text-slate-500 font-medium">Total Layanan</p>
                <p class="text-xl font-black text-slate-900">{{ $stats['total_layanan'] }}</p>
            </div>
        </div>
        <div class="bg-white rounded-2xl p-4 border border-slate-100 shadow-sm flex items-center gap-3">
            <div class="w-10 h-10 bg-emerald-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] text-slate-500 font-medium">Layanan Aktif</p>
                <p class="text-xl font-black text-slate-900">{{ $stats['layanan_aktif'] }}</p>
            </div>
        </div>
        <div class="bg-white rounded-2xl p-4 border border-slate-100 shadow-sm flex items-center gap-3">
            <div class="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] text-slate-500 font-medium">Tidak Aktif</p>
                <p class="text-xl font-black text-slate-900">{{ $stats['layanan_nonaktif'] }}</p>
            </div>
        </div>
        <div class="bg-white rounded-2xl p-4 border border-slate-100 shadow-sm flex items-center gap-3">
            <div class="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center flex-shrink-0">
                <svg class="w-5 h-5 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/>
                </svg>
            </div>
            <div>
                <p class="text-[11px] text-slate-500 font-medium">Total Pesanan</p>
                <p class="text-xl font-black text-slate-900">{{ $stats['total_pesanan'] }}</p>
            </div>
        </div>
    </div>

    <!-- Filter Bar -->
    <div class="px-8 pb-4 flex items-center gap-3">
        <!-- Search -->
        <div class="relative flex-1 max-w-xs">
            <span class="absolute inset-y-0 left-3 flex items-center text-slate-400">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
            </span>
            <input type="text" x-model="search" placeholder="Cari layanan..."
                class="w-full pl-9 pr-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7] focus:border-transparent shadow-sm">
        </div>

        <!-- Kategori Tabs -->
        <div class="flex bg-white border border-slate-200 rounded-xl p-1 gap-0.5 shadow-sm">
            @foreach($kategori as $kat)
            <button @click="filterKategori = '{{ $kat }}'"
                :class="filterKategori === '{{ $kat }}' ? 'bg-[#0284C7] text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'"
                class="px-3 py-1.5 rounded-lg text-xs font-semibold transition-all">
                {{ $kat }}
            </button>
            @endforeach
        </div>

        <!-- Status Filter -->
        <select x-model="filterStatus"
            class="px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#0284C7] shadow-sm">
            <option value="Semua">Semua Status</option>
            <option value="Aktif">Aktif</option>
            <option value="Tidak Aktif">Tidak Aktif</option>
        </select>
    </div>

    <!-- Layanan Cards Grid -->
    <div class="px-8 pb-8">
        <template x-if="filtered.length === 0">
            <div class="bg-white rounded-2xl border border-slate-100 p-12 text-center shadow-sm">
                <div class="w-14 h-14 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-3">
                    <svg class="w-7 h-7 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <p class="text-sm font-bold text-slate-600">Layanan tidak ditemukan</p>
                <p class="text-xs text-slate-400 mt-1">Coba ubah filter atau kata kunci pencarian</p>
            </div>
        </template>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            <template x-for="item in filtered" :key="item.id">
                <div class="bg-white rounded-2xl border border-slate-100 shadow-sm hover:shadow-md transition-all overflow-hidden group">
                    <!-- Card Header -->
                    <div class="p-5 pb-3">
                        <div class="flex items-start justify-between mb-3">
                            <div class="flex items-center gap-3">
                                <div class="w-11 h-11 rounded-xl flex items-center justify-center text-xl flex-shrink-0"
                                    :class="item.warna">
                                    <span x-text="item.icon"></span>
                                </div>
                                <div>
                                    <h3 class="text-sm font-bold text-slate-900 leading-tight" x-text="item.nama"></h3>
                                    <span class="inline-block mt-0.5 px-2 py-0.5 bg-sky-50 text-[#0284C7] text-[10px] font-bold rounded-full" x-text="item.kategori"></span>
                                </div>
                            </div>
                            <!-- Status Badge -->
                            <span class="px-2.5 py-1 rounded-full text-[10px] font-bold flex-shrink-0"
                                :class="item.status === 'Aktif' ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'"
                                x-text="item.status">
                            </span>
                        </div>
                        <p class="text-[11px] text-slate-500 leading-relaxed line-clamp-2" x-text="item.deskripsi"></p>
                    </div>

                    <!-- Card Info Grid -->
                    <div class="mx-5 mb-4 grid grid-cols-3 gap-2">
                        <div class="bg-slate-50 rounded-xl p-2.5 text-center">
                            <p class="text-[10px] text-slate-400 font-medium">Harga Min</p>
                            <p class="text-xs font-bold text-slate-800 mt-0.5" x-text="'Rp' + Number(item.harga_min).toLocaleString('id-ID')"></p>
                        </div>
                        <div class="bg-slate-50 rounded-xl p-2.5 text-center">
                            <p class="text-[10px] text-slate-400 font-medium">Harga Max</p>
                            <p class="text-xs font-bold text-slate-800 mt-0.5" x-text="'Rp' + Number(item.harga_max).toLocaleString('id-ID')"></p>
                        </div>
                        <div class="bg-slate-50 rounded-xl p-2.5 text-center">
                            <p class="text-[10px] text-slate-400 font-medium">Pesanan</p>
                            <p class="text-xs font-bold text-slate-800 mt-0.5" x-text="item.total_pesanan"></p>
                        </div>
                    </div>

                    <!-- Durasi Row -->
                    <div class="mx-5 mb-4 flex items-center gap-1.5 text-[11px] text-slate-500">
                        <svg class="w-3.5 h-3.5 text-slate-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                        <span>Durasi estimasi: </span>
                        <span class="font-semibold text-slate-700" x-text="item.durasi"></span>
                    </div>

                    <!-- Actions -->
                    <div class="px-5 pb-5 flex gap-2 border-t border-slate-50 pt-3">
                        <button @click="openEdit(item)"
                            class="flex-1 flex items-center justify-center gap-1.5 py-2 bg-sky-50 text-[#0284C7] text-xs font-bold rounded-xl hover:bg-sky-100 transition-all">
                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                            </svg>
                            Edit
                        </button>
                        <button @click="confirmDelete(item)"
                            class="flex items-center justify-center gap-1.5 px-3 py-2 bg-red-50 text-red-600 text-xs font-bold rounded-xl hover:bg-red-100 transition-all">
                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                            </svg>
                        </button>
                        <!-- Toggle Status -->
                        <button @click="item.status = item.status === 'Aktif' ? 'Tidak Aktif' : 'Aktif'"
                            class="flex items-center justify-center px-3 py-2 text-xs font-bold rounded-xl transition-all border"
                            :class="item.status === 'Aktif' ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100' : 'bg-slate-50 text-slate-500 border-slate-200 hover:bg-slate-100'">
                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l4-4 4 4m0 6l-4 4-4-4"/>
                            </svg>
                        </button>
                    </div>
                </div>
            </template>
        </div>
    </div>

    <!-- ===================== MODAL TAMBAH/EDIT ===================== -->
    <div x-show="showModal" x-cloak
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0">
        <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="showModal = false"></div>
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg z-10" @click.stop>
            <!-- Modal Header -->
            <div class="px-6 pt-6 pb-4 border-b border-slate-100 flex items-center justify-between">
                <div>
                    <h2 class="text-base font-bold text-slate-900" x-text="editMode ? 'Edit Layanan' : 'Tambah Layanan Baru'"></h2>
                    <p class="text-xs text-slate-500 mt-0.5">Isi informasi layanan AC dengan lengkap</p>
                </div>
                <button @click="showModal = false" class="p-2 hover:bg-slate-100 rounded-xl transition-all">
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
                        class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7] focus:border-transparent">
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Kategori</label>
                        <select x-model="form.kategori"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#0284C7]">
                            <option>Perawatan</option>
                            <option>Perbaikan</option>
                            <option>Instalasi</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Status</label>
                        <select x-model="form.status"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#0284C7]">
                            <option>Aktif</option>
                            <option>Tidak Aktif</option>
                        </select>
                    </div>
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Harga Minimum (Rp)</label>
                        <input type="number" x-model="form.harga_min" placeholder="80000"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7]">
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-1.5">Harga Maksimum (Rp)</label>
                        <input type="number" x-model="form.harga_max" placeholder="150000"
                            class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7]">
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1.5">Estimasi Durasi</label>
                    <input type="text" x-model="form.durasi" placeholder="Contoh: 60–90 menit"
                        class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7]">
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1.5">Deskripsi</label>
                    <textarea x-model="form.deskripsi" rows="3" placeholder="Deskripsi singkat layanan..."
                        class="w-full px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0284C7] resize-none"></textarea>
                </div>
            </div>
            <!-- Modal Footer -->
            <div class="px-6 pb-6 flex gap-3">
                <button @click="showModal = false"
                    class="flex-1 py-2.5 bg-slate-100 text-slate-700 text-xs font-bold rounded-xl hover:bg-slate-200 transition-all">
                    Batal
                </button>
                <button @click="showModal = false"
                    class="flex-1 py-2.5 bg-[#0284C7] text-white text-xs font-bold rounded-xl hover:bg-[#0369a1] transition-all shadow">
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
        <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="showDeleteModal = false"></div>
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm z-10 p-6 text-center" @click.stop>
            <div class="w-14 h-14 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-7 h-7 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                </svg>
            </div>
            <h3 class="text-base font-bold text-slate-900 mb-1">Hapus Layanan?</h3>
            <p class="text-xs text-slate-500 mb-5">Layanan "<span class="font-semibold text-slate-700" x-text="deleteTarget?.nama"></span>" akan dihapus permanen dan tidak dapat dikembalikan.</p>
            <div class="flex gap-3">
                <button @click="showDeleteModal = false"
                    class="flex-1 py-2.5 bg-slate-100 text-slate-700 text-xs font-bold rounded-xl hover:bg-slate-200 transition-all">
                    Batal
                </button>
                <button @click="layanan = layanan.filter(l => l.id !== deleteTarget.id); showDeleteModal = false"
                    class="flex-1 py-2.5 bg-red-500 text-white text-xs font-bold rounded-xl hover:bg-red-600 transition-all shadow">
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
