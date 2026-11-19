import 'package:flutter/material.dart';

/// Placeholder pendaftaran akun pelanggan.
class DaftarPelangganPage extends StatelessWidget {
  const DaftarPelangganPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO registrasi pelanggan: ganti placeholder ini dengan form pendaftaran
    // pelanggan (nama, telepon, email, kata sandi) lalu panggil AuthService.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pelanggan'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pendaftaran pelanggan segera hadir.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
