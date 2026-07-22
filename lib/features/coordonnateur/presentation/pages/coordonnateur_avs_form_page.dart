import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';

/// Page plein écran (ouverte depuis le menu d'actions rapides ou depuis la
/// page Équipe).
///
/// NOTE(backend) : la création d'un compte personnel (AVS, médecin...) se
/// fait via `POST /auth/admin/personnel`, réservé au rôle **administrateur**
/// (voir `INTEGRATION.md`, section 5 — le coordonnateur, lui, gère patients /
/// affectations / personnel en LECTURE seule). Cette page reste donc pour
/// l'instant une invite à contacter un administrateur plutôt qu'un vrai
/// formulaire de création, pour ne pas donner l'illusion qu'un compte a été
/// créé alors qu'aucun endpoint accessible au coordonnateur ne le permet.
class CoordonnateurAvsFormPage extends StatelessWidget {
  const CoordonnateurAvsFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Ajouter un AVS'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Création réservée à l\'administrateur',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Les comptes du personnel (AVS, médecin…) sont créés par un compte administrateur. '
                'Demande à un administrateur de provisionner ce nouvel agent AVS ; il apparaîtra '
                'automatiquement dans l\'équipe une fois son compte créé.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
