import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/coordonnateur_entities.dart';

/// Petite carte de statistique (ex: "12 Patients") pour la page d'accueil.
class StatCard extends StatelessWidget {
  final String valeur;
  final String libelle;
  final IconData icon;
  final Color couleur;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.valeur,
    required this.libelle,
    required this.icon,
    required this.couleur,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: couleur.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: couleur, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                valeur,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                libelle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre de section réutilisé sur toutes les pages coordonnateur.
class SectionTitle extends StatelessWidget {
  final String titre;
  final Widget? trailing;

  const SectionTitle({super.key, required this.titre, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(titre, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Badge/chip de statut réutilisé pour AVS et rapports.
class StatusChip extends StatelessWidget {
  final String label;
  final Color couleur;

  const StatusChip({super.key, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

extension StatutAvsX on StatutAvs {
  String get libelle => switch (this) {
    StatutAvs.disponible => 'Disponible',
    StatutAvs.enIntervention => 'En intervention',
    StatutAvs.absent => 'Absent',
  };

  Color get couleur => switch (this) {
    StatutAvs.disponible => AppColors.success,
    StatutAvs.enIntervention => AppColors.info,
    StatutAvs.absent => AppColors.textDisabled,
  };
}

extension StatutRapportX on StatutRapport {
  String get libelle => switch (this) {
    StatutRapport.enAttente => 'En attente',
    StatutRapport.valide => 'Validé',
    StatutRapport.rejete => 'Rejeté',
  };

  Color get couleur => switch (this) {
    StatutRapport.enAttente => AppColors.warning,
    StatutRapport.valide => AppColors.success,
    StatutRapport.rejete => AppColors.error,
  };
}

/// Petit avatar rond avec initiales, pour lignes de listes (patient/AVS).
class InitialsAvatar extends StatelessWidget {
  final String nomComplet;
  final Color? couleur;

  const InitialsAvatar({super.key, required this.nomComplet, this.couleur});

  String get _initiales {
    final mots = nomComplet.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = couleur ?? AppColors.primary;
    return CircleAvatar(
      radius: 20,
      backgroundColor: c.withOpacity(0.12),
      child: Text(_initiales, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }
}