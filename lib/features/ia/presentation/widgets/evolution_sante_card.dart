import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/ia_entities.dart';
import '../providers/ia_providers.dart';

/// Carte "Évolution de l'état de santé" : va chercher
/// `POST /api/ia/evolution-sante` (voir `evolutionSanteProvider`) et trace
/// pouls / SpO2 sur les `jours` derniers jours de rapports, avec un badge
/// de tendance (stable / amélioration / dégradation).
///
/// Utilisation typique : dossier patient (coordonnateur, médecin), ou
/// onglet "Mon patient" côté AVS.
class EvolutionSanteCard extends ConsumerWidget {
  final String patientId;
  final int jours;

  const EvolutionSanteCard({super.key, required this.patientId, this.jours = 30});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(evolutionSanteProvider((patientId: patientId, jours: jours)));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: async.when(
        loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => _ErreurCarte(
          message: e is AppException ? e.message : 'Analyse indisponible pour le moment',
          onReessayer: () => ref.invalidate(evolutionSanteProvider((patientId: patientId, jours: jours))),
        ),
        data: (evolution) => _Contenu(evolution: evolution, jours: jours),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  final EvolutionSante evolution;
  final int jours;

  const _Contenu({required this.evolution, required this.jours});

  @override
  Widget build(BuildContext context) {
    if (evolution.points.isEmpty) {
      return const _EtatVide(
        icone: Icons.show_chart,
        texte: "Pas encore assez de rapports pour tracer une évolution sur cette période.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Évolution santé · $jours derniers jours',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            _BadgeTendance(tendance: evolution.tendance),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(height: 200, child: _GraphiqueEvolution(points: evolution.points)),
        const SizedBox(height: AppSpacing.sm),
        _Legende(),
        if (evolution.analyse.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  evolution.analyse,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GraphiqueEvolution extends StatelessWidget {
  final List<PointEvolutionSante> points;

  const _GraphiqueEvolution({required this.points});

  @override
  Widget build(BuildContext context) {
    final poulsSpots = <FlSpot>[];
    final spo2Spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.poulsMoyen != null) poulsSpots.add(FlSpot(i.toDouble(), p.poulsMoyen!));
      if (p.spo2Moyen != null) spo2Spots.add(FlSpot(i.toDouble(), p.spo2Moyen!));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 20),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 4).clamp(1, points.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final d = points[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10, color: AppColors.textDisabled)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      s.y.toStringAsFixed(0),
                      const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          if (poulsSpots.isNotEmpty)
            LineChartBarData(
              spots: poulsSpots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.primarySurface.withOpacity(0.4)),
            ),
          if (spo2Spots.isNotEmpty)
            LineChartBarData(
              spots: spo2Spots,
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      children: const [
        _PuceLegende(couleur: AppColors.primary, texte: 'Pouls (bpm)'),
        _PuceLegende(couleur: AppColors.secondary, texte: 'SpO2 (%)'),
      ],
    );
  }
}

class _PuceLegende extends StatelessWidget {
  final Color couleur;
  final String texte;

  const _PuceLegende({required this.couleur, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texte, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BadgeTendance extends StatelessWidget {
  final TendanceSante tendance;

  const _BadgeTendance({required this.tendance});

  @override
  Widget build(BuildContext context) {
    final (couleur, icone, texte) = switch (tendance) {
      TendanceSante.amelioration => (AppColors.success, Icons.trending_up, 'Amélioration'),
      TendanceSante.degradation => (AppColors.error, Icons.trending_down, 'Dégradation'),
      TendanceSante.stable => (AppColors.info, Icons.trending_flat, 'Stable'),
      TendanceSante.inconnue => (AppColors.textDisabled, Icons.help_outline, 'Non déterminée'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: couleur),
          const SizedBox(width: 4),
          Text(texte, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
        ],
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _EtatVide({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(icone, size: 32, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.xs),
          Text(texte, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErreurCarte extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;

  const _ErreurCarte({required this.message, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 28, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onReessayer, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
