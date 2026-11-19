{{-- Token tema ACare Admin: satu sumber warna dan font untuk layout dan login. --}}
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

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
                    // Biru utama dari logo ACare. Untuk teks biru berukuran kecil di latar putih pakai brand-dark (kontras lebih tinggi).
                    brand: {
                        DEFAULT: '#0472FD',
                        dark: '#0358CC',
                        light: '#5BA2FF',
                        50: '#EAF3FB',
                        100: '#D5E7FA',
                    },
                    navy: '#0A2350',
                    surface: '#F3F7FB',
                    line: '#DCE6F0',
                }
            }
        }
    }
</script>

<!-- Iconify (paket ikon; proyek ini tidak memakai emoji) -->
<script src="https://cdn.jsdelivr.net/npm/iconify-icon@2.1.0/dist/iconify-icon.min.js"></script>

<style>
    body { font-family: 'Plus Jakarta Sans', sans-serif; }
    [x-cloak] { display: none !important; }
    ::-webkit-scrollbar { width: 8px; height: 8px; }
    ::-webkit-scrollbar-track { background: #EAF1F8; }
    ::-webkit-scrollbar-thumb { background: #BFD0E2; border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: #93ABC6; }
</style>
