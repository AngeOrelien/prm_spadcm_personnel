import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ simple pour un code à 6 chiffres. Volontairement basique (un seul
/// TextFormField) pour démarrer vite ; pourra être remplacé plus tard par
/// 6 cases séparées si le design l'exige.
class OtpCodeField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const OtpCodeField({super.key, required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      autofocus: true,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        counterText: '',
        border: OutlineInputBorder(),
        hintText: '••••••',
      ),
    );
  }
}
