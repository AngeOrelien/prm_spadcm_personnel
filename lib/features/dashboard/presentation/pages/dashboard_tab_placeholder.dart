import 'package:flutter/material.dart';

/// Contenu temporaire d'un onglet de dashboard : juste un texte centré.
/// Sera remplacé onglet par onglet par le vrai contenu (planning, liste de
/// patients, etc.) dans une prochaine itération.
class DashboardTabPlaceholder extends StatelessWidget {
  final String label;

  const DashboardTabPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
