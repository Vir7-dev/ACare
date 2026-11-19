<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - ACare Admin Portal</title>

    @include('layouts.partials.tema')

    <!-- Alpine.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="min-h-screen bg-white text-slate-800 antialiased flex">

    <!-- Panel kiri: foto identitas ACare -->
    <section class="hidden lg:flex lg:w-[55%] relative flex-col justify-between p-12 text-white bg-navy bg-cover bg-center"
             style="background-image: url('{{ asset('images/login-bg.jpg') }}');">
        <div class="absolute inset-0" style="background: linear-gradient(180deg, rgba(10,35,80,0.78) 0%, rgba(10,35,80,0.15) 38%, rgba(10,35,80,0.15) 62%, rgba(10,35,80,0.85) 100%);" aria-hidden="true"></div>

        <div class="relative">
            <img src="{{ asset('images/logo-acare-putih.png') }}" alt="ACare" class="w-40 h-auto">
        </div>

        <div class="relative max-w-md">
            <h2 class="text-3xl font-bold leading-tight">Kelola layanan AC dalam satu tempat.</h2>
            <p class="mt-3 text-base text-white/85">Verifikasi teknisi, pantau transaksi, dan tangani pengaduan pelanggan dari satu portal.</p>
        </div>
    </section>

    <!-- Panel kanan: formulir -->
    <main class="flex-1 flex flex-col items-center justify-center px-6 py-10" x-data="{ showPass: false }">
        <div class="w-full max-w-sm">

            <!-- Logo untuk layar kecil (panel foto disembunyikan) -->
            <div class="lg:hidden mb-8">
                <img src="{{ asset('images/logo-acare.png') }}" alt="ACare" class="w-32 h-auto">
            </div>

            <h1 class="text-2xl font-bold text-navy tracking-tight">Selamat Datang!</h1>
            <p class="text-sm text-slate-600 mt-1 mb-7">Masuk untuk mengelola layanan ACare.</p>

            @if(session('info'))
                <div class="mb-5 px-3.5 py-3 bg-brand-50 border border-brand-100 text-brand-dark rounded-lg text-sm font-medium flex items-center gap-2.5" role="status">
                    <iconify-icon icon="lucide:info" width="16" height="16" aria-hidden="true"></iconify-icon>
                    <span>{{ session('info') }}</span>
                </div>
            @endif

            @if($errors->any())
                <div class="mb-5 px-3.5 py-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-lg text-sm font-medium flex items-center gap-2.5" role="alert">
                    <iconify-icon icon="lucide:circle-alert" width="16" height="16" aria-hidden="true"></iconify-icon>
                    <span>{{ $errors->first() }}</span>
                </div>
            @endif

            <form action="{{ route('admin.login.submit') }}" method="POST" class="space-y-5">
                @csrf

                <div>
                    <label for="email" class="block text-sm font-semibold text-navy mb-1.5">Nama Pengguna / Email Admin</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-500">
                            <iconify-icon icon="lucide:user" width="16" height="16" aria-hidden="true"></iconify-icon>
                        </span>
                        <input type="text"
                               id="email"
                               name="email"
                               value="{{ old('email') }}"
                               autocomplete="username"
                               required
                               placeholder="admin@acare.id atau nama pengguna"
                               class="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-300 rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent">
                    </div>
                </div>

                <div>
                    <label for="password" class="block text-sm font-semibold text-navy mb-1.5">Kata Sandi</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-500">
                            <iconify-icon icon="lucide:lock" width="16" height="16" aria-hidden="true"></iconify-icon>
                        </span>
                        <input :type="showPass ? 'text' : 'password'"
                               id="password"
                               name="password"
                               autocomplete="current-password"
                               required
                               placeholder="Masukkan kata sandi portal"
                               class="w-full pl-10 pr-11 py-2.5 bg-white border border-slate-300 rounded-lg text-sm text-slate-800 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent">
                        <button type="button"
                                @click="showPass = !showPass"
                                :aria-label="showPass ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'"
                                class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-500 hover:text-slate-800">
                            <iconify-icon x-show="!showPass" icon="lucide:eye" width="18" height="18" aria-hidden="true"></iconify-icon>
                            <iconify-icon x-show="showPass" icon="lucide:eye-off" width="18" height="18" aria-hidden="true" style="display: none;"></iconify-icon>
                        </button>
                    </div>
                </div>

                <button type="submit"
                        class="w-full py-3 bg-brand hover:bg-brand-dark text-white font-semibold text-sm rounded-lg transition-colors flex items-center justify-center gap-2">
                    <span>Masuk ke Portal Admin</span>
                    <iconify-icon icon="lucide:arrow-right" width="16" height="16" aria-hidden="true"></iconify-icon>
                </button>
            </form>

            <p class="text-xs text-slate-600 mt-8">&copy; 2026 ACare. Hak Cipta Dilindungi.</p>
        </div>
    </main>

</body>
</html>
