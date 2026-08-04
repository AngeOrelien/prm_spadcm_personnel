import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/ia_entities.dart';
import '../providers/ia_providers.dart';

/// Classement de performance des AVS (`POST /api/ia/performance-avs`, voir
/// `performanceAvsProvider`) — barres horizontales triées par score
/// décroissant, avec le détail des composantes (ponctualité rapports,
/// présence, appréciations) au clic.
///
/// Réservé côté backend à coordonnateur/administrateur pour la vue
/// classement complet (`avsId: null`) ; un compte AVS reçoit uniquement
/// son propre score quel que soit `avsId` passé (voir `iaController.js`)
/// — pour ce cas, préférer [ScoreAvsPersonnelCard] ci-dessous plutôt que
/// ce classement.
class PerformanceAvsLeaderboard extends ConsumerWidget {
  final int jours;

  const PerformanceAvsLeaderboard({super.key, this.jours = 30});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(performanceAvsProvider((avsId: null, jours: jours)));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: async.when(
        loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 28, color: AppColors.textDisabled),
              const SizedBox(height: AppSpacing.xs),
              Text(
                e is AppException ? e.message : 'Classement indisponible pour le moment',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => ref.invalidate(performanceAvsProvider((avsId: null, jours: jours))),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (performance) => _Contenu(performance: performance, jours: jours),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  final PerformanceAvs performance;
  final int jours;

  const _Contenu({required this.performance, required this.jours});

  @override
  Widget build(BuildContext context) {
    final resultats = [...performance.resultats]..sort((a, b) => b.scoreGlobal.compareTo(a.scoreGlobal));

    if (resultats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text('Aucune donnée de performance sur cette période.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance des AVS · $jours derniers jours', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppSpacing.md),
        ...resultats.take(10).map((s) => _LigneAvs(score: s)),
      ],
    );
  }
}

class _LigneAvs extends StatelessWidget {
  final ScoreAvs score;

  const _LigneAvs({required this.score});

  Color get _couleur {
    if (score.scoreGlobal >= 80) return AppColors.success;
    if (score.scoreGlobal >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => _afficherDetail(context),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                score.nomComplet ?? score.avsId,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 14,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.start,
                      maxY: 100,
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                            toY: score.scoreGlobal,
                            color: _couleur,
                            width: 14,
                            borderRadius: BorderRadius.zero,
                            backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: AppColors.surfaceMuted),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 40,
              child: Text(
                score.scoreGlobal.toStringAsFixed(0),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _couleur),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(score.nomComplet ?? score.avsId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            _LigneDetail('Score global', '${score.scoreGlobal.toStringAsFixed(0)}/100'),
            _LigneDetail('Ponctualité rapports', '${score.tauxPonctualiteRapports.toStringAsFixed(0)}%'),
            _LigneDetail('Présence à l\'heure', '${score.tauxPresenceATemps.toStringAsFixed(0)}%'),
            if (score.noteMoyenneAppreciations != null)
              _LigneDetail('Note moyenne des appréciations', '${score.noteMoyenneAppreciations!.toStringAsFixed(1)}/5'),
            if (score.scoreModele != null)
              _LigneDetail('Note prédite par le modèle entraîné', '${score.scoreModele!.toStringAsFixed(1)}/5'),
            _LigneDetail('Rapports / présences / appréciations', '${score.nombreRapports} / ${score.nombrePresences} / ${score.nombreAppreciations}'),
          ],
        ),
      ),
    );
  }
}

class _LigneDetail extends StatelessWidget {
  final String label;
  final String valeur;

  const _LigneDetail(this.label, this.valeur);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Carte compacte pour un AVS consultant SON PROPRE score (pas de
/// classement) — `avsId` est de toute façon ignoré/forcé côté serveur pour
/// ce rôle, voir `iaController.js`.
class ScoreAvsPersonnelCard extends ConsumerWidget {
  final int jours;

  const ScoreAvsPersonnelCard({super.key, this.jours = 30});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(performanceAvsProvider((avsId: 'moi', jours: jours)));

    return async.when(
      loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (perf) {
        if (perf.resultats.isEmpty) return const SizedBox.shrink();
        final mon = perf.resultats.first;
        final couleur = mon.scoreGlobal >= 80
            ? AppColors.success
            : mon.scoreGlobal >= 60
                ? AppColors.warning
                : AppColors.error;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: couleur.withOpacity(0.12),
                child: Text(mon.scoreGlobal.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.w800, color: couleur)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mon score de performance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Ponctualité ${mon.tauxPonctualiteRapports.toStringAsFixed(0)}% · Présence ${mon.tauxPresenceATemps.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
