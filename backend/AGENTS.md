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
| `GET /api/layanan` | Katalog layanan aktif + harga awal |
| `GET/POST /api/alamat`, `PUT/DELETE /api/alamat/{id}` | Alamat tersimpan pelanggan; ubah alamat yang sudah dipakai pesanan = baris baru (id baru), yang lama di-soft-delete |
| `GET/POST /api/pesanan`, `GET /api/pesanan/{id}` | Pesanan pelanggan; `?status=aktif\|selesai\|dibatalkan` |
| `POST /api/pesanan/{id}/batal` | Hanya saat `mencari_teknisi`; tagihan belum dibayar → `kedaluwarsa`, sudah dibayar → `tertahan` |
| `POST /api/pesanan/{id}/biaya` | Pelanggan `setuju` true/false atas rincian biaya teknisi |
| `POST /api/pesanan/{id}/pembayaran/{idPembayaran}/simulasi-lunas` | Hanya env `local`/`testing`: anggap tagihan lunas tanpa Xendit |
| `GET /api/pesanan/{id}/foto/{idFoto}` | Foto bukti (disk privat), untuk pelanggan pemilik & teknisinya |
| `PUT /api/teknisi/status`, `PUT /api/teknisi/lokasi` | Online/offline (online wajib kirim lokasi), lokasi berkala |
| `GET /api/teknisi/tawaran`, `POST /api/teknisi/tawaran/{id}/terima\|tolak` | Tawaran 30 detik ke teknisi terdekat |
| `GET /api/teknisi/pekerjaan`, `POST /api/teknisi/pekerjaan/{id}/tiba\|pengecekan\|foto-pemeriksaan\|biaya\|tanpa-biaya\|selesai` | Langkah kerja teknisi, harus berurutan (409 bila tidak) |

- Galat: `{message, kode?}`; validasi 422 `{message, errors}` berbahasa
  Indonesia (pesan di `App\Http\Requests\Api\ApiRequest`).
- `kode` masuk: `kredensial_salah`, `peran_tidak_sesuai`, `akun_diblokir`,
  `belum_terverifikasi`, `verifikasi_ditolak` (+ `alasan`),
  `terlalu_banyak_percobaan` (5x salah → kunci 60 detik).
- Nomor HP diseragamkan ke `08…` (`App\Support\NomorTelepon`).
- Dokumen teknisi di disk privat `local` (`dokumen-teknisi/{id}`), tidak
  bisa dibuka lewat URL publik.
- Token berlaku 30 hari (`SANCTUM_EXPIRATION`, menit). Akun yang diblokir
  ditolak middleware `akun.aktif`; rute khusus peran memakai `peran:pelanggan`.
- Pesanan baru: status `mencari_teknisi` + pembayaran `awal` berstatus
  `menunggu`. Tawaran ke teknisi baru dikirim setelah pembayaran awal lunas.
  Satu pelanggan hanya boleh punya satu pesanan aktif (409
  `masih_ada_pesanan_aktif`).
- Harga layanan satu nilai (`layanan.harga`) = biaya awal per unit; biaya
  tambahan hanya lewat rincian biaya teknisi yang disetujui pelanggan.
- Alur pesanan ada di `App\Services\AlurPesanan`: pembayaran awal lunas →
  ditawarkan ke teknisi terdekat (terverifikasi, online, lokasi < 30 menit,
  radius 20 km, tidak sibuk) lewat `id_teknisi_ditawari` → terima mengisi
  `id_teknisi`. 15 menit tanpa teknisi → batal otomatis, dana `tertahan`.
  Biaya ditolak/lewat 5 menit → lanjut dengan biaya awal. Selesai: sisa
  tagihan → pembayaran `pelunasan`; lunas → `selesai` + baris `pendapatan`.
- Batas waktu diperiksa setiap permintaan API dan oleh `pesanan:proses`
  (scheduler tiap menit). Lokal: `php artisan schedule:work`.

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
