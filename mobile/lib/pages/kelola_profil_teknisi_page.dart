
import 'package:flutter/material.dart';

class KelolaProfilTeknisiPage extends StatefulWidget {
  const KelolaProfilTeknisiPage({super.key});

  @override
  State<KelolaProfilTeknisiPage> createState() =>
      _KelolaProfilTeknisiPageState();
}

class _KelolaProfilTeknisiPageState
    extends State<KelolaProfilTeknisiPage> {
  static const Color biru = Color(0xFF078AC7);
  static const Color garis = Color(0xFFD6E2FA);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaController =
      TextEditingController(text: 'Dina Safitri');
  final TextEditingController teleponController =
      TextEditingController(text: '083862865166');
  final TextEditingController emailController =
      TextEditingController(text: 'sdina3066@gmail.com');
  final TextEditingController kendaraanController =
      TextEditingController(text: 'Motor BEAT');
  final TextEditingController platController =
      TextEditingController(text: 'BP 676767');

  int menuAktif = 3;

  @override
  void dispose() {
    namaController.dispose();
    teleponController.dispose();
    emailController.dispose();
    kendaraanController.dispose();
    platController.dispose();
    super.dispose();
  }

  void simpanPerubahan() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perubahan berhasil disimpan (contoh tampilan).',
          ),
          backgroundColor: biru,
        ),
      );
    }
  }

  void bukaMenu(String judul) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$judul belum tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263746),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Kelola Profil',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => bukaMenu('Pencarian'),
            icon: const Icon(Icons.search, size: 22),
          ),
          IconButton(
            onPressed: () => bukaMenu('Pusat bantuan'),
            icon: const Icon(
              Icons.help_outline,
              size: 21,
            ),
          ),
          const SizedBox(width: 5),
        ],
        shape: const Border(
          bottom: BorderSide(color: biru, width: 2),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(17, 25, 17, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto dan nama teknisi
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Color(0xFFE2EAFB),
                            child: Text(
                              'DS',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF263746),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -4,
                            bottom: -1,
                            child: InkWell(
                              onTap: () => bukaMenu('Ganti foto'),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDDE9FC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: Color(0xFF263746),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: namaController,
                        builder: (context, value, child) {
                          return Text(
                            value.text.isEmpty
                                ? 'Nama Teknisi'
                                : value.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF20252B),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                _judulBagian('Informasi Akun'),

                _inputProfil(
                  controller: namaController,
                  icon: Icons.person_outline,
                  hint: 'Nama lengkap',
                ),
                _inputProfil(
                  controller: teleponController,
                  icon: Icons.phone_outlined,
                  hint: 'Nomor telepon',
                  keyboardType: TextInputType.phone,
                ),
                _inputProfil(
                  controller: emailController,
                  icon: Icons.mail_outline,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 7),
                _judulBagian('Informasi Teknisi'),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _inputProfil(
                        controller: kendaraanController,
                        icon: Icons.two_wheeler_outlined,
                        hint: 'Kendaraan',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _inputProfil(
                        controller: platController,
                        icon: Icons.directions_car_outlined,
                        hint: 'Nomor polisi',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 43,
                  child: ElevatedButton(
                    onPressed: simpanPerubahan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: biru,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 29),

                const Padding(
                  padding: EdgeInsets.only(left: 3, bottom: 14),
                  child: Text(
                    'Pengaturan Akun',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: garis),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _itemPengaturan(
                        Icons.lock_outline,
                        'Ubah Kata Sandi',
                        onTap: () => bukaMenu('Ubah Kata Sandi'),
                      ),
                      _itemPengaturan(
                        Icons.notifications_none,
                        'Notifikasi',
                        onTap: () => bukaMenu('Notifikasi'),
                      ),
                      _itemPengaturan(
                        Icons.help_outline,
                        'Pusat Bantuan',
                        onTap: () => bukaMenu('Pusat Bantuan'),
                      ),
                      _itemPengaturan(
                        Icons.logout,
                        'Keluar',
                        warna: Colors.redAccent,
                        tampilGaris: false,
                        onTap: () => _konfirmasiKeluar(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Navigasi bawah
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                _itemNavigasi(
                  Icons.home_outlined,
                  'Beranda',
                  0,
                ),
                _itemNavigasi(
                  Icons.assignment_outlined,
                  'Pesanan',
                  1,
                ),
                _itemNavigasi(
                  Icons.account_balance_wallet_outlined,
                  'Dompet',
                  2,
                ),
                _itemNavigasi(
                  Icons.person_outline,
                  'Profil',
                  3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _judulBagian(String judul) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 5),
      child: Text(
        judul,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _inputProfil({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 37,
      margin: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF454545),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Bagian ini wajib diisi';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            size: 16,
            color: const Color(0xFF60666C),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 37,
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 10,
            color: Color(0xFF777777),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: garis),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: garis),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: biru),
          ),
          errorStyle: const TextStyle(fontSize: 9),
        ),
      ),
    );
  }

  Widget _itemPengaturan(
    IconData icon,
    String judul, {
    Color warna = const Color(0xFF60666C),
    bool tampilGaris = true,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  Icon(icon, size: 15, color: warna),
                  const SizedBox(width: 9),
                  Text(
                    judul,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: warna == Colors.redAccent
                          ? Colors.redAccent
                          : const Color(0xFF555555),
                    ),
                  ),
                  const Spacer(),
                  if (judul != 'Keluar')
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFFB0B0B0),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (tampilGaris)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFBDBDBD),
          ),
      ],
    );
  }

  Widget _itemNavigasi(
    IconData icon,
    String judul,
    int index,
  ) {
    final aktif = menuAktif == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => menuAktif = index);

          if (index != 3) {
            bukaMenu(judul);
          }
        },
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: aktif
                    ? biru
                    : const Color(0xFF59616D),
              ),
              const SizedBox(height: 2),
              Text(
                judul,
                style: TextStyle(
                  fontSize: 9,
                  color: aktif
                      ? biru
                      : const Color(0xFF59616D),
                  fontWeight:
                      aktif ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _konfirmasiKeluar() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun teknisi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bukaMenu('Keluar');
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
