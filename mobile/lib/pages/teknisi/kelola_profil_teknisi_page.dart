
import 'package:flutter/material.dart';

class KelolaProfilTeknisiPage extends StatefulWidget {
  const KelolaProfilTeknisiPage({super.key});

  @override
  State<KelolaProfilTeknisiPage> createState() =>
      _KelolaProfilTeknisiPageState();
}

class _KelolaProfilTeknisiPageState
    extends State<KelolaProfilTeknisiPage> {
  static const Color biru = Color(0xFF0788C9);
  static const Color abu = Color(0xFF777777);

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController(text: 'Dina Safitri');
  final _teleponController =
      TextEditingController(text: '083862865166');
  final _emailController =
      TextEditingController(text: 'dina.safitri@gmail.com');
  final _jenisController =
      TextEditingController(text: 'Mekanik AC');
  final _platController = TextEditingController(text: 'BP 676767');

  bool _modeEdit = false;

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _jenisController.dispose();
    _platController.dispose();
    super.dispose();
  }

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
      const SnackBar(
        content: Text('Perubahan profil berhasil disimpan.'),
      ),
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
      padding: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        controller: controller,
        readOnly: !_modeEdit,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 10),
          prefixIcon: Icon(icon, size: 15, color: abu),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFFDDE6ED),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: biru),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.red),
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
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title belum dihubungkan.')),
        );
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 9),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: color),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 15,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label,
      {bool aktif = false}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: aktif ? biru : Colors.grey,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: aktif ? biru : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Kelola Profil',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pencarian belum dihubungkan.'),
                ),
              );
            },
            icon: const Icon(Icons.search, size: 19),
            color: Colors.black54,
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bantuan belum dihubungkan.'),
                ),
              );
            },
            icon: const Icon(
              Icons.help_outline,
              size: 18,
            ),
            color: Colors.black54,
          ),
          const SizedBox(width: 4),
        ],
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
                          const CircleAvatar(
                            radius: 31,
                            backgroundColor: Color(0xFFE0E9F9),
                            child: Text(
                              'DS',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
                                color: biru,
                                size: 15,
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
                          fontSize: 13,
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
                    fontSize: 10,
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
                    fontSize: 10,
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

                Align(
                  alignment: Alignment.centerRight,
                  child: _modeEdit
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _modeEdit = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: biru,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 7),
                            ElevatedButton(
                              onPressed: _simpanProfil,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: biru,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _editProfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: biru,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Edit Profil',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _menuItem(
                        icon: Icons.lock_outline,
                        title: 'Ubah Kata Sandi',
                      ),
                      _menuItem(
                        icon: Icons.notifications_none,
                        title: 'Notifikasi',
                      ),
                      _menuItem(
                        icon: Icons.support_agent,
                        title: 'Pusat Bantuan',
                      ),
                      _menuItem(
                        icon: Icons.logout,
                        title: 'Keluar',
                        color: Colors.redAccent,
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Keluar'),
                                content: const Text(
                                  'Apakah kamu yakin ingin keluar?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Hubungkan aksi keluar '
                                            'ke proses logout aplikasi.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Keluar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 55,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        child: Row(
          children: [
            _bottomItem(Icons.home_outlined, 'Beranda'),
            _bottomItem(Icons.receipt_long_outlined, 'Pesanan'),
            _bottomItem(Icons.calendar_month_outlined, 'Dampat'),
            _bottomItem(
              Icons.person_outline,
              'Profil',
              aktif: true,
            ),
          ],
        ),
      ),
    );
  }
}
