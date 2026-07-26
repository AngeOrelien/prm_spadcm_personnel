import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/app_dashboard_header.dart';

/// Contenu temporaire d'un onglet de dashboard : header personnalisé (titre =
/// libellé de l'onglet) + texte centré. Sera remplacé onglet par onglet par
/// le vrai contenu (planning, liste de patients, etc.) dans une prochaine
/// itération — voir le feature `coordonnateur` pour un exemple complet.
///
/// Enveloppé dans un [Scaffold] : ce widget est utilisé à la fois comme
/// contenu d'onglet (déjà sur le Scaffold de `RoleDashboardShell`, la
/// double imbrication est inoffensive) ET comme page plein écran poussée
/// hors du shell (ex. profil médecin/administrateur, voir `app_router.dart`)
/// — sans ce Scaffold, ces pages poussées n'avaient aucun fond derrière
/// leur contenu et s'affichaient sur un écran noir (cf. le même correctif
/// sur `AvsProfilPage`/`CoordonnateurProfilPage`).
class DashboardTabPlaceholder extends StatelessWidget {
  final String label;
  final bool showBackButton;

  const DashboardTabPlaceholder({super.key, required this.label, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppDashboardHeader.page(title: label, showBackButton: showBackButton),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
        ],
      ),
    );
  }
}
