import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/perangkat.dart';
import '../../services/sesi_pengguna.dart';
import '../../theme/app_colors.dart';

class RegistrasiTeknisiPage extends StatefulWidget {
  const RegistrasiTeknisiPage({super.key});

  @override
  State<RegistrasiTeknisiPage> createState() => _RegistrasiTeknisiPageState();
}

class _RegistrasiTeknisiPageState extends State<RegistrasiTeknisiPage> {
  final formKey = GlobalKey<FormState>();

  int tahap = 1;
  bool sembunyikanPassword = true;
  bool setuju = false;

  final nama = TextEditingController();
  final telepon = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final nomorRekening = TextEditingController();
  final namaPemilik = TextEditingController();

  String bank = 'BNI (Bank Negara Indonesia)';
  bool mengirim = false;

  /// Dokumen verifikasi yang wajib diunggah (sesuai SKPPL & Figma).
  static const daftarDokumen = {
    'cv': 'CV',
    'lamaran_kerja': 'Lamaran Kerja',
    'ktp': 'KTP',
    'ijazah': 'Ijazah',
    'pas_foto': 'Pas Foto',
  };

  /// Batas ukuran tiap dokumen.
  static const int maksUkuranByte = 5 * 1024 * 1024;

  /// Nama berkas yang sudah dipilih per jenis dokumen.
  final Map<String, String> dokumen = {};

  @override
  void dispose() {
    nama.dispose();
    telepon.dispose();
    email.dispose();
    password.dispose();
    nomorRekening.dispose();
    namaPemilik.dispose();
    super.dispose();
  }

  String? wajib(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bagian ini wajib diisi';
    }
    return null;
  }

  void lanjut() {
    if (tahap == 1) {
      if (!formKey.currentState!.validate()) return;
      setState(() => tahap = 2);
      return;
    }

    if (tahap == 2) {
      final kurang = daftarDokumen.entries
          .where((e) => !dokumen.containsKey(e.key))
          .map((e) => e.value)
          .toList();
      if (kurang.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen wajib diunggah: ${kurang.join(', ')}'),
          ),
        );
        return;
      }

      setState(() => tahap = 3);
      return;
    }

    if (!formKey.currentState!.validate()) return;

    if (!setuju) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui syarat dan ketentuan.'),
        ),
      );
      return;
    }

    _kirim();
  }

  Future<void> _kirim() async {
    setState(() => mengirim = true);
    await AuthService.registerTeknisi(
      nama: nama.text,
      telepon: telepon.text,
      email: email.text,
      bank: bank,
      nomorRekening: nomorRekening.text,
      namaPemilik: namaPemilik.text,
      dokumen: dokumen,
    );
    // Email & nomor diingat supaya terisi otomatis di halaman Masuk.
    await SesiPengguna.simpanAkun(
      nama: nama.text,
      telepon: telepon.text,
      email: email.text,
    );
    if (!mounted) return;
    setState(() => mengirim = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pendaftaran berhasil'),
        content: const Text(
          'Akun kamu menunggu verifikasi Admin. Kami akan mengirim '
          'notifikasi setelah dokumenmu selesai diperiksa, biasanya '
          'dalam 1x24 jam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali ke Masuk'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> pilihDokumen(String jenis) async {
    final berkas = await Perangkat.ambilFoto();
    if (berkas == null || !mounted) return;
    if (await berkas.length() > maksUkuranByte) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran berkas maksimal 5 MB')),
      );
      return;
    }
    if (!mounted) return;
    setState(
      () => dokumen[jenis] = berkas.name.isEmpty
          ? 'Berkas terpilih'
          : berkas.name,
    );
  }

  void kembali() {
    if (tahap > 1) {
      setState(() => tahap--);
    } else {
      Navigator.maybePop(context);
    }
  }

  Widget input({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    bool passwordField = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            validator: validator ?? wajib,
            obscureText: passwordField && sembunyikanPassword,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
              prefixIcon: Icon(icon, color: AppColors.biru, size: 18),
              suffixIcon: passwordField
                  ? IconButton(
                      tooltip: sembunyikanPassword
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () {
                        setState(() {
                          sembunyikanPassword = !sembunyikanPassword;
                        });
                      },
                      icon: Icon(
                        sembunyikanPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                        color: AppColors.teksSamar,
                      ),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.biruGaris),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.biru, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.merah),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.merah),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tombol({
    required String teks,
    required VoidCallback aksi,
    bool utama = true,
  }) {
    return ElevatedButton(
      onPressed: mengirim ? null : aksi,
      style: ElevatedButton.styleFrom(
        backgroundColor: utama ? AppColors.biru : Colors.white,
        foregroundColor: utama ? Colors.white : AppColors.biru,
        elevation: utama ? 1 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: mengirim && utama
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(teks, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget uploadFoto({
    required String judul,
    required String? file,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file ?? 'Unggah $judul',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Foto JPG atau PNG | Maks. 5 MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.teksSamar,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tahapPertama() {
    return Column(
      children: [
        const Text(
          'ACare',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'Aplikasi Layanan AC yang Cepat dan Terpercaya',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 24),
        const Text(
          'Informasi Pribadi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        input(
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          icon: Icons.person_outline,
          controller: nama,
        ),
        input(
          label: 'Nomor telepon',
          hint: 'Masukkan nomor telepon',
          icon: Icons.phone_outlined,
          controller: telepon,
          keyboard: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nomor telepon wajib diisi';
            }
            if (!RegExp(r'^[0-9+ ]{8,16}$').hasMatch(value.trim())) {
              return 'Nomor telepon tidak valid';
            }
            return null;
          },
        ),
        input(
          label: 'Email',
          hint: 'Masukkan email',
          icon: Icons.mail_outline,
          controller: email,
          keyboard: TextInputType.emailAddress,
          validator: (value) {
            if (value == null ||
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
              return 'Email tidak valid';
            }
            return null;
          },
        ),
        input(
          label: 'Kata sandi',
          hint: 'Minimal 8 karakter',
          icon: Icons.lock_outline,
          controller: password,
          passwordField: true,
          validator: (value) {
            if (value == null || value.length < 8) {
              return 'Kata sandi minimal 8 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: tombol(teks: 'Selanjutnya', aksi: lanjut),
        ),
        const SizedBox(height: 14),
        const Text(
          'Dengan Mendaftar Anda Menyetujui',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const Text(
          'Syarat dan Ketentuan ACare',
          style: TextStyle(fontSize: 11, color: AppColors.biru),
        ),
      ],
    );
  }

  Widget tahapKedua() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Unggah Dokumen',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        for (final d in daftarDokumen.entries)
          uploadFoto(
            judul: d.value,
            file: dokumen[d.key],
            onTap: () => pilihDokumen(d.key),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.biruMuda,
            border: Border.all(color: AppColors.biruGaris),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ⓘ Tips',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.biru,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 7),
              Text(
                '• Semua dokumen harus jelas dan tidak buram',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                '• Foto dokumen secara utuh, tidak terpotong',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                '• Ukuran tiap berkas maksimal 5 MB',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tombol(teks: 'Kembali', aksi: kembali, utama: false),
            tombol(teks: 'Selanjutnya', aksi: lanjut),
          ],
        ),
      ],
    );
  }

  Widget tahapKetiga() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Data Rekening Bank',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Pilih Bank Penerima',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: bank,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.account_balance_outlined,
              color: AppColors.biru,
              size: 18,
            ),
            filled: true,
            fillColor: AppColors.biruMuda,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.biruGaris),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'BNI (Bank Negara Indonesia)',
              child: Text(
                'BNI (Bank Negara Indonesia)',
                style: TextStyle(fontSize: 11),
              ),
            ),
            DropdownMenuItem(
              value: 'BRI (Bank Rakyat Indonesia)',
              child: Text(
                'BRI (Bank Rakyat Indonesia)',
                style: TextStyle(fontSize: 11),
              ),
            ),
            DropdownMenuItem(
              value: 'BCA (Bank Central Asia)',
              child: Text(
                'BCA (Bank Central Asia)',
                style: TextStyle(fontSize: 11),
              ),
            ),
            DropdownMenuItem(
              value: 'Mandiri',
              child: Text('Mandiri', style: TextStyle(fontSize: 11)),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => bank = value);
          },
        ),
        const SizedBox(height: 15),
        input(
          label: 'Nomor Rekening',
          hint: 'Masukkan nomor rekening',
          icon: Icons.credit_card_outlined,
          controller: nomorRekening,
          keyboard: TextInputType.number,
        ),
        input(
          label: 'Nama Pemilik Rekening',
          hint: 'Masukkan nama pemilik rekening',
          icon: Icons.person_outline,
          controller: namaPemilik,
        ),
        const SizedBox(height: 8),
        // Material transparan supaya efek sentuh ListTile tidak tertutup
        // latar putih kartu (menghilangkan peringatan debug Flutter).
        Material(
          type: MaterialType.transparency,
          child: CheckboxListTile(
            value: setuju,
            onChanged: (value) {
              setState(() => setuju = value ?? false);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.biru,
            title: const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11, color: Colors.black54),
                children: [
                  TextSpan(text: 'Saya Menyetujui '),
                  TextSpan(
                    text: 'Syarat & Ketentuan Kemitraan Teknisi',
                    style: TextStyle(
                      color: AppColors.biru,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' serta '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: TextStyle(
                      color: AppColors.biru,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tombol(teks: 'Kembali', aksi: kembali, utama: false),
            tombol(teks: 'Registrasi', aksi: lanjut),
          ],
        ),
      ],
    );
  }

  Widget isiTahap() {
    switch (tahap) {
      case 1:
        return tahapPertama();
      case 2:
        return tahapKedua();
      default:
        return tahapKetiga();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: double.infinity,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _LatarPainter())),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 95, 18, 30),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(15, 22, 15, 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(key: formKey, child: isiTahap()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = AppColors.biru;
    final atas = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.62, 0)
      ..lineTo(0, size.height * 0.16)
      ..close();
    canvas.drawPath(atas, paint);

    paint.color = AppColors.biruGaris;
    final atasMuda = Path()
      ..moveTo(0, size.height * 0.07)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.04,
        size.width * 0.65,
        0,
      )
      ..lineTo(size.width * 0.82, 0)
      ..lineTo(0, size.height * 0.19)
      ..close();
    canvas.drawPath(atasMuda, paint);

    paint.color = AppColors.biru;
    final bawah = Path()
      ..moveTo(0, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.02,
        size.width,
        size.height * 0.87,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bawah, paint);

    paint.color = AppColors.biruGaris;
    final bawahMuda = Path()
      ..moveTo(0, size.height * 0.89)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height,
        size.width,
        size.height * 0.84,
      )
      ..lineTo(size.width, size.height * 0.93)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.04,
        0,
        size.height * 0.98,
      )
      ..close();
    canvas.drawPath(bawahMuda, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
