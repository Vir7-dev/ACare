import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool password;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.password = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _sembunyi = true;

  OutlineInputBorder _border(Color warna) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: warna),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.password && _sembunyi,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.teksSamar),
        prefixIcon: Icon(widget.icon, color: AppColors.teksSamar, size: 22),
        suffixIcon: widget.password
            ? IconButton(
                icon: Icon(
                  _sembunyi
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.teksSamar,
                  size: 20,
                ),
                onPressed: () => setState(() => _sembunyi = !_sembunyi),
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.biru),
        errorBorder: _border(Colors.red.shade400),
        focusedErrorBorder: _border(Colors.red.shade400),
      ),
    );
  }
}
