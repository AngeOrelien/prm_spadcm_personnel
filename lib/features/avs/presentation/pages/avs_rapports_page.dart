import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/avs_providers.dart';

/// Onglet "Rapports" : historique des rapports journaliers de l'AVS, avec
/// statut de remise (à temps / en retard), et accès au formulaire de saisie.
class AvsRapportsPage extends ConsumerWidget {
  const AvsRapportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rapportsAsync = ref.watch(mesRapportsProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Mes rapports',
          subtitle: 'Historique et statut de remise',
          leadingIcon: Icons.fact_check_outlined,
          actions: [
            HeaderAction(
              icon: Icons.add,
              tooltip: 'Nouveau rapport',
              onTap: () => context.push(AppRoutes.avsNouveauRapport),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: rapportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => ErreurChargement(onReessayer: () => ref.invalidate(mesRapportsProvider)),
            data: (rapports) {
              if (rapports.isEmpty) {
                return Center(
                  child: EmptyStateCard(
                    icon: Icons.fact_check_outlined,
                    titre: 'Aucun rapport pour le moment',
                    message: 'Rédige ton premier rapport journalier depuis le bouton "+".',
                    action: FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.avsNouveauRapport),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau rapport'),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(mesRapportsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: rapports.length,
                  itemBuilder: (context, index) {
                    final rapport = rapports[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${rapport.date.day.toString().padLeft(2, '0')}/${rapport.date.month.toString().padLeft(2, '0')}/${rapport.date.year}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rapport.resume,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
