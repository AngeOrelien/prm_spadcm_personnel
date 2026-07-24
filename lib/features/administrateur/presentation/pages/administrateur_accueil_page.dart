import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

/// Onglet "Tableau de bord" : statistiques clés (retards, absences,
/// paiements du jour) — README §7.2 (Administrateur).
class AdministrateurAccueilPage extends ConsumerWidget {
  const AdministrateurAccueilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;
    final statsAsync = ref.watch(statistiquesGlobalesProvider);
    final paiementsAsync = ref.watch(paiementsListProvider);

    return Column(
      children: [
        AppDashboardHeader.greeting(
          nomComplet: personnel?.nomComplet ?? '',
          libelleRole: 'Administrateur',
          actions: [
            HeaderAction(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: 'Export PDF',
              onTap: () => context.go(AppRoutes.administrateurStatistiques),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(statistiquesGlobalesProvider);
              ref.invalidate(paiementsListProvider);
            },
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(statistiquesGlobalesProvider)),
              data: (stats) => ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  Padding(
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
                          valeur: '${stats.totalPatients}',
                          libelle: 'Patients suivis',
                          icon: Icons.people_alt_outlined,
                          couleur: AppColors.primary,
                        ),
                        StatCard(
                          valeur: '${stats.totalAvs}',
                          libelle: 'AVS actifs',
                          icon: Icons.badge_outlined,
                          couleur: AppColors.roleAvs,
                          onTap: () => context.go(AppRoutes.administrateurUtilisateurs),
                        ),
                        StatCard(
                          valeur: '${stats.rapportsEnRetard}',
                          libelle: 'Rapports en retard',
                          icon: Icons.schedule_outlined,
                          couleur: AppColors.warning,
                          onTap: () => context.go(AppRoutes.administrateurStatistiques),
                        ),
                        StatCard(
                          valeur: '${stats.avsAbsentsAujourdhui}',
                          libelle: 'Absences AVS (jour)',
                          icon: Icons.event_busy_outlined,
                          couleur: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: AppColors.secondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${stats.montantPaiementsDuJour.toStringAsFixed(0)} FCFA aujourd\'hui',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text('${stats.paiementsDuJour} paiement(s) confirmé(s)', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.administrateurPaiements),
                            child: const Text('Voir'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SectionTitle(
                    titre: 'Derniers paiements',
                    trailing: TextButton(
                      onPressed: () => context.go(AppRoutes.administrateurPaiements),
                      child: const Text('Tout voir'),
                    ),
                  ),
                  paiementsAsync.when(
                    loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator()),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text('Impossible de charger les paiements.', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    data: (paiements) {
                      if (paiements.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text('Aucun paiement récent.', style: Theme.of(context).textTheme.bodySmall),
                        );
                      }
                      return Column(
                        children: [
                          for (final p in paiements.take(3))
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: p.statut.couleur.withOpacity(0.12),
                                child: Icon(Icons.receipt_long_outlined, color: p.statut.couleur, size: 18),
                              ),
                              title: Text(p.patientNom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(p.soinLibelle),
                              trailing: Text('${p.montant.toStringAsFixed(0)} FCFA'),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
