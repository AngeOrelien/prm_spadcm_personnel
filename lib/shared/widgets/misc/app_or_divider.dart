import 'package:flutter/material.dart';

/// Séparateur "─── Ou continuer avec ───" utilisé entre le formulaire
/// principal et les boutons de connexion tierce.
class AppOrDivider extends StatelessWidget {
  final String label;

  const AppOrDivider({super.key, this.label = 'Ou continuer avec'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
