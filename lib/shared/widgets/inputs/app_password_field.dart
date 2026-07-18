import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// Champ mot de passe réutilisable : icône cadenas + bouton "œil" pour
/// afficher/masquer la saisie. S'appuie sur [AppTextField] pour garder un
/// style cohérent avec le reste des formulaires.
class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool autofocus;

  const AppPasswordField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      validator: widget.validator,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      prefixIcon: Icons.lock_outline,
      textInputAction: widget.textInputAction,
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
