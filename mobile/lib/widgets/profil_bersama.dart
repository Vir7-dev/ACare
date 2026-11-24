import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Komponen halaman profil yang dipakai bersama oleh Pelanggan dan Teknisi,
/// supaya kedua peran punya tampilan dan cara edit yang sama.

/// Inisial untuk avatar, misal "Dina Safitri" -> "DS".
String inisialNama(String nama) {
  final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty);
  if (kata.isEmpty) return '?';
  return kata.take(2).map((k) => k[0].toUpperCase()).join();
}

/// Avatar, tombol ganti foto, nama, dan keterangan peran.
class KepalaProfil extends StatelessWidget {
  final String nama;
  final String keterangan;
  final Uint8List? foto;
  final VoidCallback? onGantiFoto;

  const KepalaProfil({
    super.key,
    required this.nama,
    required this.keterangan,
    this.foto,
    this.onGantiFoto,
  });

  @override
  Widget build(BuildContext context) {
    final tampilNama = nama.trim().isEmpty ? 'Lengkapi nama kamu' : nama;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.biruMuda,
              backgroundImage: foto == null ? null : MemoryImage(foto!),
              child: foto != null
                  ? null
                  : nama.trim().isEmpty
                  ? const Icon(Icons.person, size: 40, color: AppColors.biru)
                  : Text(
                      inisialNama(nama),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.biruTua,
                      ),
                    ),
            ),
            if (onGantiFoto != null)
              // Lingkaran 32 px, area sentuh 48 px; digeser ke luar avatar
              // agar tidak menutupi inisial.
              Positioned(
                right: -14,
                bottom: -14,
                child: Tooltip(
                  message: 'Ganti foto profil',
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onGantiFoto,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.garisLembut),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                              color: AppColors.biru,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          tampilNama,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: nama.trim().isEmpty ? AppColors.teksSamar : AppColors.teks,
          ),
        ),
        Text(
          keterangan,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.teksSamar,
          ),
        ),
      ],
    );
  }
}

/// Judul kecil di atas sekelompok isian atau menu.
class JudulBagianProfil extends StatelessWidget {
  final String teks;

  const JudulBagianProfil(this.teks, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        teks,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.teks,
        ),
      ),
    );
  }
}

/// Kolom data profil dengan label. Terkunci sampai pengguna menekan
/// "Edit Profil".
class IsianProfil extends StatelessWidget {
  final String label;
  final IconData ikon;
  final TextEditingController controller;
  final bool bisaDiubah;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  /// Jumlah baris untuk isian panjang, misal "Tentang Saya".
  final int baris;

  const IsianProfil({
    super.key,
    required this.label,
    required this.ikon,
    required this.controller,
    required this.bisaDiubah,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.baris = 1,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder garis(Color warna) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: warna),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: !bisaDiubah,
        keyboardType: baris > 1 ? TextInputType.multiline : keyboardType,
        minLines: 1,
        maxLines: baris,
        validator: validator,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.teks),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.teksSamar,
          ),
          hintText: 'Belum diisi',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.teksNonaktif,
          ),
          prefixIcon: Icon(ikon, size: 20, color: AppColors.teksSamar),
          filled: true,
          fillColor: bisaDiubah ? Colors.white : AppColors.latar,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          enabledBorder: garis(AppColors.garis),
          focusedBorder: garis(AppColors.biru),
          errorBorder: garis(AppColors.merah),
          focusedErrorBorder: garis(AppColors.merah),
        ),
      ),
    );
  }
}

/// Tombol "Edit Profil", atau "Batal" + "Simpan Perubahan" saat mengedit.
class TombolEditProfil extends StatelessWidget {
  final bool modeEdit;
  final VoidCallback onEdit;
  final VoidCallback onBatal;
  final VoidCallback onSimpan;

  const TombolEditProfil({
    super.key,
    required this.modeEdit,
    required this.onEdit,
    required this.onBatal,
    required this.onSimpan,
  });

  @override
  Widget build(BuildContext context) {
    if (!modeEdit) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Profil'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.biru,
            side: const BorderSide(color: AppColors.biru),
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBatal,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teksSamar,
              side: const BorderSide(color: AppColors.garis),
            ),
            child: const Text('Batal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: onSimpan,
            style: FilledButton.styleFrom(backgroundColor: AppColors.biru),
            child: const Text('Simpan Perubahan'),
          ),
        ),
      ],
    );
  }
}

/// Satu baris menu pengaturan.
class ItemMenuProfil {
  final IconData ikon;
  final String label;
  final VoidCallback onTap;
  final bool bahaya;

  const ItemMenuProfil({
    required this.ikon,
    required this.label,
    required this.onTap,
    this.bahaya = false,
  });
}

/// Daftar menu pengaturan dalam satu kartu, dipisah garis tipis.
class KartuMenuProfil extends StatelessWidget {
  final List<ItemMenuProfil> menu;

  const KartuMenuProfil({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.garisLembut),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < menu.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 52,
                color: AppColors.garisLembut,
              ),
            ListTile(
              onTap: menu[i].onTap,
              minTileHeight: 52,
              leading: Icon(
                menu[i].ikon,
                size: 22,
                color: menu[i].bahaya ? AppColors.merah : AppColors.teksSamar,
              ),
              title: Text(
                menu[i].label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: menu[i].bahaya ? AppColors.merah : AppColors.teks,
                ),
              ),
              trailing: menu[i].bahaya
                  ? null
                  : const Icon(
                      Icons.chevron_right,
                      color: AppColors.teksNonaktif,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
