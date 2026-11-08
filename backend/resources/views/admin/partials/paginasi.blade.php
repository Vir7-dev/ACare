{{--
    Kontrol halaman bersama. Dipakai di dalam komponen Alpine yang punya:
    halaman, jumlahHalaman, totalTersaring, perHalaman. Tersembunyi bila data muat dalam satu halaman.
--}}
<div x-show="jumlahHalaman > 1" style="display: none;"
     class="flex items-center justify-between gap-3 px-5 py-3 border-t border-line text-sm text-slate-600">
    <p>
        Menampilkan
        <span class="font-semibold text-slate-800" x-text="((halaman - 1) * perHalaman + 1) + '–' + Math.min(halaman * perHalaman, totalTersaring)"></span>
        dari <span class="font-semibold text-slate-800" x-text="totalTersaring"></span>
    </p>
    <div class="flex items-center gap-1">
        <button type="button" @click="halaman = halaman - 1" :disabled="halaman <= 1"
                class="px-3 py-1.5 rounded-lg border border-line font-semibold hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">Sebelumnya</button>
        <span class="px-3 py-1.5 text-slate-600">Halaman <span x-text="halaman"></span> / <span x-text="jumlahHalaman"></span></span>
        <button type="button" @click="halaman = halaman + 1" :disabled="halaman >= jumlahHalaman"
                class="px-3 py-1.5 rounded-lg border border-line font-semibold hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">Berikutnya</button>
    </div>
</div>
