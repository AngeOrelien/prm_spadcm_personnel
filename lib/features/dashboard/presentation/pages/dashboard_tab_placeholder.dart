import 'package:flutter/material.dart';

import '../widgets/app_dashboard_header.dart';

/// Contenu temporaire d'un onglet de dashboard : header personnalisé (titre =
/// libellé de l'onglet) + texte centré. Sera remplacé onglet par onglet par
/// le vrai contenu (planning, liste de patients, etc.) dans une prochaine
/// itération — voir le feature `coordonnateur` pour un exemple complet.
class DashboardTabPlaceholder extends StatelessWidget {
  final String label;

  const DashboardTabPlaceholder({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppDashboardHeader.page(title: label),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
      ],
    );
  }
}
