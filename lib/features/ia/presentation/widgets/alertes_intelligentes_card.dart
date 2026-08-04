import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/ia_entities.dart';
import '../providers/ia_providers.dart';

/// Anomalies proposées par le service IA pour un patient
/// (`POST /api/ia/alertes-intelligentes`, voir `alertesIntelligentesProvider`)
/// — reste une PROPOSITION à valider par un humain : ce widget n'envoie
/// jamais d'alerte lui-même, il affiche seulement de quoi décider vite
/// (voir bouton "Créer une alerte" qui doit rester câblé au flux
/// `POST /api/alertes` existant, pas à ce widget).
class AlertesIntelligentesCard extends ConsumerWidget {
  final String patientId;

  /// Appelé quand l'utilisateur choisit de transformer une anomalie en
  /// vraie alerte (flux `POST /api/alertes` classique, hors service IA).
  final void Function(AnomalieDetectee anomalie)? onCreerAlerte;

  const AlertesIntelligentesCard({super.key, required this.patientId, this.onCreerAlerte});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertesIntelligentesProvider(patientId));

    return async.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textDisabled, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                e is AppException ? e.message : 'Analyse indisponible pour le moment',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(alertesIntelligentesProvider(patientId)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (alertes) {
        if (alertes.anomalies.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Aucune anomalie détectée sur les derniers relevés.', style: TextStyle(fontSize: 13))),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomalies détectées (${alertes.anomalies.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...alertes.anomalies.map((a) => _CarteAnomalie(anomalie: a, onCreerAlerte: onCreerAlerte)),
          ],
        );
      },
    );
  }
}

class _CarteAnomalie extends StatelessWidget {
  final AnomalieDetectee anomalie;
  final void Function(AnomalieDetectee anomalie)? onCreerAlerte;

  const _CarteAnomalie({required this.anomalie, this.onCreerAlerte});

  (Color, IconData) get _styleGravite => switch (anomalie.gravite) {
        GraviteAnomalie.urgent => (AppColors.error, Icons.warning_amber_rounded),
        GraviteAnomalie.attention => (AppColors.warning, Icons.info_outline),
        GraviteAnomalie.info => (AppColors.info, Icons.info_outline),
      };

  @override
  Widget build(BuildContext context) {
    final (couleur, icone) = _styleGravite;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: couleur.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: couleur, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${anomalie.champ} — ${anomalie.valeur}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
              if (anomalie.source == 'modele')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accentSurface, borderRadius: BorderRadius.circular(4)),
                  child: const Text('modèle IA', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(anomalie.explication, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3)),
          const SizedBox(height: 4),
          Text('Référence : ${anomalie.seuilReference}', style: const TextStyle(fontSize: 11, color: AppColors.textDisabled)),
          if (onCreerAlerte != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onCreerAlerte!(anomalie),
                icon: const Icon(Icons.add_alert_outlined, size: 16),
                label: const Text('Créer une alerte'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
