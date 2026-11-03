@extends('layouts.admin')

@section('title', 'Kelola Pengguna & Verifikasi Teknisi - ACare Admin Portal')

@section('content')

<style>
    [x-cloak] { display: none !important; }

    /* Custom high fidelity badge styles */
    .badge-terverifikasi { background-color: #4ADE80; color: #ffffff; }
    .badge-menunggu      { background-color: #FBBF24; color: #ffffff; }
    .badge-ditolak       { background-color: #F87171; color: #ffffff; }
</style>

<script>
function initKelolaPengguna() {
    return {
        activeTabPeran: 'semua',
        filterStatus: 'semua',
        searchQuery: '',
        detailTab: 'verifikasi',
        selectedUser: {!! json_encode($selectedPengguna) !!},
        users: {!! json_encode($penggunaList) !!},

        previewModal: false,
        previewDoc: null,
        showRejectModal: false,
        showApproveModal: false,
        showRevokeModal: false,

        rejectPresets: [
            'Foto KTP buram, terpotong, atau NIK tidak terbaca jelas',
            'Sertifikat keahlian teknik AC belum dilampirkan atau kedaluwarsa',
            'Pas foto diri tidak sesuai ketentuan (wajib foto resmi)',
            'Surat pengalaman kerja tidak memiliki stempel atau tanda tangan resmi'
        ],
        selectedPresets: [],
        rejectNotes: '',

        toast: { show: false, message: '', type: 'success' },

        tampilkanToast(msg, type = 'success') {
            this.toast.message = msg;
            this.toast.type = type;
            this.toast.show = true;
            var self = this;
            setTimeout(function() { self.toast.show = false; }, 4000);
        },

        pilihUser(user) {
            this.selectedUser = user;
            if (user.peran.toLowerCase() === 'pengguna') {
                this.detailTab = 'data_pengguna';
            } else {
                this.detailTab = 'verifikasi';
            }
        },

        tampilkanPreview(doc) {
            this.previewDoc = doc;
            this.previewModal = true;
        },

        tandaiDokumen(status) {
            if (!this.previewDoc) return;
            this.previewDoc.status = status;
            if (status === 'valid') {
                this.previewDoc.catatan = 'Telah diperiksa: Berkas Asli & Valid';
                this.tampilkanToast('Dokumen ' + this.previewDoc.nama + ' ditandai Valid.', 'success');
            } else {
                this.previewDoc.catatan = 'Telah diperiksa: Perlu perbaikan / buram';
                this.tampilkanToast('Dokumen ' + this.previewDoc.nama + ' ditandai Tidak Valid.', 'warning');
            }
            this.previewModal = false;
        },

        bukaModalApprove() {
            this.showApproveModal = true;
        },

        prosesSetujuiTeknisi() {
            this.selectedUser.status_verifikasi = 'terverifikasi';
            this.selectedUser.alasan_penolakan = null;
            
            if (this.selectedUser.dokumen) {
                this.selectedUser.dokumen.forEach(function(d) {
                    d.status = 'valid';
                    d.catatan = 'Diverifikasi oleh Admin Operasional';
                });
            }

            var self = this;
            var idx = this.users.findIndex(function(u) { return u.id === self.selectedUser.id; });
            if (idx !== -1) {
                this.users[idx].status_verifikasi = 'terverifikasi';
                this.users[idx].dokumen = this.selectedUser.dokumen;
                this.users[idx].alasan_penolakan = null;
            }

            this.showApproveModal = false;
            this.tampilkanToast('Selamat! Teknisi ' + this.selectedUser.nama + ' berhasil diverifikasi & akun kini aktif menerima order.');
        },

        bukaModalTolak() {
            this.selectedPresets = [];
            this.rejectNotes = '';
            this.showRejectModal = true;
        },

        togglePreset(item) {
            if (this.selectedPresets.includes(item)) {
                this.selectedPresets = this.selectedPresets.filter(function(p) { return p !== item; });
            } else {
                this.selectedPresets.push(item);
            }
        },

        prosesTolakTeknisi() {
            if (this.selectedPresets.length === 0 && this.rejectNotes.trim() === '') {
                alert('Silakan pilih minimal 1 alasan penolakan atau isi catatan.');
                return;
            }

            var alasan = this.selectedPresets.join('. ');
            if (this.rejectNotes.trim() !== '') {
                alasan += (alasan ? '. ' : '') + this.rejectNotes.trim();
            }

            this.selectedUser.status_verifikasi = 'ditolak';
            this.selectedUser.alasan_penolakan = alasan;

            var self = this;
            var idx = this.users.findIndex(function(u) { return u.id === self.selectedUser.id; });
            if (idx !== -1) {
                this.users[idx].status_verifikasi = 'ditolak';
                this.users[idx].alasan_penolakan = alasan;
            }

            this.showRejectModal = false;
            this.tampilkanToast('Verifikasi teknisi ' + this.selectedUser.nama + ' telah ditolak dengan catatan perbaikan.', 'error');
        },

        cabutVerifikasi() {
            if (!confirm('Apakah Anda ingin mencabut verifikasi teknisi ' + this.selectedUser.nama + ' dan mengembalikannya ke status Menunggu?')) return;
            this.selectedUser.status_verifikasi = 'menunggu';
            var self = this;
            var idx = this.users.findIndex(function(u) { return u.id === self.selectedUser.id; });
            if (idx !== -1) {
                this.users[idx].status_verifikasi = 'menunggu';
            }
            this.tampilkanToast('Status verifikasi teknisi ' + this.selectedUser.nama + ' dikembalikan ke Menunggu.');
        },

        tinjauUlang() {
            this.selectedUser.status_verifikasi = 'menunggu';
            var self = this;
            var idx = this.users.findIndex(function(u) { return u.id === self.selectedUser.id; });
            if (idx !== -1) {
                this.users[idx].status_verifikasi = 'menunggu';
            }
            this.tampilkanToast('Pengajuan teknisi ' + this.selectedUser.nama + ' dibuka kembali untuk ditinjau ulang.');
        },

        get filteredUsers() {
            var self = this;
            return this.users.filter(function(user) {
                if (self.activeTabPeran === 'teknisi' && user.peran.toLowerCase() !== 'teknisi') return false;
                if (self.activeTabPeran === 'pengguna' && user.peran.toLowerCase() !== 'pengguna') return false;

                if (self.filterStatus !== 'semua' && user.status_verifikasi !== self.filterStatus) return false;

                if (self.searchQuery.trim() !== '') {
                    var q = self.searchQuery.toLowerCase();
                    var match = user.nama.toLowerCase().includes(q) ||
                                user.email.toLowerCase().includes(q) ||
                                user.telepon.includes(q) ||
                                user.id.toLowerCase().includes(q) ||
                                (user.alamat && user.alamat.toLowerCase().includes(q));
                    if (!match) return false;
                }

                return true;
            });
        },

        get hitungTeknisiMenunggu() {
            return this.users.filter(function(u) { return u.peran === 'Teknisi' && u.status_verifikasi === 'menunggu'; }).length;
        }
    };
}
</script>

<div x-data="initKelolaPengguna()" class="p-8">

    <!-- Toast Notification Popup -->
    <div x-show="toast.show"
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0 transform translate-y-4"
         x-transition:enter-end="opacity-100 transform translate-y-0"
         x-transition:leave="transition ease-in duration-200"
         x-transition:leave-start="opacity-100 transform translate-y-0"
         x-transition:leave-end="opacity-0 transform translate-y-4"
         class="fixed bottom-6 right-6 z-50 px-5 py-3.5 rounded-2xl shadow-2xl flex items-center gap-3 border text-xs font-semibold"
         :class="{
             'bg-slate-900 text-white border-slate-700': toast.type === 'success',
             'bg-amber-900 text-amber-100 border-amber-700': toast.type === 'warning',
             'bg-rose-900 text-rose-100 border-rose-700': toast.type === 'error'
         }"
         style="display: none;">
        <template x-if="toast.type === 'success'">
            <svg class="w-5 h-5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
        </template>
        <template x-if="toast.type === 'warning' || toast.type === 'error'">
            <svg class="w-5 h-5 text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
            </svg>
        </template>
        <span x-text="toast.message"></span>
    </div>

    <!-- Breadcrumb: Beranda > Kelola Pengguna (Sesuai Figma) -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-400 mb-2">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-[#0284C7] transition-colors flex items-center gap-1">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            Beranda
        </a>
        <span>&gt;</span>
        <span class="text-slate-600 font-semibold">Kelola Pengguna</span>
    </div>

    <!-- Title & Subtitle sesuai Figma -->
    <div class="mb-5 flex items-center justify-between">
        <div>
            <h1 class="text-xl font-extrabold text-slate-900 tracking-tight">Kelola Pengguna</h1>
            <p class="text-xs text-slate-400 font-medium mt-0.5">Kelola Pengguna aplikasi ACare, termasuk verifikasi teknisi layanan AC.</p>
        </div>
        <div class="flex items-center gap-2">
            <span class="text-xs font-bold text-slate-500">Menunggu Verifikasi:</span>
            <span class="px-2.5 py-1 rounded-full bg-amber-100 text-amber-800 text-xs font-black" x-text="hitungTeknisiMenunggu + ' Teknisi'"></span>
        </div>
    </div>

    <!-- MAIN GRID 2 KOLOM (KIRI TABEL 8 KOLOM, KANAN PANEL VERIFIKASI 4 KOLOM) -->
    <div class="grid grid-cols-12 gap-6 items-start">

        <!-- ================= BAGIAN TENGAH / KIRI: TABEL PENGGUNA (8 COLS) ================= -->
        <div class="col-span-12 lg:col-span-8 space-y-4">

            <!-- Filter Tabs Kategori Sesuai Figma -->
            <div class="flex items-center justify-between border-b border-slate-200 pb-1">
                <div class="flex items-center gap-6">
                    <!-- Tab: Semua Pengguna (243) -->
                    <button @click="activeTabPeran = 'semua'"
                            :class="activeTabPeran === 'semua' ? 'text-[#0284C7] font-bold border-b-2 border-[#0284C7] pb-2' : 'text-slate-400 font-medium hover:text-slate-700 pb-2'"
                            class="text-xs flex items-center gap-2 transition-all">
                        <span>Semua Pengguna</span>
                        <span :class="activeTabPeran === 'semua' ? 'bg-sky-100 text-[#0284C7]' : 'bg-slate-100 text-slate-500'"
                              class="text-[10px] px-2 py-0.5 rounded-full font-bold">243</span>
                    </button>

                    <!-- Tab: Teknisi (15) -->
                    <button @click="activeTabPeran = 'teknisi'"
                            :class="activeTabPeran === 'teknisi' ? 'text-[#0284C7] font-bold border-b-2 border-[#0284C7] pb-2' : 'text-slate-400 font-medium hover:text-slate-700 pb-2'"
                            class="text-xs flex items-center gap-2 transition-all">
                        <span>Teknisi</span>
                        <span :class="activeTabPeran === 'teknisi' ? 'bg-sky-100 text-[#0284C7]' : 'bg-slate-100 text-slate-500'"
                              class="text-[10px] px-2 py-0.5 rounded-full font-bold">15</span>
                    </button>

                    <!-- Tab: Pengguna (228) -->
                    <button @click="activeTabPeran = 'pengguna'"
                            :class="activeTabPeran === 'pengguna' ? 'text-[#0284C7] font-bold border-b-2 border-[#0284C7] pb-2' : 'text-slate-400 font-medium hover:text-slate-700 pb-2'"
                            class="text-xs flex items-center gap-2 transition-all">
                        <span>Pengguna</span>
                        <span :class="activeTabPeran === 'pengguna' ? 'bg-sky-100 text-[#0284C7]' : 'bg-slate-100 text-slate-500'"
                              class="text-[10px] px-2 py-0.5 rounded-full font-bold">228</span>
                    </button>
                </div>
            </div>

            <!-- Baris Filter Dropdown & Search Bar -->
            <div class="flex items-center justify-between gap-3">
                <div class="flex items-center gap-3">
                    <!-- Dropdown Status -->
                    <div class="relative">
                        <select x-model="filterStatus"
                                class="appearance-none bg-white border border-slate-300 rounded-xl px-4 py-2 pr-9 text-xs font-semibold text-slate-700 hover:border-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0284C7] cursor-pointer shadow-sm">
                            <option value="semua">Semua Status</option>
                            <option value="menunggu">Menunggu Verifikasi</option>
                            <option value="terverifikasi">Terverifikasi</option>
                            <option value="ditolak">Ditolak</option>
                        </select>
                        <div class="absolute inset-y-0 right-0 flex items-center pr-2.5 pointer-events-none text-slate-400">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </div>
                    </div>

                    <!-- Dropdown Tanggal Daftar -->
                    <div class="relative">
                        <button class="flex items-center gap-2 bg-white border border-slate-300 rounded-xl px-4 py-2 text-xs font-semibold text-slate-700 hover:border-slate-400 shadow-sm">
                            <svg class="w-3.5 h-3.5 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            <span>Tanggal Daftar</span>
                            <svg class="w-3.5 h-3.5 text-slate-400 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </button>
                    </div>
                </div>

                <!-- Input Pencarian Cepat Tabel -->
                <div class="relative w-64">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                    </span>
                    <input type="text"
                           x-model="searchQuery"
                           placeholder="Filter nama, ID, atau kontak..."
                           class="w-full pl-9 pr-3 py-1.5 bg-white border border-slate-300 rounded-xl text-xs font-medium text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0284C7] shadow-sm">
                </div>
            </div>

            <!-- TABEL DATA PENGGUNA SESUAI FIGMA DENGAN HEADER PASTEL -->
            <div class="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-[#EBF2FC] text-[11px] font-bold text-slate-600">
                            <th class="py-3 px-5">Nama</th>
                            <th class="py-3 px-4">Peran</th>
                            <th class="py-3 px-4">Kontak</th>
                            <th class="py-3 px-4">Status Verifikasi</th>
                            <th class="py-3 px-5 text-right">Tanggal Daftar</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 text-xs">
                        <template x-for="user in filteredUsers" :key="user.id">
                            <tr @click="pilihUser(user)"
                                :class="selectedUser.id === user.id ? 'bg-sky-50/80 border-l-4 border-[#0284C7]' : 'hover:bg-slate-50/80'"
                                class="cursor-pointer transition-colors group">
                                
                                <!-- Kolom Nama & Avatar Bulat Abu-abu Polos Sesuai Figma -->
                                <td class="py-3.5 px-5">
                                    <div class="flex items-center gap-3">
                                        <div class="w-9 h-9 rounded-full bg-[#D1D5DB] text-slate-600 flex items-center justify-center font-bold text-xs flex-shrink-0">
                                            <span x-text="user.nama.charAt(0)"></span>
                                        </div>
                                        <div>
                                            <div class="flex items-center gap-1.5">
                                                <p class="font-bold text-slate-800" x-text="user.nama"></p>
                                                <template x-if="user.status_verifikasi === 'menunggu'">
                                                    <span class="w-2 h-2 rounded-full bg-amber-400 animate-pulse" title="Perlu Verifikasi"></span>
                                                </template>
                                            </div>
                                            <p class="text-[10px] text-slate-400 font-medium" x-text="'ID : ' + user.id"></p>
                                        </div>
                                    </div>
                                </td>

                                <!-- Kolom Peran -->
                                <td class="py-3.5 px-4 text-slate-600 font-medium">
                                    <span :class="user.peran === 'Teknisi' ? 'text-sky-700 font-bold' : 'text-slate-600'" x-text="user.peran"></span>
                                </td>

                                <!-- Kolom Kontak dengan Ikon Telepon -->
                                <td class="py-3.5 px-4 text-slate-600 font-medium">
                                    <div class="flex items-center gap-1.5">
                                        <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                        </svg>
                                        <span x-text="user.telepon"></span>
                                    </div>
                                </td>

                                <!-- Kolom Status Verifikasi Badge Sesuai Figma -->
                                <td class="py-3.5 px-4">
                                    <template x-if="user.status_verifikasi === 'terverifikasi'">
                                        <span class="inline-block px-3 py-1 rounded-full text-[10px] font-semibold bg-[#4ADE80] text-white">
                                            Terverifikasi
                                        </span>
                                    </template>
                                    <template x-if="user.status_verifikasi === 'menunggu'">
                                        <span class="inline-block px-3 py-1 rounded-full text-[10px] font-semibold bg-[#FBBF24] text-white">
                                            Menunggu Verifikasi
                                        </span>
                                    </template>
                                    <template x-if="user.status_verifikasi === 'ditolak'">
                                        <span class="inline-block px-3 py-1 rounded-full text-[10px] font-semibold bg-[#F87171] text-white">
                                            Ditolak
                                        </span>
                                    </template>
                                </td>

                                <!-- Kolom Tanggal Daftar (2 Baris Sesuai Figma) -->
                                <td class="py-3.5 px-5 text-right font-medium text-[11px] text-slate-500">
                                    <p class="leading-tight" x-text="user.tanggal_daftar.split(' ')[0] + ' ' + user.tanggal_daftar.split(' ')[1] + ' ' + user.tanggal_daftar.split(' ')[2]"></p>
                                    <p class="text-[10px] text-slate-400" x-text="user.tanggal_daftar.split(' ')[3] || '12:25'"></p>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>

        </div>

        <!-- ================= BAGIAN KANAN: PANEL DETAIL & VERIFIKASI (4 COLS) ================= -->
        <div class="col-span-12 lg:col-span-4 bg-white rounded-2xl border border-slate-200 p-5 shadow-sm sticky top-6">

            <!-- Judul Panel Kanan -->
            <h2 class="text-xs font-bold text-slate-900 tracking-tight mb-3">
                <span x-show="selectedUser.peran === 'Teknisi'">Data Pengguna &amp; Verifikasi Teknisi</span>
                <span x-show="selectedUser.peran === 'Pengguna'">Detail Informasi Pelanggan</span>
            </h2>

            <!-- Profil User Header (Card dengan Border sesuai Figma GanAnWo) -->
            <div class="border border-slate-200 rounded-xl p-4 mb-4">
                <div class="flex items-start gap-4">
                    <!-- Avatar Bulat Abu-abu Polos Sesuai Figma -->
                    <div class="w-16 h-16 rounded-full bg-[#D1D5DB] flex items-center justify-center font-bold text-slate-600 text-xl flex-shrink-0">
                        <span x-text="selectedUser.nama ? selectedUser.nama.charAt(0) : 'U'"></span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h3 class="text-base font-extrabold text-slate-900 truncate" x-text="selectedUser.nama"></h3>
                        <div class="mt-1 flex items-center gap-1.5">
                            <span class="text-[10px] font-semibold px-2.5 py-0.5 rounded-full bg-[#93C5FD] text-white" x-text="selectedUser.peran"></span>
                            <template x-if="selectedUser.status_verifikasi === 'terverifikasi'">
                                <span class="text-[9px] font-bold px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">Aktif</span>
                            </template>
                            <template x-if="selectedUser.status_verifikasi === 'menunggu'">
                                <span class="text-[9px] font-bold px-2 py-0.5 rounded-full bg-amber-100 text-amber-800">Pending</span>
                            </template>
                            <template x-if="selectedUser.status_verifikasi === 'ditolak'">
                                <span class="text-[9px] font-bold px-2 py-0.5 rounded-full bg-rose-100 text-rose-800">Ditolak</span>
                            </template>
                        </div>
                        <p class="text-[11px] text-slate-400 font-medium mt-1.5" x-text="'ID : ' + selectedUser.id"></p>
                        <p class="text-[11px] text-slate-600 font-medium mt-0.5 flex items-center gap-1.5">
                            <svg class="w-3 h-3 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                            </svg>
                            <span x-text="selectedUser.telepon"></span>
                        </p>
                        <p class="text-[11px] text-slate-500 truncate mt-0.5 flex items-center gap-1">
                            <svg class="w-3 h-3 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                            </svg>
                            <span x-text="selectedUser.alamat"></span>
                        </p>
                    </div>
                </div>
            </div>

            <!-- Tab Sub Menu: Sesuai Peran -->
            <template x-if="selectedUser.peran === 'Teknisi'">
                <div class="flex border-b border-slate-200 mb-4 text-xs font-semibold">
                    <button @click="detailTab = 'data_pengguna'"
                            :class="detailTab === 'data_pengguna' ? 'text-[#0284C7] border-b-2 border-[#0284C7] pb-2' : 'text-slate-400 hover:text-slate-600 pb-2'"
                            class="mr-6 transition-all">
                        Data Pengguna
                    </button>
                    <button @click="detailTab = 'verifikasi'"
                            :class="detailTab === 'verifikasi' ? 'text-[#0284C7] border-b-2 border-[#0284C7] pb-2' : 'text-slate-400 hover:text-slate-600 pb-2'"
                            class="pb-2 transition-all flex items-center gap-1.5">
                        <span>Verifikasi Teknisi</span>
                        <template x-if="selectedUser.status_verifikasi === 'menunggu'">
                            <span class="w-2 h-2 rounded-full bg-amber-500"></span>
                        </template>
                    </button>
                </div>
            </template>

            <!-- ISI TAB 1: DATA PENGGUNA (TEKNISI / PELANGGAN) -->
            <div x-show="detailTab === 'data_pengguna'" class="space-y-3 text-xs">
                <div class="bg-slate-50 p-3.5 rounded-xl border border-slate-100 space-y-2.5">
                    <div>
                        <span class="text-slate-400 text-[10px] block">Email Terdaftar</span>
                        <span class="font-bold text-slate-800" x-text="selectedUser.email"></span>
                    </div>
                    <div>
                        <span class="text-slate-400 text-[10px] block">Nomor WhatsApp / Kontak</span>
                        <span class="font-bold text-slate-800" x-text="selectedUser.telepon"></span>
                    </div>
                    <div>
                        <span class="text-slate-400 text-[10px] block">Alamat Domisili</span>
                        <span class="font-bold text-slate-800" x-text="selectedUser.alamat"></span>
                    </div>
                    <template x-if="selectedUser.peran === 'Teknisi'">
                        <div>
                            <span class="text-slate-400 text-[10px] block">Kendaraan Operasional</span>
                            <span class="font-bold text-slate-800" x-text="selectedUser.kendaraan || 'Tidak ada data kendaraan'"></span>
                        </div>
                    </template>
                    <template x-if="selectedUser.peran === 'Teknisi' && selectedUser.keahlian">
                        <div>
                            <span class="text-slate-400 text-[10px] block">Keahlian &amp; Spesialisasi</span>
                            <span class="font-bold text-slate-800" x-text="selectedUser.keahlian"></span>
                        </div>
                    </template>
                </div>

                <!-- Jika Pelanggan Biasa: Tampilkan Riwayat Pesanan AC -->
                <template x-if="selectedUser.peran === 'Pengguna'">
                    <div class="mt-4">
                        <p class="text-[11px] font-bold text-slate-900 mb-2">Riwayat Pesanan Servis AC</p>
                        <div class="border border-slate-200 rounded-xl divide-y divide-slate-100 overflow-hidden bg-white">
                            <template x-for="ord in (selectedUser.riwayat_order || [])" :key="ord.id">
                                <div class="p-3 text-xs">
                                    <div class="flex items-center justify-between mb-1">
                                        <span class="font-bold text-slate-800" x-text="ord.layanan"></span>
                                        <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-emerald-100 text-emerald-700" x-text="ord.status"></span>
                                    </div>
                                    <div class="flex items-center justify-between text-[10px] text-slate-400">
                                        <span x-text="'Teknisi: ' + ord.teknisi"></span>
                                        <span class="font-bold text-slate-700" x-text="ord.biaya"></span>
                                    </div>
                                </div>
                            </template>
                        </div>
                    </div>
                </template>
            </div>

            <!-- ISI TAB 2: VERIFIKASI TEKNISI (SESUAI GAMBAR FIGMA DENGAN ALUR LENGKAP) -->
            <div x-show="detailTab === 'verifikasi' && selectedUser.peran === 'Teknisi'" class="space-y-4">

                <!-- 1. ALERT BOX STATUS VERIFIKASI -->
                <div>
                    <p class="text-[11px] font-bold text-slate-900 mb-1.5">Status Verifikasi</p>
                    
                    <!-- Kondisi 1: Menunggu Verifikasi (Banner Kuning Sesuai Figma) -->
                    <template x-if="selectedUser.status_verifikasi === 'menunggu'">
                        <div class="bg-[#FEF3C7]/80 border border-[#FDE68A] p-3 rounded-xl flex items-start gap-2.5">
                            <div class="w-6 h-6 rounded-full bg-amber-200/80 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <svg class="w-3.5 h-3.5 text-amber-700" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <div class="flex items-center justify-between">
                                    <p class="text-xs font-bold text-amber-900">Menunggu Verifikasi</p>
                                    <span class="text-[9px] text-amber-700 font-medium" x-text="'Sejak ' + (selectedUser.sejak_tanggal || '12 Sept 2026')"></span>
                                </div>
                                <p class="text-[10px] text-amber-800 mt-0.5 leading-snug">Data teknisi belum dicek. Silakan tinjau berkas kelengkapan di bawah.</p>
                            </div>
                        </div>
                    </template>

                    <!-- Kondisi 2: Terverifikasi (Banner Hijau) -->
                    <template x-if="selectedUser.status_verifikasi === 'terverifikasi'">
                        <div class="bg-emerald-50 border border-emerald-200 p-3 rounded-xl flex items-start gap-2.5">
                            <div class="w-6 h-6 rounded-full bg-emerald-200 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <svg class="w-3.5 h-3.5 text-emerald-800" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <div class="flex items-center justify-between">
                                    <p class="text-xs font-bold text-emerald-900">Teknisi Terverifikasi</p>
                                    <span class="text-[9px] text-emerald-700 font-medium">Akun Aktif</span>
                                </div>
                                <p class="text-[10px] text-emerald-800 mt-0.5 leading-snug">Seluruh berkas identitas &amp; keahlian telah disetujui. Teknisi dapat menerima order servis AC.</p>
                            </div>
                        </div>
                    </template>

                    <!-- Kondisi 3: Ditolak (Banner Merah) -->
                    <template x-if="selectedUser.status_verifikasi === 'ditolak'">
                        <div class="bg-rose-50 border border-rose-200 p-3 rounded-xl flex items-start gap-2.5">
                            <div class="w-6 h-6 rounded-full bg-rose-200 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <svg class="w-3.5 h-3.5 text-rose-800" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <div class="flex items-center justify-between">
                                    <p class="text-xs font-bold text-rose-900">Verifikasi Ditolak</p>
                                    <span class="text-[9px] text-rose-700 font-medium">Perlu Revisi</span>
                                </div>
                                <p class="text-[10px] text-rose-800 mt-0.5 leading-snug" x-text="selectedUser.alasan_penolakan || 'Berkas tidak memenuhi syarat kelayakan teknisi.'"></p>
                            </div>
                        </div>
                    </template>
                </div>

                <!-- 2. DAFTAR DOKUMEN CHECKLIST (KTP, Ijazah, Foto Diri, Surat Kerja) SESUAI FIGMA -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <p class="text-[11px] font-bold text-slate-900">Data Verifikasi</p>
                        <span class="text-[10px] text-slate-400">Klik "Lihat" untuk memeriksa</span>
                    </div>

                    <div class="border border-slate-200 rounded-xl divide-y divide-slate-100 overflow-hidden bg-white">
                        <template x-for="doc in (selectedUser.dokumen || [])" :key="doc.nama">
                            <div class="p-3 flex items-center justify-between hover:bg-slate-50 transition-colors">
                                <div class="flex items-center gap-2.5">
                                    <!-- Status Indicator Dot -->
                                    <template x-if="doc.status === 'valid'">
                                        <div class="w-5 h-5 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0" title="Dokumen Valid">
                                            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
                                            </svg>
                                        </div>
                                    </template>
                                    <template x-if="doc.status === 'tidak_valid'">
                                        <div class="w-5 h-5 rounded-full bg-rose-100 text-rose-600 flex items-center justify-center flex-shrink-0" title="Dokumen Tidak Valid">
                                            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M6 18L18 6M6 6l12 12"/>
                                            </svg>
                                        </div>
                                    </template>
                                    <template x-if="doc.status === 'menunggu' || !doc.status">
                                        <div class="w-5 h-5 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center flex-shrink-0" title="Belum Diperiksa">
                                            <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                                        </div>
                                    </template>

                                    <div>
                                        <p class="text-xs font-bold text-slate-800" x-text="doc.nama"></p>
                                        <p class="text-[10px] text-slate-400 font-mono" x-text="doc.file"></p>
                                    </div>
                                </div>
                                <div>
                                    <button @click="tampilkanPreview(doc)"
                                            class="px-3 py-1 text-[11px] font-semibold text-[#16A34A] border border-[#86EFAC] bg-[#F0FDF4] rounded-full hover:bg-[#DCFCE7] transition-all">
                                        Lihat
                                    </button>
                                </div>
                            </div>
                        </template>
                    </div>
                </div>

                <!-- 3. TOMBOL AKSI ALUR VERIFIKASI (Tolak & Setujui) -->
                <div class="pt-2">

                    <!-- Skenario A: Jika Status Menunggu Verifikasi -->
                    <template x-if="selectedUser.status_verifikasi === 'menunggu'">
                        <div class="flex items-center gap-3">
                            <button @click="bukaModalTolak()"
                                    class="flex-1 py-2.5 px-3 rounded-xl border border-rose-300 text-rose-600 font-bold text-xs hover:bg-rose-50 transition-all flex items-center justify-center gap-1.5">
                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                </svg>
                                <span>Tolak</span>
                            </button>
                            <button @click="bukaModalApprove()"
                                    class="flex-[2] py-2.5 px-3 rounded-xl bg-[#0284C7] hover:bg-sky-700 text-white font-bold text-xs shadow-md shadow-sky-500/20 transition-all flex items-center justify-center gap-1.5">
                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span>Setujui Verifikasi</span>
                            </button>
                        </div>
                    </template>

                    <!-- Skenario B: Jika Status Sudah Terverifikasi -->
                    <template x-if="selectedUser.status_verifikasi === 'terverifikasi'">
                        <div class="space-y-2">
                            <div class="w-full py-2 px-3 bg-emerald-100/70 border border-emerald-300 text-emerald-800 rounded-xl text-center font-bold text-xs flex items-center justify-center gap-1.5">
                                <svg class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                <span>Teknisi Telah Terverifikasi &amp; Aktif</span>
                            </div>
                            <button @click="cabutVerifikasi()"
                                    class="w-full py-2 text-center text-xs font-semibold text-slate-500 hover:text-rose-600 hover:underline transition-all">
                                Cabut Status Verifikasi / Nonaktifkan
                            </button>
                        </div>
                    </template>

                    <!-- Skenario C: Jika Status Ditolak -->
                    <template x-if="selectedUser.status_verifikasi === 'ditolak'">
                        <div class="space-y-2">
                            <button @click="tinjauUlang()"
                                    class="w-full py-2.5 px-3 bg-[#0284C7] hover:bg-sky-700 text-white font-bold text-xs rounded-xl shadow transition-all flex items-center justify-center gap-1.5">
                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                </svg>
                                <span>Buka Ulang Pengajuan (Tinjau Ulang)</span>
                            </button>
                        </div>
                    </template>

                </div>

            </div>

        </div>

    </div>

    <!-- ===================== 1. MODAL PREVIEW DOKUMEN REALISTIS ===================== -->
    <div x-show="previewModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4"
         style="display: none;">
        <div @click.away="previewModal = false"
             class="bg-white rounded-2xl max-w-lg w-full overflow-hidden shadow-2xl border border-slate-200 transform transition-all">
            
            <!-- Header Modal -->
            <div class="bg-[#0284C7] text-white p-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <svg class="w-4 h-4 text-sky-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <span class="text-xs font-bold tracking-wide" x-text="'TINJAUAN BERKAS: ' + (previewDoc ? previewDoc.nama : '')"></span>
                </div>
                <button @click="previewModal = false" class="text-sky-100 hover:text-white p-1">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <!-- Body Modal Mockup Dokumen Realistis -->
            <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                    <div>
                        <h4 class="text-sm font-extrabold text-slate-800" x-text="previewDoc ? previewDoc.file : ''"></h4>
                        <p class="text-[11px] text-slate-400" x-text="previewDoc ? previewDoc.deskripsi : ''"></p>
                    </div>
                    <template x-if="previewDoc && previewDoc.status === 'valid'">
                        <span class="px-2.5 py-1 text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-300 rounded-md">✓ STATUS: VALID</span>
                    </template>
                    <template x-if="previewDoc && previewDoc.status === 'tidak_valid'">
                        <span class="px-2.5 py-1 text-[10px] font-bold bg-rose-50 text-rose-700 border border-rose-300 rounded-md">✗ STATUS: TIDAK VALID</span>
                    </template>
                    <template x-if="!previewDoc || previewDoc.status === 'menunggu'">
                        <span class="px-2.5 py-1 text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-300 rounded-md">⏳ PERLU TINJAUAN</span>
                    </template>
                </div>

                <!-- Tampilan Visual Dokumen Sesuai Tipe Dokumen -->
                <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                    
                    <!-- Dokumen KTP Mockup -->
                    <template x-if="previewDoc && previewDoc.id === 'ktp'">
                        <div class="bg-gradient-to-br from-sky-100 via-sky-50 to-blue-100 rounded-xl p-4 border border-sky-300 text-slate-800 shadow-inner">
                            <div class="text-center pb-2 border-b border-sky-200 mb-3">
                                <p class="text-[10px] font-black uppercase tracking-wider text-slate-800">REPUBLIK INDONESIA</p>
                                <p class="text-[8px] font-bold text-sky-900 uppercase">KARTU TANDA PENDUDUK</p>
                            </div>
                            <div class="flex gap-3 items-center">
                                <div class="w-20 h-24 bg-slate-300 rounded-lg flex items-center justify-center font-bold text-slate-500 border border-slate-400 flex-shrink-0 text-center p-1 text-[9px]">
                                    [FOTO KTP ASLI]
                                </div>
                                <div class="text-[10px] space-y-0.5 leading-tight flex-1">
                                    <p><span class="font-bold">NIK :</span> 2171012304950001</p>
                                    <p><span class="font-bold">Nama :</span> <span x-text="selectedUser.nama"></span></p>
                                    <p><span class="font-bold">Tempat/Tgl Lahir :</span> Batam, 15-08-1996</p>
                                    <p><span class="font-bold">Alamat :</span> <span x-text="selectedUser.alamat"></span></p>
                                    <p><span class="font-bold">Pekerjaan :</span> Teknisi AC / Pendingin</p>
                                    <p><span class="font-bold">Berlaku Hingga :</span> SEUMUR HIDUP</p>
                                </div>
                            </div>
                        </div>
                    </template>

                    <!-- Dokumen Ijazah / Sertifikat BNSP -->
                    <template x-if="previewDoc && previewDoc.id === 'ijazah'">
                        <div class="bg-amber-50/60 rounded-xl p-4 border-2 border-amber-300 text-slate-800 shadow-inner text-center">
                            <div class="w-10 h-10 mx-auto rounded-full bg-amber-500 text-white flex items-center justify-center font-bold text-xs mb-1 shadow">
                                BNSP
                            </div>
                            <p class="text-xs font-black uppercase tracking-wider text-amber-900">SERTIFIKAT KOMPETENSI TEKNISI AC</p>
                            <p class="text-[9px] text-slate-500 font-mono mt-0.5">No. Reg: BNSP-AC-2026-88741</p>
                            <div class="mt-3 text-[11px] text-slate-700 leading-relaxed">
                                Diberikan kepada: <br>
                                <strong class="text-slate-900 text-xs" x-text="selectedUser.nama"></strong><br>
                                Dinyatakan <strong class="text-emerald-700">KOMPETEN</strong> dalam bidang:<br>
                                <em>Pemeliharaan, Perbaikan, dan Pengisian Freon Unit Tata Udara (AC Split)</em>
                            </div>
                        </div>
                    </template>

                    <!-- Dokumen Foto Diri -->
                    <template x-if="previewDoc && previewDoc.id === 'foto'">
                        <div class="bg-white rounded-xl p-4 border border-slate-200 text-center shadow-inner">
                            <div class="w-28 h-36 mx-auto bg-slate-200 rounded-lg border-2 border-slate-300 flex flex-col items-center justify-center text-slate-500 p-2 shadow-sm mb-2">
                                <svg class="w-12 h-12 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                                </svg>
                                <span class="text-[9px] font-bold mt-1">PAS FOTO 4x6</span>
                            </div>
                            <p class="text-xs font-bold text-slate-800" x-text="selectedUser.nama"></p>
                            <p class="text-[10px] text-slate-400">Identitas Foto Profil Teknisi Resmi ACare</p>
                        </div>
                    </template>

                    <!-- Dokumen Surat Keterangan Kerja -->
                    <template x-if="previewDoc && previewDoc.id === 'surat_kerja'">
                        <div class="bg-white rounded-xl p-4 border border-slate-300 text-left shadow-inner font-serif text-[10px] text-slate-800 space-y-1.5">
                            <div class="border-b-2 border-slate-900 pb-1 text-center font-sans">
                                <p class="font-extrabold text-xs uppercase tracking-wide">CV BERKAH DINGIN SEJAHTERA</p>
                                <p class="text-[8px] text-slate-500">Jl. Pahlawan No. 45, Batam Center • Telp: (0778) 465123</p>
                            </div>
                            <p class="text-center font-bold text-[11px] underline pt-1 font-sans">SURAT KETERANGAN PENGALAMAN KERJA</p>
                            <p class="pt-1">Menerangkan bahwa:</p>
                            <p class="pl-3">Nama: <strong x-text="selectedUser.nama"></strong></p>
                            <p class="pl-3">Posisi: Teknisi Senior Servis &amp; Perawatan AC</p>
                            <p>Telah bekerja sejak tahun 2023 hingga sekarang dengan catatan kinerja sangat baik dan kompeten.</p>
                        </div>
                    </template>

                </div>

                <!-- Tombol Aksi Pemeriksaan Dokumen (Tandai Valid / Tidak Valid) -->
                <div class="mt-5 flex items-center justify-between gap-3 border-t border-slate-100 pt-4">
                    <button @click="tandaiDokumen('tidak_valid')"
                            class="px-4 py-2 rounded-xl border border-rose-300 text-rose-600 hover:bg-rose-50 text-xs font-bold transition-colors flex items-center gap-1.5">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                        <span>Tandai Tidak Valid / Buram</span>
                    </button>
                    <button @click="tandaiDokumen('valid')"
                            class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-colors shadow flex items-center gap-1.5">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                        </svg>
                        <span>Tandai Dokumen Valid</span>
                    </button>
                </div>
            </div>

        </div>
    </div>

    <!-- ===================== 2. MODAL PENOLAKAN DENGAN FORM ALASAN LENGKAP ===================== -->
    <div x-show="showRejectModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4"
         style="display: none;">
        <div @click.away="showRejectModal = false"
             class="bg-white rounded-2xl max-w-md w-full overflow-hidden shadow-2xl border border-slate-200">
            
            <div class="bg-rose-600 text-white p-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <svg class="w-5 h-5 text-rose-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                    </svg>
                    <h3 class="text-sm font-bold">Penolakan Verifikasi Teknisi</h3>
                </div>
                <button @click="showRejectModal = false" class="text-rose-100 hover:text-white">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <div class="p-5 text-xs text-slate-700">
                <p class="font-bold text-slate-900 mb-1">
                    Tolak pengajuan berkas: <span class="text-rose-600" x-text="selectedUser.nama"></span>
                </p>
                <p class="text-[11px] text-slate-500 mb-4">
                    Pilih alasan penolakan agar teknisi mengetahui dokumen mana yang harus diperbaiki &amp; diunggah ulang:
                </p>

                <!-- Checkbox Alasan Penolakan Preset -->
                <div class="space-y-2 mb-4">
                    <template x-for="preset in rejectPresets" :key="preset">
                        <label class="flex items-start gap-2.5 p-2 rounded-lg border border-slate-200 hover:bg-slate-50 cursor-pointer transition-colors">
                            <input type="checkbox"
                                   :value="preset"
                                   :checked="selectedPresets.includes(preset)"
                                   @change="togglePreset(preset)"
                                   class="mt-0.5 rounded text-rose-600 focus:ring-rose-500">
                            <span class="text-[11px] font-medium text-slate-700" x-text="preset"></span>
                        </label>
                    </template>
                </div>

                <!-- Input Catatan Tambahan -->
                <div>
                    <label class="block text-[11px] font-bold text-slate-700 mb-1">Catatan Tambahan untuk Teknisi (Opsional):</label>
                    <textarea x-model="rejectNotes"
                              rows="2"
                              placeholder="Contoh: Mohon foto ulang KTP dengan pencahayaan terang..."
                              class="w-full p-2.5 border border-slate-300 rounded-xl text-xs focus:ring-1 focus:ring-rose-500 focus:outline-none"></textarea>
                </div>

                <div class="mt-5 flex justify-end gap-2.5 border-t border-slate-100 pt-3">
                    <button @click="showRejectModal = false"
                            class="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold transition-colors">
                        Batal
                    </button>
                    <button @click="prosesTolakTeknisi()"
                            class="px-5 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold transition-colors shadow">
                        Kirim Keputusan Penolakan
                    </button>
                </div>
            </div>

        </div>
    </div>

    <!-- ===================== 3. MODAL PERSETUJUAN VERIFIKASI ===================== -->
    <div x-show="showApproveModal"
         x-transition.opacity
         class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4"
         style="display: none;">
        <div @click.away="showApproveModal = false"
             class="bg-white rounded-2xl max-w-sm w-full overflow-hidden shadow-2xl border border-slate-200 p-6 text-center">
            
            <div class="w-14 h-14 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-3 text-emerald-600">
                <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                </svg>
            </div>

            <h3 class="text-base font-extrabold text-slate-900 mb-1">Setujui Verifikasi Teknisi?</h3>
            <p class="text-xs text-slate-500 leading-relaxed mb-4">
                Anda akan menyetujui berkas identitas dan keahlian teknisi <strong class="text-slate-800" x-text="selectedUser.nama"></strong>. Akun teknisi akan langsung aktif di aplikasi mobile ACare.
            </p>

            <div class="bg-slate-50 rounded-xl p-3 text-left text-[11px] space-y-1 mb-5 border border-slate-200">
                <p><span class="text-slate-400">ID Teknisi:</span> <span class="font-bold text-slate-800" x-text="selectedUser.id"></span></p>
                <p><span class="text-slate-400">Keahlian:</span> <span class="font-bold text-slate-800" x-text="selectedUser.keahlian || 'Servis AC ACare'"></span></p>
                <p><span class="text-slate-400">Domisili:</span> <span class="font-bold text-slate-800" x-text="selectedUser.alamat"></span></p>
            </div>

            <div class="flex items-center gap-2.5">
                <button @click="showApproveModal = false"
                        class="flex-1 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-colors">
                    Batal
                </button>
                <button @click="prosesSetujuiTeknisi()"
                        class="flex-[1.5] py-2.5 rounded-xl bg-[#0284C7] hover:bg-sky-700 text-white text-xs font-bold shadow-md shadow-sky-500/20 transition-colors">
                    Ya, Setujui &amp; Aktifkan
                </button>
            </div>

        </div>
    </div>

</div>

@endsection
