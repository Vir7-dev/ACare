
import 'package:flutter/material.dart';

class RegistrasiTeknisiPage extends StatefulWidget {
  const RegistrasiTeknisiPage({super.key});

  @override
  State<RegistrasiTeknisiPage> createState() =>
      _RegistrasiTeknisiPageState();
}

class _RegistrasiTeknisiPageState
    extends State<RegistrasiTeknisiPage> {
  static const Color biru = Color(0xFF0788D1);
  static const Color biruMuda = Color(0xFFB9DFFF);

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
  String? fotoKtp;
  String? fotoSelfie;

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
      if (fotoKtp == null || fotoSelfie == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Silakan lengkapi foto KTP dan foto selfie.',
            ),
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
          content: Text(
            'Anda harus menyetujui syarat dan ketentuan.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrasi Berhasil'),
        content: const Text(
          'Data sudah diperiksa. Hubungkan proses ini '
          'ke backend untuk menyimpan data teknisi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Colors.black38,
              ),
              prefixIcon: Icon(icon, color: biru, size: 18),
              suffixIcon: passwordField
                  ? IconButton(
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
                        color: Colors.grey,
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
                borderSide: const BorderSide(
                  color: Color(0xFF80C9F5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: biru,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
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
      onPressed: aksi,
      style: ElevatedButton.styleFrom(
        backgroundColor: utama ? biru : Colors.white,
        foregroundColor: utama ? Colors.white : biru,
        elevation: utama ? 1 : 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 12),
      ),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
                          'Format JPG, PNG, PDF | Maks. 5MB',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
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
          style: TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 24),
        const Text(
          'Informasi Pribadi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
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
          label: 'Gmail',
          hint: 'Masukkan Gmail',
          icon: Icons.mail_outline,
          controller: email,
          keyboard: TextInputType.emailAddress,
          validator: (value) {
            if (value == null ||
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value.trim())) {
              return 'Email tidak valid';
            }
            return null;
          },
        ),
        input(
          label: 'Verifikasi kata sandi',
          hint: 'Masukkan kata sandi',
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
          child: tombol(
            teks: 'Selanjutnya',
            aksi: lanjut,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Dengan Mendaftar Anda Menyetujui',
          style: TextStyle(fontSize: 10, color: Colors.black45),
        ),
        const Text(
          'Syarat dan Ketentuan ACare',
          style: TextStyle(fontSize: 10, color: biru),
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
            'Informasi Tambahan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        uploadFoto(
          judul: 'Foto KTP',
          file: fotoKtp,
          onTap: () {
            setState(() => fotoKtp = 'KTP dipilih (contoh)');
          },
        ),
        uploadFoto(
          judul: 'Foto Selfie dengan KTP',
          file: fotoSelfie,
          onTap: () {
            setState(() => fotoSelfie = 'Foto selfie dipilih (contoh)');
          },
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6FF),
            border: Border.all(color: biruMuda),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ⓘ Tips Foto',
                style: TextStyle(
                  fontSize: 12,
                  color: biru,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 7),
              Text(
                '• Pastikan foto terang dan jelas',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
              Text(
                '• KTP terlihat penuh dan tidak terpotong',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
              Text(
                '• Wajah dan data pada KTP dapat terbaca',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tombol(
              teks: 'Kembali',
              aksi: kembali,
              utama: false,
            ),
            tombol(
              teks: 'Selanjutnya',
              aksi: lanjut,
            ),
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Pilih Bank Penerima',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: bank,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.account_balance_outlined,
              color: biru,
              size: 18,
            ),
            filled: true,
            fillColor: const Color(0xFFF0F6FF),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: biruMuda),
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
              child: Text(
                'Mandiri',
                style: TextStyle(fontSize: 11),
              ),
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
        CheckboxListTile(
          value: setuju,
          onChanged: (value) {
            setState(() => setuju = value ?? false);
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: biru,
          title: const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 10, color: Colors.black54),
              children: [
                TextSpan(text: 'Saya Menyetujui '),
                TextSpan(
                  text: 'Syarat & Ketentuan Kemitraan Teknisi',
                  style: TextStyle(
                    color: biru,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' serta '),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: TextStyle(
                    color: biru,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tombol(
              teks: 'Kembali',
              aksi: kembali,
              utama: false,
            ),
            tombol(
              teks: 'Registrasi',
              aksi: lanjut,
            ),
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
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LatarPainter(),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 95, 18, 30),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            15, 22, 15, 18,
                          ),
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
                          child: Form(
                            key: formKey,
                            child: isiTahap(),
                          ),
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

    paint.color = const Color(0xFF087BEA);
    final atas = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.62, 0)
      ..lineTo(0, size.height * 0.16)
      ..close();
    canvas.drawPath(atas, paint);

    paint.color = const Color(0xFFB9DFFF);
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

    paint.color = const Color(0xFF087BEA);
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

    paint.color = const Color(0xFFB9DFFF);
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
