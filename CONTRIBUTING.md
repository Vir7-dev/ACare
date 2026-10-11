# Panduan Kerja Git Tim ACare

Repo ini monorepo: `mobile/` (Flutter) dan `backend/` (Laravel). Semua perubahan masuk lewat **branch** dan **Pull Request (PR)**, tidak ada yang push langsung ke `main`.

## Konsep singkat

- `main` = kode yang stabil dan jalan.
- Branch = jalur kerja terpisah dari `main`. **Satu branch untuk satu tugas** (satu halaman atau satu fitur), bukan satu branch per orang.
- Selesai dikerjakan, branch digabung ke `main` lewat PR, lalu branch dihapus.

## Setup awal (sekali saja)

```bash
git clone https://github.com/Vir7-dev/ACare.git
cd ACare
```

Mobile:
```bash
cd mobile
flutter pub get
```

Backend:
```bash
cd backend
composer install
copy .env.example .env
php artisan key:generate
```
Lalu atur `DB_*` di `.env` (MySQL Laragon, nama database `acare`) dan jalankan `php artisan migrate`.

## Alur kerja per tugas

**1. Sinkron dengan `main`, lalu buat branch**
```bash
git checkout main
git pull
git checkout -b feature/nama-halaman
```

**2. Ngoding dan commit**
```bash
git add .
git commit -m "tambah halaman riwayat pesanan"
```
Commit boleh berkali-kali selama mengerjakan.

**3. Push branch**
```bash
git push -u origin feature/nama-halaman
```
Push berikutnya cukup `git push`.

**4. Buka Pull Request**
Di GitHub klik **Compare & pull request**, isi judul dan deskripsi singkat, lalu minta review ke leader.

**5. Setelah PR di-merge, bersihkan**
```bash
git checkout main
git pull
git branch -d feature/nama-halaman
```
Lalu mulai tugas berikutnya dari langkah 1.

## Aturan penamaan

| Jenis | Pola | Contoh |
|---|---|---|
| Fitur/halaman baru | `feature/nama-halaman` | `feature/login`, `feature/pembayaran` |
| Perbaikan bug | `fix/deskripsi-singkat` | `fix/overflow-kartu-pesanan` |

Pesan commit harus jelas (bukan "update" atau "fix"), contoh: `tambah filter status di riwayat pesanan`.

## Aturan main

- Jangan push langsung ke `main`.
- Jangan pakai `git push --force`.
- Satu branch satu tugas, jangan dipakai berminggu-minggu.
- Tarik `main` terbaru sebelum mulai tugas baru.
- Jangan commit file `.env`, `vendor/`, `build/`, atau `.dart_tool/`.
- Kerjakan file sesuai pembagian halaman supaya konflik minimal.

## Kalau ada konflik

Konflik terjadi kalau dua orang mengedit baris yang sama. File yang rawan: `mobile/lib/main.dart`, `mobile/pubspec.yaml`, `backend/routes/api.php`, `backend/routes/web.php`.

Tarik perubahan terbaru ke branch kamu sebelum push:
```bash
git checkout main
git pull
git checkout feature/nama-halaman
git merge main
```

Kalau muncul tanda `<<<<<<<` di file, buka di VS Code, pilih **Accept Current**, **Accept Incoming**, atau **Accept Both**, simpan, lalu:
```bash
git add .
git commit
```

## Struktur folder

```
acare/
├── mobile/     <- Flutter (customer & teknisi)
└── backend/    <- Laravel (REST API + web admin Blade)
```

Struktur di `mobile/lib/`:
```
lib/
├── main.dart
├── models/     <- bentuk data
├── pages/      <- satu file per halaman
└── widgets/    <- komponen yang dipakai ulang
```