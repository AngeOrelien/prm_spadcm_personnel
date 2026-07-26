import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../domain/entities/avs_entities.dart';

extension StatutPresenceX on StatutPresence {
  String get libelle => switch (this) {
    StatutPresence.enAttente => 'En attente',
    StatutPresence.aLheure => 'À l\'heure',
    StatutPresence.enRetard => 'En retard',
    StatutPresence.absent => 'Absent',
  };

  Color get couleur => switch (this) {
    StatutPresence.enAttente => AppColors.textDisabled,
    StatutPresence.aLheure => AppColors.success,
    StatutPresence.enRetard => AppColors.warning,
    StatutPresence.absent => AppColors.error,
  };
}

/// Ligne compacte "patient" (nom + pathologie/adresse + chevron), réutilisée
/// sur l'accueil (teaser) et dans les listes de patients de l'AVS.
class PatientSummaryTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback? onTap;

  const PatientSummaryTile({super.key, required this.patient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                InitialsAvatar(nomComplet: patient.nomComplet, photoUrl: patient.photoUrl, couleur: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.nomComplet,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (patient.pathologie.isNotEmpty)
                        Text(patient.pathologie, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
