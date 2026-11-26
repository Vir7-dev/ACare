# Backend ACare

API dan panel Admin untuk aplikasi pemesanan servis AC ACare.

## Lingkungan

- Laravel 13, PHP 8.4, MySQL 8.4 (lokal lewat Laragon, database `acare`)
- Test memakai SQLite in-memory: `php artisan test`
- Gaya kode: `vendor/bin/pint --dirty` sebelum commit

## Konvensi

- Penamaan berbahasa Indonesia: tabel `pengguna`, kunci `id_pengguna`,
  waktu `dibuat_pada` / `diubah_pada` (atur `CREATED_AT` / `UPDATED_AT`
  di model).
- Semua peran (pelanggan, teknisi, admin) ada di tabel `pengguna`; model
  autentikasinya `App\Models\Pengguna`. Tidak ada tabel `users`.
- Aplikasi mobile login dengan token Laravel Sanctum (`auth:sanctum`).
- Jangan mengubah migrasi yang sudah masuk `main`; buat migrasi baru.
- Trigger dan CHECK constraint hanya untuk MySQL, dibungkus
  `if (DB::getDriverName() === 'mysql')` agar test SQLite tetap jalan.

## API mobile (`routes/api.php`)

| Endpoint | Keterangan |
|---|---|
| `POST /api/daftar` | Daftar pelanggan |
| `POST /api/daftar/teknisi` | Daftar teknisi (multipart, 5 dokumen `dokumen[cv\|lamaran_kerja\|ktp\|ijazah\|pas_foto]`), status `menunggu` |
| `POST /api/masuk` | `identitas` (email/no HP), `kata_sandi`, `peran` → `token` + `pengguna` |
| `POST /api/keluar` | Cabut token perangkat ini |
| `GET/PUT /api/saya` | Data akun; ubah sebagian (teknisi juga kendaraan & deskripsi) |
| `POST /api/saya/foto` | Foto profil (disk `public`) |
| `PUT /api/saya/kata-sandi` | Mengeluarkan perangkat lain |

- Galat: `{message, kode?}`; validasi 422 `{message, errors}` berbahasa
  Indonesia (pesan di `App\Http\Requests\Api\ApiRequest`).
- `kode` masuk: `kredensial_salah`, `peran_tidak_sesuai`, `akun_diblokir`,
  `belum_terverifikasi`, `verifikasi_ditolak` (+ `alasan`),
  `terlalu_banyak_percobaan` (5x salah → kunci 60 detik).
- Nomor HP diseragamkan ke `08…` (`App\Support\NomorTelepon`).
- Dokumen teknisi di disk privat `local` (`dokumen-teknisi/{id}`), tidak
  bisa dibuka lewat URL publik.
- Token berlaku 30 hari (`SANCTUM_EXPIRATION`, menit). Akun yang diblokir
  ditolak middleware `akun.aktif`.

## Aturan bisnis penting

- Status pesanan (9): `mencari_teknisi`, `menuju_lokasi`, `tiba`,
  `pengecekan_awal`, `menunggu_persetujuan_biaya`, `dikerjakan`,
  `menunggu_pembayaran`, `selesai`, `dibatalkan`. Pelanggan melihat
  versi ringkas (`Pesanan::LABEL_PELANGGAN`).
- Pembayaran 2 tahap lewat Xendit: biaya awal sebelum mencari teknisi,
  pelunasan biaya perbaikan setelah pekerjaan selesai.
- Biaya perbaikan dari teknisi hanya ditagih bila `status_biaya`
  disetujui pelanggan. Pelanggan punya waktu 5 menit
  (`Pesanan::BATAS_PERSETUJUAN_MENIT`); lewat dari itu dianggap ditolak.
- Pelanggan hanya bisa membatalkan saat status `mencari_teknisi`.
- Komisi platform per layanan (`layanan.persentase_platform`, bawaan 10%),
  dicatat di `pendapatan` setelah pelunasan. Pencairan minimal Rp50.000.
- Akun admin, pelanggan, dan teknisi contoh ada di `PenggunaSeeder`
  (kata sandi `password`).
