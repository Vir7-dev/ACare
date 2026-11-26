# ACare Mobile

Aplikasi Flutter untuk pelanggan dan teknisi ACare.

## Menjalankan bersama backend

1. Jalankan backend Laravel (folder `backend`):

   ```bash
   php artisan migrate
   php artisan db:seed --class=PenggunaSeeder
   php artisan storage:link
   php artisan serve
   ```

2. Jalankan aplikasi:

   - **Emulator Android:** cukup `flutter run`. Aplikasi memanggil
     `http://10.0.2.2:8000/api` (alamat komputer dilihat dari emulator).
   - **HP sungguhan** (satu Wi-Fi dengan laptop): jalankan backend dengan
     `php artisan serve --host=0.0.0.0`, lalu
     `flutter run --dart-define=API_URL=http://<IP-laptop>:8000/api`.

Akun contoh (kata sandi `password`): `pelanggan@acare.id` dan
`teknisi@acare.id`.

## Catatan

- Semua panggilan API lewat `lib/services/api_client.dart`; autentikasi
  dan data akun lewat `lib/services/auth_service.dart`.
- Token disimpan terenkripsi (`flutter_secure_storage`).
- HTTP biasa hanya diizinkan di build debug
  (`android/app/src/debug/AndroidManifest.xml`). Build rilis wajib HTTPS.
- Test memakai server API palsu di memori (`test/support/server_palsu.dart`),
  jadi `flutter test` tidak butuh backend menyala.
