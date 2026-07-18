import 'package:flutter/material.dart';

/// Champ de texte générique de l'app. Toutes les variantes (email, texte
/// simple, mot de passe via [AppPasswordField]) passent par ce widget pour
/// garder un style unique (voir `AppTheme.inputDecorationTheme`).
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool autofocus;
  final int? maxLength;
  final TextAlign textAlign;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLength: maxLength,
      textAlign: textAlign,
      obscureText: obscureText,
      enabled: enabled,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
