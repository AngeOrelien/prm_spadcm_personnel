import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Petit bouton circulaire icône (ex: chevron retour en haut des écrans de
/// connexion). Réutilisable partout où ce style de bouton apparaît.
class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const AppCircleIconButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
