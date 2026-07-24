import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../domain/entities/avs_entities.dart';
import '../providers/avs_providers.dart';
import '../widgets/avs_widgets.dart';

/// Onglet "Planning" — sert aussi de page d'accueil pour l'AVS : visites du
/// jour, statut de présence, statistiques de ponctualité personnelles.
class AvsPlanningPage extends ConsumerWidget {
  const AvsPlanningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;
    final planningAsync = ref.watch(monPlanningProvider);
    final presenceAsync = ref.watch(presenceDuJourProvider);
    final statsAsync = ref.watch(mesStatistiquesProvider);

    final chargementInitial = planningAsync.isLoading && !planningAsync.hasValue;

    return Column(
      children: [
        AppDashboardHeader.greeting(
          nomComplet: personnel?.nomComplet ?? '',
          libelleRole: 'Agent AVS',
          actions: [
            HeaderAction(
              icon: Icons.badge_outlined,
              tooltip: 'Check-in',
              onTap: () {},
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: chargementInitial
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(monPlanningProvider);
                    ref.invalidate(presenceDuJourProvider);
                    ref.invalidate(mesStatistiquesProvider);
                  },
                  child: planningAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => ErreurChargement(onReessayer: () => ref.invalidate(monPlanningProvider)),
                    data: (visites) {
                      final aujourdhui = DateTime.now();
                      final visitesDuJour = visites
                          .where((v) => v.date.year == aujourdhui.year && v.date.month == aujourdhui.month && v.date.day == aujourdhui.day)
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                        children: [
                          presenceAsync.maybeWhen(
                            data: (presence) => _CarteStatutPresence(presence: presence),
                            orElse: () => const SizedBox.shrink(),
                          ),
                          statsAsync.maybeWhen(
                            data: (stats) => Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: AppSpacing.sm,
                                crossAxisSpacing: AppSpacing.sm,
                                childAspectRatio: 1.3,
                                children: [
                                  StatCard(
                                    valeur: '${visitesDuJour.length}',
                                    libelle: 'Visites aujourd\'hui',
                                    icon: Icons.calendar_today_outlined,
                                    couleur: AppColors.primary,
                                  ),
                                  StatCard(
                                    valeur: '${(stats.tauxPonctualite * 100).round()}%',
                                    libelle: 'Ponctualité rapports',
                                    icon: Icons.timer_outlined,
                                    couleur: stats.tauxPonctualite >= 0.8 ? AppColors.success : AppColors.warning,
                                  ),
                                  StatCard(
                                    valeur: '${stats.rapportsEnRetard}',
                                    libelle: 'Rapports en retard',
                                    icon: Icons.report_gmailerrorred_outlined,
                                    couleur: AppColors.secondary,
                                    onTap: () => context.go(AppRoutes.avsRapports),
                                  ),
                                  StatCard(
                                    valeur: '${stats.absences}',
                                    libelle: 'Absences enregistrées',
                                    icon: Icons.event_busy_outlined,
                                    couleur: AppColors.info,
                                  ),
                                ],
                              ),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                          SectionTitle(titre: 'Visites du jour (${visitesDuJour.length})'),
                          if (visitesDuJour.isEmpty)
                            const EmptyStateCard(
                              icon: Icons.event_available_outlined,
                              titre: 'Aucune visite aujourd\'hui',
                              message: 'Ton planning du jour est vide pour le moment.',
                            )
                          else
                            for (final visite in visitesDuJour) VisiteTile(visite: visite),
                          const SizedBox(height: AppSpacing.md),
                          SectionTitle(titre: 'Prochainement'),
                          if (visites.where((v) => v.date.isAfter(aujourdhui)).isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Text('Rien de planifié pour l\'instant.', style: Theme.of(context).textTheme.bodySmall),
                            )
                          else
                            for (final visite in visites.where((v) => v.date.isAfter(aujourdhui)).take(5)) VisiteTile(visite: visite),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CarteStatutPresence extends StatelessWidget {
  final Presence? presence;

  const _CarteStatutPresence({required this.presence});

  @override
  Widget build(BuildContext context) {
    final faitCheckIn = presence?.aFaitCheckIn == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: faitCheckIn ? AppColors.primarySurface : AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              faitCheckIn ? Icons.check_circle_outline : Icons.warning_amber_outlined,
              color: faitCheckIn ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                faitCheckIn
                    ? 'Présence confirmée pour aujourd\'hui.'
                    : 'Tu n\'as pas encore fait ton check-in du matin.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
