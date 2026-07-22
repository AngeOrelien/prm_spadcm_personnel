import 'package:flutter/material.dart';
import 'package:prm_spadcm_personnel/core/theme/app_colors.dart';
import 'package:prm_spadcm_personnel/shared/widgets/misc/app_circle_icon_button.dart';

import '../../../core/theme/app_dimens.dart';

/// Écran de messagerie — pour l'instant un simple stub affichant
/// l'interlocuteur visé (patient ou AVS). Le vrai fil de discussion sera
/// développé plus tard, branché sur `/api/conversations` (déjà disponible
/// côté backend — voir `INTEGRATION.md`, section Messagerie).
class MessagerieStubPage extends StatelessWidget {
  final String interlocuteurNom;
  final String? interlocuteurSousTitre;

  const MessagerieStubPage({
    super.key,
    required this.interlocuteurNom,
    this.interlocuteurSousTitre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(interlocuteurNom, style: const TextStyle(fontSize: 16)),
            if (interlocuteurSousTitre != null)
              Text(
                interlocuteurSousTitre!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        titleSpacing: 0,
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
                child: const Icon(Icons.forum_outlined, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Messagerie bientôt disponible',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'La discussion avec $interlocuteurNom sera activée dans une prochaine mise à jour.',
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
