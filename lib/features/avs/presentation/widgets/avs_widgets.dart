import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
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

/// Ligne "visite" du planning (patient + adresse + créneau + statut).
class VisiteTile extends StatelessWidget {
  final VisitePlanifiee visite;
  final VoidCallback? onTap;

  const VisiteTile({super.key, required this.visite, this.onTap});

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
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: visite.terminee ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visite.patientNom,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (visite.adressePatient.isNotEmpty)
                        Text(visite.adressePatient, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(visite.creneauLibelle, style: Theme.of(context).textTheme.bodySmall),
                    if (visite.terminee)
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                    else
                      const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
