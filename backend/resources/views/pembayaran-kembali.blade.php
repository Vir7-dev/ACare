<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ACare</title>
    <style>
        body { font-family: system-ui, sans-serif; display: grid; place-items: center; min-height: 100vh; margin: 0; padding: 16px; text-align: center; color: #1f2937; }
        h1 { font-size: 20px; margin: 0 0 8px; }
        p { margin: 0; color: #6b7280; }
    </style>
</head>
<body>
    <main>
        @if (request()->boolean('gagal'))
            <h1>Pembayaran belum berhasil</h1>
            <p>Kembali ke aplikasi ACare untuk mencoba lagi atau memilih metode lain.</p>
        @else
            <h1>Terima kasih</h1>
            <p>Silakan kembali ke aplikasi ACare. Status pembayaran akan diperbarui otomatis.</p>
        @endif
    </main>
</body>
</html>
