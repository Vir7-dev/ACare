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
        filterStatus: {!! json_encode($statusAwal) !!},
        searchQuery: {!! json_encode((string) request('q', '')) !!},
        urutan: 'terbaru',
        halaman: 1,
        perHalaman: 10,
        dipilih: [],
        detailTab: 'verifikasi',
        selectedUser: {!! json_encode($selectedPengguna) !!},
        users: {!! json_encode($penggunaList) !!},

        previewModal: false,
        previewDoc: null,
        showRejectModal: false,
        showRevokeModal: false,

        rejectPresets: [
            'Foto KTP buram, terpotong, atau NIK tidak terbaca jelas',
            'Sertifikat keahlian teknik AC belum dilampirkan atau kedaluwarsa',
            'Pas foto diri tidak sesuai ketentuan (wajib foto resmi)',
            'Surat pengalaman kerja tidak memiliki stempel atau tanda tangan resmi'
        ],
        selectedPresets: [],
        rejectNotes: '',

        tampilkanToast(msg, type = 'success', batal = null) {
            window.adminToast(msg, { tipe: type, batal: batal });
        },

        init() {
            var self = this;
            if (this.filteredUsers.length > 0) {
                this.pilihUser(this.filteredUsers[0]);
            }
            ['filterStatus', 'searchQuery', 'urutan', 'activeTabPeran'].forEach(function (k) {
                self.$watch(k, function () { self.halaman = 1; self.dipilih = []; });
            });
            this.$watch('halaman', function () { self.dipilih = []; });
        },

        // Simpan ke server; fungsi lanjut dipanggil hanya jika berhasil.
        simpanStatus(perubahan, massal) {
            return window.kirimAdmin('{{ route('admin.pengguna.status') }}', { perubahan: perubahan, massal: !!massal }).then(function (r) {
                if (!r.ok) {
                    var pesan = (r.data && r.data.pesan) || (r.data && r.data.message) || 'Perubahan gagal disimpan.';
                    window.adminToast(pesan, { tipe: 'error' });
                }
                return r;
            });
        },

        setLokal(perubahan) {
            var self = this;
            perubahan.forEach(function (u) {
                var user = self.users.find(function (x) { return x.id === u.id; });
                if (!user) { return; }
                user.status_verifikasi = u.status;
                user.alasan_penolakan = u.status === 'ditolak' ? (u.alasan || '') : null;
                if (u.dokumen) {
                    user.dokumen = JSON.parse(JSON.stringify(u.dokumen));
                } else if (u.status === 'terverifikasi') {
                    (user.dokumen || []).forEach(function (d) { d.status = 'valid'; d.catatan = 'Diverifikasi oleh Admin Operasional'; });
                }
            });
            window.setLencana('pengguna', this.users.filter(function (x) { return x.peran === 'Teknisi' && x.status_verifikasi === 'menunggu'; }).length);
        },

        // Terapkan perubahan status dengan Batalkan. Dipakai satu per satu maupun massal.
        terapkan(daftarUser, status, alasan, pesan, massal) {
            var self = this;
            var sebelum = daftarUser.map(function (u) {
                return { id: u.id, status: u.status_verifikasi, alasan: u.alasan_penolakan, dokumen: JSON.parse(JSON.stringify(u.dokumen || [])) };
            });
            var sesudah = daftarUser.map(function (u) { return { id: u.id, status: status, alasan: alasan || null }; });

            return this.simpanStatus(sesudah, massal).then(function (r) {
                if (!r.ok) { return false; }
                self.setLokal(sesudah);
                self.dipilih = [];
                self.tampilkanToast(pesan, status === 'ditolak' ? 'warning' : 'success', function () {
                    self.simpanStatus(sebelum.map(function (b) { return { id: b.id, status: b.status, alasan: b.alasan }; }), false).then(function (hasil) {
                        if (hasil.ok) {
                            self.setLokal(sebelum);
                            window.adminToast('Perubahan dibatalkan.');
                        }
                    });
                });
                return true;
            });
        },

        // Teknisi yang terpilih dan boleh disetujui massal (semua dokumen valid)
        get terpilihLayak() {
            var self = this;
            return this.users.filter(function (u) {
                return self.dipilih.includes(u.id) && u.status_verifikasi === 'menunggu'
                    && (u.dokumen || []).length > 0 && u.dokumen.every(function (d) { return d.status === 'valid'; });
            });
        },
        get terpilihBelumLayak() { return this.dipilih.length - this.terpilihLayak.length; },

        get dapatDipilih() {
            return this.halamanIni.filter(function (u) { return u.peran === 'Teknisi' && u.status_verifikasi === 'menunggu'; });
        },
        get semuaTerpilih() {
            return this.dapatDipilih.length > 0 && this.dipilih.length === this.dapatDipilih.length;
        },
        pilihSemua() {
            this.dipilih = this.semuaTerpilih ? [] : this.dapatDipilih.map(function (u) { return u.id; });
        },
        setujuiMassal() {
            var n = this.terpilihLayak.length;
            this.terapkan(this.terpilihLayak, 'terverifikasi', null, n + ' teknisi diverifikasi dan kini aktif menerima order.', true);
        },

        get totalTersaring() { return this.filteredUsers.length; },
        get jumlahHalaman() { return Math.max(1, Math.ceil(this.totalTersaring / this.perHalaman)); },
        get halamanIni() {
            var mulai = (this.halaman - 1) * this.perHalaman;
            return this.filteredUsers.slice(mulai, mulai + this.perHalaman);
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
            var self = this;
            var doc = this.previewDoc;
            window.kirimAdmin('{{ route('admin.pengguna.dokumen') }}', { id: this.selectedUser.id, dokumen_id: doc.id, status: status }).then(function (r) {
                if (!r.ok) {
                    window.adminToast((r.data && r.data.pesan) || 'Hasil pemeriksaan gagal disimpan.', { tipe: 'error' });
                    return;
                }
                var sebelumStatus = doc.status;
                var sebelumCatatan = doc.catatan;
                doc.status = status;
                doc.catatan = status === 'valid' ? 'Telah diperiksa: berkas asli dan valid' : 'Telah diperiksa: perlu perbaikan atau buram';
                self.previewModal = false;
                self.tampilkanToast('Dokumen ' + doc.nama + ' ditandai ' + (status === 'valid' ? 'Valid' : 'Tidak Valid') + '.', status === 'valid' ? 'success' : 'warning', function () {
                    window.kirimAdmin('{{ route('admin.pengguna.dokumen') }}', { id: self.selectedUser.id, dokumen_id: doc.id, status: sebelumStatus }).then(function (h) {
                        if (h.ok) { doc.status = sebelumStatus; doc.catatan = sebelumCatatan; window.adminToast('Perubahan dibatalkan.'); }
                    });
                });
            });
        },

        // Persetujuan langsung, dengan Batalkan. Dokumen yang belum valid disebut di pesan.
        setujui() {
            var user = this.selectedUser;
            var belum = (user.dokumen || []).filter(function (d) { return d.status !== 'valid'; }).length;
            var pesan = 'Teknisi ' + user.nama + ' diverifikasi dan kini aktif menerima order.'
                + (belum > 0 ? ' ' + belum + ' dokumen belum ditandai valid.' : '');
            this.terapkan([user], 'terverifikasi', null, pesan, false);
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

            var self = this;
            this.terapkan([this.selectedUser], 'ditolak', alasan, 'Verifikasi teknisi ' + this.selectedUser.nama + ' ditolak. Alasan dikirim sebagai catatan perbaikan.', false).then(function (ok) {
                if (ok) { self.showRejectModal = false; }
            });
        },

        cabutVerifikasi() {
            this.terapkan([this.selectedUser], 'menunggu', null, 'Verifikasi teknisi ' + this.selectedUser.nama + ' dicabut dan dikembalikan ke Menunggu.', false);
        },

        tinjauUlang() {
            this.terapkan([this.selectedUser], 'menunggu', null, 'Pengajuan teknisi ' + this.selectedUser.nama + ' dibuka kembali untuk ditinjau ulang.', false);
        },

        waktuDaftar(teks) {
            var bulan = { jan: 0, feb: 1, mar: 2, apr: 3, mei: 4, jun: 5, jul: 6, agu: 7, sep: 8, okt: 9, nov: 10, des: 11 };
            var bagian = String(teks).split(' ');
            var jam = (bagian[3] || '00:00').split(':');
            return Date.UTC(parseInt(bagian[2], 10), bulan[bagian[1].slice(0, 3).toLowerCase()], parseInt(bagian[0], 10), parseInt(jam[0], 10), parseInt(jam[1], 10));
        },

        hitungPeran(peran) {
            if (peran === 'semua') { return this.users.length; }
            return this.users.filter(function(u) { return u.peran.toLowerCase() === peran; }).length;
        },

        get filteredUsers() {
            var self = this;
            var hasil = this.users.filter(function(user) {
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
            return hasil.sort(function(a, b) {
                var selisih = self.waktuDaftar(b.tanggal_daftar) - self.waktuDaftar(a.tanggal_daftar);
                return self.urutan === 'terbaru' ? selisih : -selisih;
            });
        },

    };
}
</script>

<div x-data="initKelolaPengguna()" class="p-8">

    <!-- Breadcrumb: Beranda > Kelola Pengguna (Sesuai Figma) -->
    <div class="flex items-center gap-2 text-xs font-medium text-slate-500 mb-2">
        <a href="{{ route('admin.dashboard') }}" class="hover:text-brand-dark transition-colors flex items-center gap-1">
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
            <h1 class="text-2xl font-bold text-navy tracking-tight">Kelola Pengguna</h1>
            <p class="text-xs text-slate-500 font-medium mt-0.5">Kelola Pengguna aplikasi ACare, termasuk verifikasi teknisi layanan AC.</p>
        </div>
    </div>

    <!-- MAIN GRID 2 KOLOM (KIRI TABEL 8 KOLOM, KANAN PANEL VERIFIKASI 4 KOLOM) -->
    <div class="grid grid-cols-12 gap-6 items-start">

        <!-- ================= BAGIAN TENGAH / KIRI: TABEL PENGGUNA (8 COLS) ================= -->
        <div class="col-span-12 lg:col-span-8 space-y-4">

            <!-- Filter Tabs Kategori Sesuai Figma -->
            <div class="flex items-center justify-between border-b border-line pb-1">
                <div class="flex items-center gap-6">
                    <!-- Tab: Semua Pengguna -->
                    <button @click="activeTabPeran = 'semua'"
                            :class="activeTabPeran === 'semua' ? 'text-brand-dark font-bold border-b-2 border-brand pb-2' : 'text-slate-500 font-medium hover:text-slate-700 pb-2'"
                            class="text-xs flex items-center gap-2 transition-all">
                        <span>Semua Pengguna</span>
                        <span :class="activeTabPeran === 'semua' ? 'text-brand-dark' : 'text-slate-500'"
                              class="text-xs font-semibold" x-text="hitungPeran('semua')"></span>
                    </button>

                    <!-- Tab: Teknisi -->
                    <button @click="activeTabPeran = 'teknisi'"
                            :class="activeTabPeran === 'teknisi' ? 'text-brand-dark font-bold border-b-2 border-brand pb-2' : 'text-slate-500 font-medium hover:text-slate-700 pb-2'"
                            class="text-xs flex items-center gap-2 transition-all">
                        <span>Teknisi</span>
                        <span :class="activeTabPeran === 'teknisi' ? 'text-brand-dark' : 'text-slate-500'"
                              class="text-xs font-semibold" x-text="hitungPeran('teknisi')"></span>
                    </button>

                    <!-- Tab: Pengguna -->
                    <button @click="activeTabPeran = 'pengguna'"
                            :class="activeTabPeran === 'pengguna' ? 'text-brand-dark font-bold border-b-2 border-brand pb-2' : 'text-slate-500 font-medium hover:text-slate-700 pb-2'"
                            class="text-xs flex items-center gap-2 transition-all">
                        <span>Pengguna</span>
                        <span :class="activeTabPeran === 'pengguna' ? 'text-brand-dark' : 'text-slate-500'"
                              class="text-xs font-semibold" x-text="hitungPeran('pengguna')"></span>
                    </button>
                </div>
            </div>

            <!-- Baris Filter Dropdown & Search Bar -->
            <div class="flex items-center justify-between gap-3">
                <div class="flex items-center gap-3">
                    <!-- Dropdown Status -->
                    <div class="relative">
                        <select x-model="filterStatus"
                                class="appearance-none bg-white border border-slate-400 rounded-lg px-3 py-2 pr-8 text-sm font-semibold text-slate-700 hover:border-slate-400 focus:outline-none focus:ring-1 focus:ring-brand cursor-pointer">
                            <option value="semua">Semua Status</option>
                            <option value="menunggu">Menunggu Verifikasi</option>
                            <option value="terverifikasi">Terverifikasi</option>
                            <option value="ditolak">Ditolak</option>
                        </select>
                        <div class="absolute inset-y-0 right-0 flex items-center pr-2.5 pointer-events-none text-slate-500">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </div>
                    </div>

                    <!-- Urutan Tanggal Daftar -->
                    <div class="relative">
                        <select x-model="urutan" aria-label="Urutkan berdasarkan tanggal daftar"
                                class="appearance-none bg-white border border-slate-400 rounded-lg px-3 py-2 pr-8 text-sm font-semibold text-slate-700 hover:border-slate-400 focus:outline-none focus:ring-1 focus:ring-brand cursor-pointer">
                            <option value="terbaru">Daftar: Terbaru</option>
                            <option value="terlama">Daftar: Terlama</option>
                        </select>
                        <div class="absolute inset-y-0 right-0 flex items-center pr-2.5 pointer-events-none text-slate-500">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                            </svg>
                        </div>
                    </div>
                </div>

                <!-- Input Pencarian Cepat Tabel -->
                <div class="relative flex-1 min-w-0 max-w-xs">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                    </span>
                    <input type="text"
                           x-model="searchQuery"
                           placeholder="Filter nama, ID, atau kontak..."
                           class="w-full pl-9 pr-3 py-1.5 bg-white border border-slate-400 rounded-lg text-sm font-medium text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-brand">
                </div>
            </div>

            <!-- Bilah aksi massal: hanya muncul saat ada baris dipilih -->
            <div x-show="dipilih.length > 0" style="display: none;"
                 class="flex items-center justify-between gap-3 px-4 py-2.5 rounded-lg border border-brand bg-brand-50">
                <div class="min-w-0">
                    <p class="text-sm font-semibold text-navy"><span x-text="dipilih.length"></span> teknisi dipilih</p>
                    <p x-show="terpilihBelumLayak > 0" class="text-xs text-slate-600">
                        <span x-text="terpilihBelumLayak"></span> belum punya semua dokumen valid. Tinjau satu per satu.
                    </p>
                </div>
                <div class="flex items-center gap-2 flex-shrink-0">
                    <button type="button" @click="dipilih = []"
                            class="px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-white rounded-lg transition-colors">Batal pilih</button>
                    <button type="button" :disabled="terpilihLayak.length === 0" @click="setujuiMassal()"
                            class="px-3.5 py-1.5 bg-brand hover:bg-brand-dark text-white text-sm font-semibold rounded-lg transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                        Setujui <span x-text="terpilihLayak.length"></span> teknisi
                    </button>
                </div>
            </div>

            <!-- TABEL DATA PENGGUNA -->
            <div class="bg-white rounded-lg border border-line overflow-hidden">
                <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-brand-50 text-xs font-bold text-slate-600">
                            <th class="py-3 pl-5 pr-1 w-8">
                                <input type="checkbox" :checked="semuaTerpilih" :disabled="dapatDipilih.length === 0" @change="pilihSemua()"
                                       aria-label="Pilih semua teknisi menunggu di halaman ini"
                                       class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand disabled:opacity-30">
                            </th>
                            <th class="py-3 px-3">Nama</th>
                            <th class="py-3 px-4">Kontak</th>
                            <th class="py-3 px-4">Status Verifikasi</th>
                            <th class="py-3 px-5 text-right">Tanggal Daftar</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-line text-sm">
                        <template x-for="user in halamanIni" :key="user.id">
                            <tr @click="pilihUser(user)" @keydown.enter="pilihUser(user)" @keydown.space.prevent="pilihUser(user)" tabindex="0" role="button" :aria-pressed="selectedUser.id === user.id"
                                :class="selectedUser.id === user.id ? 'bg-brand-50 border-l-4 border-brand' : 'hover:bg-slate-50/80'"
                                class="cursor-pointer transition-colors group focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-brand">
                                
                                <td class="py-3.5 pl-5 pr-1" @click.stop>
                                    <input type="checkbox" :value="user.id" x-model="dipilih"
                                           x-show="user.peran === 'Teknisi' && user.status_verifikasi === 'menunggu'"
                                           :aria-label="'Pilih ' + user.nama"
                                           class="w-4 h-4 rounded border-slate-400 text-brand focus:ring-brand">
                                </td>

                                <!-- Kolom Nama & Avatar -->
                                <td class="py-3.5 px-3">
                                    <div class="flex items-center gap-3">
                                        <div class="w-9 h-9 rounded-full bg-brand-100 text-brand-dark flex items-center justify-center font-bold text-xs flex-shrink-0">
                                            <span x-text="user.nama.charAt(0)"></span>
                                        </div>
                                        <div>
                                            <div class="flex items-center gap-1.5">
                                                <p class="font-bold text-slate-800 whitespace-nowrap" x-text="user.nama"></p>
                                            </div>
                                            <p class="text-xs text-slate-500 font-medium whitespace-nowrap"><span :class="user.peran === 'Teknisi' ? 'text-brand-dark font-semibold' : ''" x-text="user.peran"></span><span x-text="' · ' + user.id"></span></p>
                                        </div>
                                    </div>
                                </td>

                                <!-- Kolom Kontak dengan Ikon Telepon -->
                                <td class="py-3.5 px-4 text-slate-600 font-medium whitespace-nowrap">
                                    <div class="flex items-center gap-1.5">
                                        <svg class="w-3.5 h-3.5 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                        </svg>
                                        <span x-text="user.telepon"></span>
                                    </div>
                                </td>

                                <!-- Kolom Status Verifikasi Badge Sesuai Figma -->
                                <td class="py-3.5 px-4">
                                    <template x-if="user.status_verifikasi === 'terverifikasi'">
                                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 whitespace-nowrap">Terverifikasi</span>
                                    </template>
                                    <template x-if="user.status_verifikasi === 'menunggu'">
                                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-amber-700 whitespace-nowrap">Menunggu</span>
                                    </template>
                                    <template x-if="user.status_verifikasi === 'ditolak'">
                                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-rose-700 whitespace-nowrap">Ditolak</span>
                                    </template>
                                </td>

                                <!-- Kolom Tanggal Daftar (2 Baris Sesuai Figma) -->
                                <td class="py-3.5 px-5 text-right font-medium text-xs text-slate-500 whitespace-nowrap">
                                    <p class="leading-tight" x-text="user.tanggal_daftar.split(' ')[0] + ' ' + user.tanggal_daftar.split(' ')[1] + ' ' + user.tanggal_daftar.split(' ')[2]"></p>
                                    <p class="text-xs text-slate-500" x-text="user.tanggal_daftar.split(' ')[3] || '12:25'"></p>
                                </td>
                            </tr>
                        </template>
                        <tr x-show="filteredUsers.length === 0" style="display: none;">
                            <td colspan="5" class="py-12 text-center">
                                <p class="text-sm font-bold text-slate-600">Pengguna tidak ditemukan</p>
                                <p class="text-xs text-slate-500 mt-1">Coba ubah filter status, tab peran, atau kata kunci pencarian.</p>
                            </td>
                        </tr>
                    </tbody>
                </table>
                </div>
                @include('admin.partials.paginasi')
            </div>

        </div>

        <!-- ================= BAGIAN KANAN: PANEL DETAIL & VERIFIKASI (4 COLS) ================= -->
        <div class="col-span-12 lg:col-span-4 bg-white rounded-lg border border-line p-5 sticky top-6">

            <!-- Judul Panel Kanan -->
            <h2 class="text-xs font-bold text-navy tracking-tight mb-3">
                <span x-show="selectedUser.peran === 'Teknisi'">Data Pengguna &amp; Verifikasi Teknisi</span>
                <span x-show="selectedUser.peran === 'Pengguna'">Detail Informasi Pelanggan</span>
            </h2>

            <!-- Profil User Header (Card dengan Border sesuai Figma GanAnWo) -->
            <div class="border border-line rounded-lg p-4 mb-4">
                <div class="flex items-start gap-4">
                    <!-- Avatar Bulat Abu-abu Polos Sesuai Figma -->
                    <div class="w-16 h-16 rounded-full bg-brand-100 text-brand-dark flex items-center justify-center font-bold text-xl flex-shrink-0">
                        <span x-text="selectedUser.nama ? selectedUser.nama.charAt(0) : 'U'"></span>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h3 class="text-base font-bold text-navy truncate" x-text="selectedUser.nama"></h3>
                        <div class="mt-1 flex items-center gap-1.5">
                            <span class="text-xs font-semibold text-brand-dark" x-text="selectedUser.peran"></span>
                        </div>
                        <p class="text-xs text-slate-500 font-medium mt-1.5" x-text="'ID : ' + selectedUser.id"></p>
                        <p class="text-xs text-slate-600 font-medium mt-0.5 flex items-center gap-1.5">
                            <svg class="w-3 h-3 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                            </svg>
                            <span x-text="selectedUser.telepon"></span>
                        </p>
                        <p class="text-xs text-slate-500 truncate mt-0.5 flex items-center gap-1">
                            <svg class="w-3 h-3 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                <div class="flex border-b border-line mb-4 text-xs font-semibold">
                    <button @click="detailTab = 'data_pengguna'"
                            :class="detailTab === 'data_pengguna' ? 'text-brand-dark border-b-2 border-brand pb-2' : 'text-slate-500 hover:text-slate-600 pb-2'"
                            class="mr-6 transition-all">
                        Data Pengguna
                    </button>
                    <button @click="detailTab = 'verifikasi'"
                            :class="detailTab === 'verifikasi' ? 'text-brand-dark border-b-2 border-brand pb-2' : 'text-slate-500 hover:text-slate-600 pb-2'"
                            class="pb-2 transition-all flex items-center gap-1.5">
                        <span>Verifikasi Teknisi</span>
                    </button>
                </div>
            </template>

            <!-- ISI TAB 1: DATA PENGGUNA (TEKNISI / PELANGGAN) -->
            <div x-show="detailTab === 'data_pengguna'" class="space-y-3 text-xs">
                <div class="bg-slate-50 p-3.5 rounded-lg border border-line space-y-2.5">
                    <div>
                        <span class="text-slate-500 text-xs block">Email Terdaftar</span>
                        <span class="font-bold text-slate-800" x-text="selectedUser.email"></span>
                    </div>
                    <div>
                        <span class="text-slate-500 text-xs block">Nomor WhatsApp / Kontak</span>
                        <span class="font-bold text-slate-800" x-text="selectedUser.telepon"></span>
                    </div>
                    <div>
                        <span class="text-slate-500 text-xs block">Alamat Domisili</span>
                        <span class="font-bold text-slate-800" x-text="selectedUser.alamat"></span>
                    </div>
                    <template x-if="selectedUser.peran === 'Teknisi'">
                        <div>
                            <span class="text-slate-500 text-xs block">Kendaraan Operasional</span>
                            <span class="font-bold text-slate-800" x-text="selectedUser.kendaraan || 'Tidak ada data kendaraan'"></span>
                        </div>
                    </template>
                    <template x-if="selectedUser.peran === 'Teknisi' && selectedUser.keahlian">
                        <div>
                            <span class="text-slate-500 text-xs block">Keahlian &amp; Spesialisasi</span>
                            <span class="font-bold text-slate-800" x-text="selectedUser.keahlian"></span>
                        </div>
                    </template>
                </div>

                <!-- Jika Pelanggan Biasa: Tampilkan Riwayat Pesanan AC -->
                <template x-if="selectedUser.peran === 'Pengguna'">
                    <div class="mt-4">
                        <p class="text-xs font-bold text-navy mb-2">Riwayat Pesanan Servis AC</p>
                        <div class="border border-line rounded-lg divide-y divide-line overflow-hidden bg-white">
                            <template x-for="ord in (selectedUser.riwayat_order || [])" :key="ord.id">
                                <div class="p-3 text-xs">
                                    <div class="flex items-center justify-between mb-1">
                                        <span class="font-bold text-slate-800" x-text="ord.layanan"></span>
                                        <span class="text-xs font-semibold text-emerald-700" x-text="ord.status"></span>
                                    </div>
                                    <div class="flex items-center justify-between text-xs text-slate-500">
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
                    <p class="text-xs font-bold text-navy mb-1.5">Status Verifikasi</p>
                    
                    <!-- Kondisi 1: Menunggu Verifikasi (Banner Kuning Sesuai Figma) -->
                    <template x-if="selectedUser.status_verifikasi === 'menunggu'">
                        <div class="bg-amber-50 border border-amber-200 p-3 rounded-lg flex items-start gap-2.5">
                            <div class="w-6 h-6 rounded-full bg-amber-200/80 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <svg class="w-3.5 h-3.5 text-amber-700" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <div class="flex items-center justify-between">
                                    <p class="text-xs font-bold text-amber-900">Menunggu Verifikasi</p>
                                    <span class="text-xs text-amber-700 font-medium" x-text="'Sejak ' + (selectedUser.sejak_tanggal || '12 Sept 2026')"></span>
                                </div>
                                <p class="text-xs text-amber-800 mt-0.5 leading-snug">Data teknisi belum dicek. Silakan tinjau berkas kelengkapan di bawah.</p>
                            </div>
                        </div>
                    </template>

                    <!-- Kondisi 2: Terverifikasi (Banner Hijau) -->
                    <template x-if="selectedUser.status_verifikasi === 'terverifikasi'">
                        <div class="bg-emerald-50 border border-emerald-200 p-3 rounded-lg flex items-start gap-2.5">
                            <div class="w-6 h-6 rounded-full bg-emerald-200 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <svg class="w-3.5 h-3.5 text-emerald-800" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <div class="flex items-center justify-between">
                                    <p class="text-xs font-bold text-emerald-900">Teknisi Terverifikasi</p>
                                    <span class="text-xs text-emerald-700 font-medium">Akun Aktif</span>
                                </div>
                                <p class="text-xs text-emerald-800 mt-0.5 leading-snug">Seluruh berkas identitas &amp; keahlian telah disetujui. Teknisi dapat menerima order servis AC.</p>
                            </div>
                        </div>
                    </template>

                    <!-- Kondisi 3: Ditolak (Banner Merah) -->
                    <template x-if="selectedUser.status_verifikasi === 'ditolak'">
                        <div class="bg-rose-50 border border-rose-200 p-3 rounded-lg flex items-start gap-2.5">
                            <div class="w-6 h-6 rounded-full bg-rose-200 flex items-center justify-center flex-shrink-0 mt-0.5">
                                <svg class="w-3.5 h-3.5 text-rose-800" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <div class="flex items-center justify-between">
                                    <p class="text-xs font-bold text-rose-900">Verifikasi Ditolak</p>
                                    <span class="text-xs text-rose-700 font-medium">Perlu Revisi</span>
                                </div>
                                <p class="text-xs text-rose-800 mt-0.5 leading-snug" x-text="selectedUser.alasan_penolakan || 'Berkas tidak memenuhi syarat kelayakan teknisi.'"></p>
                            </div>
                        </div>
                    </template>
                </div>

                <!-- 2. DAFTAR DOKUMEN CHECKLIST (KTP, Ijazah, Foto Diri, Surat Kerja) SESUAI FIGMA -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <p class="text-xs font-bold text-navy">Data Verifikasi</p>
                    </div>

                    <div class="border border-line rounded-lg divide-y divide-line overflow-hidden bg-white">
                        <template x-for="doc in (selectedUser.dokumen || [])" :key="doc.nama">
                            <div class="p-3 flex items-center justify-between gap-3 hover:bg-slate-50 transition-colors">
                                <div class="flex items-center gap-2.5 flex-1 min-w-0">
                                    <!-- Status Indicator Dot -->
                                    <template x-if="doc.status === 'valid'">
                                        <div class="w-5 h-5 text-emerald-600 flex items-center justify-center flex-shrink-0" title="Dokumen Valid">
                                            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
                                            </svg>
                                        </div>
                                    </template>
                                    <template x-if="doc.status === 'tidak_valid'">
                                        <div class="w-5 h-5 text-rose-600 flex items-center justify-center flex-shrink-0" title="Dokumen Tidak Valid">
                                            <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M6 18L18 6M6 6l12 12"/>
                                            </svg>
                                        </div>
                                    </template>
                                    <template x-if="doc.status === 'menunggu' || !doc.status">
                                        <div class="w-5 h-5 text-amber-600 flex items-center justify-center flex-shrink-0" title="Belum Diperiksa">
                                            <iconify-icon icon="lucide:clock" width="16" height="16" aria-hidden="true"></iconify-icon>
                                        </div>
                                    </template>

                                    <div class="min-w-0">
                                        <p class="text-xs font-bold text-slate-800 truncate" x-text="doc.nama"></p>
                                        <p class="text-xs text-slate-500 font-mono truncate" x-text="doc.file" :title="doc.file"></p>
                                    </div>
                                </div>
                                <div class="flex-shrink-0">
                                    <button @click="tampilkanPreview(doc)"
                                            class="whitespace-nowrap px-3 py-1 text-xs font-semibold text-brand-dark border border-brand rounded-lg hover:bg-brand-50 transition-colors">
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
                                    class="flex-1 py-2.5 px-3 rounded-lg border border-rose-300 text-rose-600 font-bold text-xs hover:bg-rose-50 transition-all flex items-center justify-center gap-1.5">
                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                </svg>
                                <span>Tolak</span>
                            </button>
                            <button @click="setujui()"
                                    class="flex-[2] py-2.5 px-3 rounded-lg bg-brand hover:bg-brand-dark text-white font-bold text-xs transition-all flex items-center justify-center gap-1.5">
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
                            <div class="w-full py-2 px-3 bg-emerald-100/70 border border-emerald-300 text-emerald-800 rounded-lg text-center font-bold text-xs flex items-center justify-center gap-1.5">
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
                                    class="w-full py-2.5 px-3 bg-brand hover:bg-brand-dark text-white font-bold text-xs rounded-lg  transition-all flex items-center justify-center gap-1.5">
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
         class="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4"
         style="display: none;">
        <div @click.away="previewModal = false"
             class="bg-white rounded-lg max-w-lg w-full overflow-hidden shadow-lg border border-line transform transition-all">
            
            <!-- Header Modal -->
            <div class="bg-brand text-white p-4 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <svg class="w-4 h-4 text-brand-dark" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <span class="text-xs font-bold tracking-wide" x-text="'TINJAUAN BERKAS: ' + (previewDoc ? previewDoc.nama : '')"></span>
                </div>
                <button @click="previewModal = false" class="text-brand-dark hover:text-white p-1">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <!-- Body Modal Mockup Dokumen Realistis -->
            <div class="p-6">
                <div class="flex items-center justify-between mb-4">
                    <div>
                        <h4 class="text-sm font-bold text-slate-800" x-text="previewDoc ? previewDoc.file : ''"></h4>
                        <p class="text-xs text-slate-500" x-text="previewDoc ? previewDoc.deskripsi : ''"></p>
                    </div>
                    <template x-if="previewDoc && previewDoc.status === 'valid'">
                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700"><iconify-icon icon="lucide:check" aria-hidden="true"></iconify-icon>Valid</span>
                    </template>
                    <template x-if="previewDoc && previewDoc.status === 'tidak_valid'">
                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-rose-700"><iconify-icon icon="lucide:x" aria-hidden="true"></iconify-icon>Tidak valid</span>
                    </template>
                    <template x-if="!previewDoc || previewDoc.status === 'menunggu'">
                        <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-amber-700"><iconify-icon icon="lucide:clock" aria-hidden="true"></iconify-icon>Perlu tinjauan</span>
                    </template>
                </div>

                <!-- Pratinjau berkas -->
                <div class="rounded-lg border border-dashed border-slate-400 bg-slate-50 p-8 text-center">
                    <iconify-icon icon="lucide:file-text" width="36" height="36" class="text-slate-500" aria-hidden="true"></iconify-icon>
                    <p class="mt-2 text-sm font-semibold text-navy" x-text="previewDoc ? previewDoc.file : ''"></p>
                    <p class="text-sm text-slate-600 mt-1" x-text="previewDoc ? previewDoc.catatan : ''"></p>
                    <p class="text-xs text-slate-500 mt-3">Pratinjau berkas asli belum tersedia karena penyimpanan berkas belum terhubung ke server.</p>
                </div>

                <!-- Tombol Aksi Pemeriksaan Dokumen (Tandai Valid / Tidak Valid) -->
                <div class="mt-5 flex items-center justify-between gap-3 border-t border-line pt-4">
                    <button @click="tandaiDokumen('tidak_valid')"
                            class="px-4 py-2 rounded-lg border border-rose-300 text-rose-600 hover:bg-rose-50 text-xs font-bold transition-colors flex items-center gap-1.5">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                        <span>Tandai Tidak Valid / Buram</span>
                    </button>
                    <button @click="tandaiDokumen('valid')"
                            class="px-5 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-colors  flex items-center gap-1.5">
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
         class="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4"
         style="display: none;">
        <div @click.away="showRejectModal = false"
             class="bg-white rounded-lg max-w-md w-full overflow-hidden shadow-lg border border-line">
            
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
                <p class="font-bold text-navy mb-1">
                    Tolak pengajuan berkas: <span class="text-rose-600" x-text="selectedUser.nama"></span>
                </p>
                <p class="text-xs text-slate-500 mb-4">
                    Pilih alasan penolakan agar teknisi mengetahui dokumen mana yang harus diperbaiki &amp; diunggah ulang:
                </p>

                <!-- Checkbox Alasan Penolakan Preset -->
                <div class="space-y-2 mb-4">
                    <template x-for="preset in rejectPresets" :key="preset">
                        <label class="flex items-start gap-2.5 p-2 rounded-lg border border-line hover:bg-slate-50 cursor-pointer transition-colors">
                            <input type="checkbox"
                                   :value="preset"
                                   :checked="selectedPresets.includes(preset)"
                                   @change="togglePreset(preset)"
                                   class="mt-0.5 rounded text-rose-600 focus:ring-rose-500">
                            <span class="text-xs font-medium text-slate-700" x-text="preset"></span>
                        </label>
                    </template>
                </div>

                <!-- Input Catatan Tambahan -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1">Catatan Tambahan untuk Teknisi (Opsional):</label>
                    <textarea x-model="rejectNotes"
                              rows="2"
                              placeholder="Contoh: Mohon foto ulang KTP dengan pencahayaan terang..."
                              class="w-full p-2.5 border border-slate-400 rounded-lg text-sm focus:ring-1 focus:ring-rose-500 focus:outline-none"></textarea>
                </div>

                <div class="mt-5 flex justify-end gap-2.5 border-t border-line pt-3">
                    <button @click="showRejectModal = false"
                            class="px-4 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold transition-colors">
                        Batal
                    </button>
                    <button @click="prosesTolakTeknisi()"
                            class="px-5 py-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white font-bold transition-colors ">
                        Kirim Keputusan Penolakan
                    </button>
                </div>
            </div>

        </div>
    </div>

</div>

@endsection
