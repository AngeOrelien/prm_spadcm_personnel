import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Petite carte de statistique (ex: "12 Patients") réutilisée par tous les
/// dashboards de rôle (Coordonnateur, AVS, Administrateur, Médecin).
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

/// Titre de section réutilisé sur toutes les pages de dashboard.
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

/// Badge/chip de statut générique (rapports, présences, paiements...).
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

/// Petit avatar rond avec initiales, pour lignes de listes.
class InitialsAvatar extends StatelessWidget {
  final String nomComplet;
  final Color? couleur;
  final double radius;

  const InitialsAvatar({super.key, required this.nomComplet, this.couleur, this.radius = 20});

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
      radius: radius,
      backgroundColor: c.withOpacity(0.12),
      child: Text(_initiales, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

/// Carte "vide" réutilisée (aucune donnée / erreur de chargement) pour éviter
/// de réécrire le même bloc dans chaque page.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String message;
  final Widget? action;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.titre,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(titre, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Bloc d'erreur de chargement générique, avec bouton "Réessayer".
class ErreurChargement extends StatelessWidget {
  final VoidCallback onReessayer;

  const ErreurChargement({super.key, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyStateCard(
        icon: Icons.wifi_off_outlined,
        titre: 'Impossible de charger les données',
        message: 'Vérifie ta connexion puis réessaie.',
        action: FilledButton.tonal(onPressed: onReessayer, child: const Text('Réessayer')),
      ),
    );
  }
}
