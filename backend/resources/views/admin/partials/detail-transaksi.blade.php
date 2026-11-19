{{--
    Panel samping detail transaksi + kuitansi, dipakai di Beranda, Kelola Transaksi, dan Pengaduan.
    Dibuka lewat event window:  $dispatch('buka-detail-transaksi', { id: 'TRX-2410001' })
    atau lewat alamat:  ?detail=TRX-2410001
    Data diisi oleh View Composer (AppServiceProvider) sebagai $daftarTransaksi.
--}}
<style>
    @media print {
        body * { visibility: hidden; }
        #printableInvoice, #printableInvoice * { visibility: visible; }
        #printableInvoice { position: absolute; left: 0; top: 0; width: 100%; background: white !important; padding: 20px; }
    }
</style>

<script>
function detailTransaksi(daftar) {
    return {
        daftar: daftar,
        trx: null,
        terbuka: false,
        kuitansi: false,

        init: function () {
            var id = new URLSearchParams(window.location.search).get('detail');
            if (id) {
                this.bukaDetail(id);
            }
        },

        bukaDetail: function (id) {
            var ditemukan = this.daftar.find(function (t) { return t.id === id; });
            if (!ditemukan) {
                return;
            }
            this.trx = ditemukan;
            this.terbuka = true;
        },

        tutup: function () {
            this.kuitansi = false;
            this.terbuka = false;
        },

        tekanEsc: function () {
            if (this.kuitansi) {
                this.kuitansi = false;
            } else if (this.terbuka) {
                this.terbuka = false;
            }
        },

        rupiah: function (angka) {
            return 'Rp ' + Number(angka).toLocaleString('id-ID');
        },

        get lunas() {
            return this.trx !== null && this.trx.status_bayar === 'Lunas';
        },

        kelasStatus: function (status) {
            if (status === 'Selesai') { return 'text-emerald-700'; }
            if (status === 'Berlangsung') { return 'text-amber-700'; }
            return 'text-rose-700';
        },

        kelasBayar: function (status) {
            if (status === 'Lunas') { return 'text-emerald-700'; }
            if (status === 'Batal') { return 'text-rose-700'; }
            return 'text-amber-700';
        }
    };
}
</script>

<div x-data="detailTransaksi(@js($daftarTransaksi))"
     @buka-detail-transaksi.window="bukaDetail($event.detail.id)"
     @keydown.escape.window="tekanEsc()">

    <!-- ===================== PANEL SAMPING DETAIL ===================== -->
    <div x-show="terbuka" x-transition.opacity class="fixed inset-0 z-[60] bg-navy/40" @click="tutup()" style="display: none;" aria-hidden="true"></div>

    <aside x-show="terbuka"
           x-transition:enter="transition ease-out duration-200"
           x-transition:enter-start="translate-x-full"
           x-transition:enter-end="translate-x-0"
           x-transition:leave="transition ease-in duration-150"
           x-transition:leave-start="translate-x-0"
           x-transition:leave-end="translate-x-full"
           class="fixed inset-y-0 right-0 z-[70] w-full max-w-lg bg-white border-l border-line shadow-lg flex flex-col"
           role="dialog" aria-modal="true" aria-labelledby="judul-detail-transaksi"
           style="display: none;">

        <template x-if="trx">
            <div class="flex flex-col h-full min-h-0">

                <!-- Header -->
                <div class="px-6 py-4 border-b border-line flex items-start justify-between gap-4">
                    <div class="min-w-0">
                        <div class="flex items-center gap-2 flex-wrap">
                            <h2 id="judul-detail-transaksi" class="text-base font-bold font-mono text-navy" x-text="trx.id"></h2>
                            <span class="inline-flex items-center gap-1.5 text-xs font-semibold" :class="kelasStatus(trx.status)"><span x-text="trx.status"></span></span>
                        </div>
                        <p class="text-sm text-slate-600 mt-0.5" x-text="trx.layanan + ' · ' + trx.tanggal + ', ' + trx.jam"></p>
                    </div>
                    <button type="button" @click="tutup()" aria-label="Tutup detail transaksi"
                            class="p-1.5 -mr-1.5 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800 transition-colors">
                        <iconify-icon icon="lucide:x" width="20" height="20" aria-hidden="true"></iconify-icon>
                    </button>
                </div>

                <!-- Isi -->
                <div class="flex-1 overflow-y-auto px-6 py-5 space-y-6 text-sm">

                    <!-- Pelanggan & teknisi -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <p class="text-xs font-semibold text-slate-500 mb-1">Pelanggan</p>
                            <p class="font-bold text-navy" x-text="trx.pelanggan"></p>
                            <p class="text-slate-600 mt-0.5" x-text="trx.telepon_pelanggan"></p>
                            <p class="text-slate-500 text-xs mt-0.5" x-text="trx.alamat"></p>
                        </div>
                        <div>
                            <p class="text-xs font-semibold text-slate-500 mb-1">Teknisi</p>
                            <p class="font-bold text-navy" x-text="trx.teknisi"></p>
                            <p class="text-slate-600 mt-0.5" x-text="trx.telepon_teknisi"></p>
                            <p class="text-slate-500 text-xs mt-0.5" x-text="'Durasi: ' + trx.durasi"></p>
                        </div>
                    </div>

                    <!-- Unit & keluhan -->
                    <div class="bg-brand-50 border border-brand-100 rounded-lg p-4">
                        <p class="text-xs font-semibold text-brand-dark mb-1">Unit AC &amp; keluhan</p>
                        <p class="font-bold text-navy" x-text="trx.unit_ac"></p>
                        <p class="text-slate-700 mt-1" x-text="trx.keluhan"></p>
                    </div>

                    <!-- Bukti pengerjaan -->
                    <div>
                        <h3 class="text-sm font-bold text-navy mb-2">Bukti pengerjaan</h3>
                        <template x-if="trx.status === 'Dibatalkan'">
                            <p class="text-slate-500 border border-dashed border-slate-400 rounded-lg p-4 text-center">Pesanan dibatalkan, tidak ada bukti pengerjaan.</p>
                        </template>
                        <template x-if="trx.status !== 'Dibatalkan' && trx.bukti">
                            <div class="space-y-3">
                                <template x-for="tahap in [
                                    { judul: 'Sebelum servis', isi: trx.bukti.sebelum },
                                    { judul: 'Proses servis', isi: trx.bukti.proses },
                                    { judul: 'Sesudah servis', isi: trx.bukti.sesudah }
                                ]" :key="tahap.judul">
                                    <div class="flex gap-3">
                                        <div class="w-16 h-16 flex-shrink-0 rounded-lg bg-slate-100 border border-line flex items-center justify-center text-slate-500">
                                            <iconify-icon icon="lucide:image" width="22" height="22" aria-hidden="true"></iconify-icon>
                                        </div>
                                        <div class="min-w-0">
                                            <p class="font-semibold text-navy" x-text="tahap.judul"></p>
                                            <p class="text-slate-600" x-text="tahap.isi"></p>
                                        </div>
                                    </div>
                                </template>
                                <div class="bg-amber-50 border border-amber-200 rounded-lg p-3">
                                    <p class="text-xs font-semibold text-amber-900">Catatan teknisi</p>
                                    <p class="text-amber-950 mt-0.5" x-text="trx.bukti.catatan_teknisi"></p>
                                    <p class="text-xs text-amber-900/80 mt-1" x-text="trx.bukti.waktu_selesai"></p>
                                </div>
                            </div>
                        </template>
                    </div>

                    <!-- Rincian biaya -->
                    <div>
                        <h3 class="text-sm font-bold text-navy mb-2">Rincian biaya</h3>
                        <div class="border border-line rounded-lg divide-y divide-line overflow-hidden">
                            <template x-for="rincian in trx.rincian" :key="rincian.item">
                                <div class="px-3.5 py-2.5 flex items-center justify-between gap-4">
                                    <span class="text-slate-700" x-text="rincian.item"></span>
                                    <span class="font-semibold text-navy whitespace-nowrap" x-text="rupiah(rincian.biaya)"></span>
                                </div>
                            </template>
                            <div class="px-3.5 py-3 bg-slate-50 flex items-center justify-between">
                                <span class="font-bold text-navy">Total</span>
                                <span class="font-bold text-navy" x-text="rupiah(trx.total_biaya)"></span>
                            </div>
                        </div>
                        <p class="mt-2 text-sm text-slate-600">
                            <span x-text="trx.metode_bayar"></span> ·
                            <span class="font-semibold" :class="kelasBayar(trx.status_bayar)" x-text="trx.status_bayar"></span>
                        </p>
                    </div>
                </div>

                <!-- Aksi -->
                <div class="px-6 py-4 border-t border-line flex items-center justify-between gap-3">
                    <button type="button" @click="kuitansi = true" :disabled="!lunas"
                            :title="lunas ? '' : 'Kuitansi hanya tersedia untuk pembayaran lunas'"
                            class="px-4 py-2 border border-slate-400 text-slate-700 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed font-semibold rounded-lg text-sm transition-colors flex items-center gap-2">
                        <iconify-icon icon="lucide:receipt-text" width="16" height="16" aria-hidden="true"></iconify-icon>
                        <span>Lihat kuitansi</span>
                    </button>
                    <button type="button" @click="tutup()"
                            class="px-5 py-2 bg-brand hover:bg-brand-dark text-white font-semibold rounded-lg text-sm transition-colors">
                        Tutup
                    </button>
                </div>
            </div>
        </template>
    </aside>

    <!-- ===================== KUITANSI ===================== -->
    <div x-show="kuitansi" x-transition.opacity
         class="fixed inset-0 z-[80] flex items-center justify-center bg-navy/60 p-4 overflow-y-auto"
         role="dialog" aria-modal="true" aria-label="Kuitansi pembayaran"
         style="display: none;">
        <div @click.away="kuitansi = false" class="bg-white rounded-xl max-w-lg w-full overflow-hidden shadow-lg border border-line my-8">

            <template x-if="trx">
                <div id="printableInvoice" class="p-8 text-slate-800">
                    <div class="flex items-start justify-between border-b-2 border-navy pb-4 mb-4">
                        <div>
                            <img src="{{ asset('images/logo-acare.png') }}" alt="ACare" class="h-9 w-auto mb-2">
                            <p class="text-xs text-slate-500">Batam Center, Kepulauan Riau</p>
                        </div>
                        <div class="text-right">
                            <h2 class="text-lg font-bold text-navy">Kuitansi</h2>
                            <p class="text-xs font-mono font-bold text-brand-dark" x-text="trx.id"></p>
                            <p class="text-xs text-slate-500" x-text="trx.tanggal"></p>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 gap-4 text-sm mb-5">
                        <div>
                            <p class="text-xs font-semibold text-slate-500">Diterbitkan untuk</p>
                            <p class="font-bold text-navy" x-text="trx.pelanggan"></p>
                            <p class="text-slate-600 text-xs" x-text="trx.telepon_pelanggan"></p>
                            <p class="text-slate-500 text-xs" x-text="trx.alamat"></p>
                        </div>
                        <div class="text-right">
                            <p class="text-xs font-semibold text-slate-500">Teknisi</p>
                            <p class="font-bold text-navy" x-text="trx.teknisi"></p>
                            <p class="text-slate-600 text-xs" x-text="trx.layanan"></p>
                            <p class="text-slate-500 text-xs" x-text="trx.unit_ac"></p>
                        </div>
                    </div>

                    <table class="w-full text-sm text-left border-collapse mb-5">
                        <thead>
                            <tr class="border-b border-slate-400 text-xs font-semibold text-slate-500">
                                <th class="py-2">Deskripsi</th>
                                <th class="py-2 text-right">Jumlah</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-line">
                            <template x-for="rincian in trx.rincian" :key="rincian.item">
                                <tr>
                                    <td class="py-2.5 text-slate-800" x-text="rincian.item"></td>
                                    <td class="py-2.5 text-right font-semibold text-navy" x-text="rupiah(rincian.biaya)"></td>
                                </tr>
                            </template>
                        </tbody>
                        <tfoot>
                            <tr class="border-t-2 border-navy">
                                <td class="py-3 font-bold text-navy">Total</td>
                                <td class="py-3 text-right font-bold text-navy text-base" x-text="rupiah(trx.total_biaya)"></td>
                            </tr>
                        </tfoot>
                    </table>

                    <div class="flex items-center justify-between pt-3 border-t border-dashed border-slate-400">
                        <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-100 border border-emerald-300 rounded-lg text-emerald-800 font-bold text-xs">
                            <iconify-icon icon="lucide:check" aria-hidden="true"></iconify-icon>
                            <span>Lunas via <span x-text="trx.metode_bayar"></span></span>
                        </span>
                        <p class="text-xs text-slate-500">Dicetak oleh Admin Operasional ACare</p>
                    </div>
                </div>
            </template>

            <div class="p-4 bg-slate-50 border-t border-line flex items-center justify-end gap-2.5">
                <button type="button" @click="kuitansi = false" class="px-4 py-2 bg-white border border-slate-400 text-slate-700 hover:bg-slate-100 font-semibold rounded-lg text-sm transition-colors">Tutup</button>
                <button type="button" @click="window.print()" class="px-5 py-2 bg-brand hover:bg-brand-dark text-white font-semibold rounded-lg text-sm transition-colors flex items-center gap-2">
                    <iconify-icon icon="lucide:printer" width="16" height="16" aria-hidden="true"></iconify-icon>
                    <span>Cetak</span>
                </button>
            </div>
        </div>
    </div>
</div>
