import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/sesi_pengguna.dart';
import '../../services/teknisi_service.dart';
import '../pelanggan/pengaduan_page.dart';
import '../role_select_page.dart';
import '../umum/notifikasi_page.dart';
import '../umum/ubah_kata_sandi_page.dart';
import '../../theme/app_colors.dart';

class KelolaProfilTeknisiPage extends StatefulWidget {
  const KelolaProfilTeknisiPage({super.key});

  @override
  State<KelolaProfilTeknisiPage> createState() =>
      _KelolaProfilTeknisiPageState();
}

class _KelolaProfilTeknisiPageState extends State<KelolaProfilTeknisiPage> {
  final _formKey = GlobalKey<FormState>();

  // TODO(backend): isi dari data profil teknisi di API. Sementara data contoh.
  final _namaController = TextEditingController(text: 'Teknisi Contoh');
  final _teleponController = TextEditingController(text: '081200000003');
  final _emailController = TextEditingController(text: 'teknisi@acare.id');
  final _jenisController = TextEditingController(text: 'Mekanik AC');
  final _platController = TextEditingController(text: 'BP 1234 AC');

  bool _modeEdit = false;

  /// Inisial untuk avatar, misal "Teknisi Contoh" -> "TC".
  static String _inisial(String nama) {
    final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty);
    if (kata.isEmpty) return '?';
    return kata.take(2).map((k) => k[0].toUpperCase()).join();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _jenisController.dispose();
    _platController.dispose();
    super.dispose();
  }

  void _buka(Widget halaman) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));

  void _editProfil() {
    setState(() {
      _modeEdit = true;
    });
  }

  void _simpanProfil() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _modeEdit = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan profil berhasil disimpan.')),
    );
  }

  Future<void> _konfirmasiKeluar() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.merah),
            ),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;

    await AuthService.logout();
    TeknisiService.instance.reset();
    await SesiPengguna.keluar();
    if (!mounted) return;
    // Kembali ke pemilihan peran, sama seperti saat pertama membuka aplikasi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectPage()),
      (_) => false,
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        readOnly: !_modeEdit,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.teksSamar),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: AppColors.teksSamar),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.garis),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.biru),
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
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    Color color = Colors.black54,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title belum dihubungkan.')),
            );
          },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.garisLembut)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 14, color: color)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kelola Profil',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.biruMuda,
                            child: Text(
                              _inisial(_namaController.text),
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -1,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.biru,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _namaController.text.isEmpty
                            ? 'Nama Teknisi'
                            : _namaController.text,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),

                _field(
                  label: 'Nama Lengkap',
                  hint: 'Nama lengkap',
                  icon: Icons.person_outline,
                  controller: _namaController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                _field(
                  label: 'Nomor Telepon',
                  hint: 'Nomor telepon',
                  icon: Icons.phone_outlined,
                  controller: _teleponController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor telepon wajib diisi';
                    }
                    return null;
                  },
                ),
                _field(
                  label: 'Email',
                  hint: 'Email',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 5),
                const Text(
                  'Informasi Teknisi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),

                _field(
                  label: 'Jenis Teknisi',
                  hint: 'Jenis teknisi',
                  icon: Icons.home_repair_service_outlined,
                  controller: _jenisController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jenis teknisi wajib diisi';
                    }
                    return null;
                  },
                ),
                _field(
                  label: 'Nomor Kendaraan',
                  hint: 'Nomor kendaraan',
                  icon: Icons.motorcycle_outlined,
                  controller: _platController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor kendaraan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 5),

                SizedBox(
                  width: double.infinity,
                  child: _modeEdit
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _modeEdit = false;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.biru,
                                  minimumSize: const Size(0, 46),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _simpanProfil,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.biru,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 46),
                                ),
                                child: const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _editProfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.biru,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          child: const Text(
                            'Edit Profil',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.garisLembut),
                  ),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.lock_outline,
                        title: 'Ubah Kata Sandi',
                        onTap: () => _buka(const UbahKataSandiPage()),
                      ),
                      _menuItem(
                        icon: Icons.notifications_none,
                        title: 'Notifikasi',
                        onTap: () => _buka(const NotifikasiPage()),
                      ),
                      _menuItem(
                        icon: Icons.support_agent,
                        title: 'Pusat Bantuan',
                        onTap: () => _buka(const PengaduanPage()),
                      ),
                      _menuItem(
                        icon: Icons.logout,
                        title: 'Keluar',
                        color: AppColors.merah,
                        onTap: _konfirmasiKeluar,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Navigasi bawah disediakan oleh TeknisiShell.
    );
  }
}
