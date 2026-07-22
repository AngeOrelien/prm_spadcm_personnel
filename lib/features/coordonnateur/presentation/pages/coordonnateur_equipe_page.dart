import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Gestion de l'équipe AVS : liste des agents, leur statut (disponible / en
/// intervention / absent), et le nombre de patients qui leur sont assignés.
/// Chaque ligne ouvre désormais la fiche AVS plein écran (voir
/// `coordonnateur_avs_detail_page.dart`).
class CoordonnateurEquipePage extends ConsumerWidget {
  const CoordonnateurEquipePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avsAsync = ref.watch(avsListProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Équipe AVS',
          subtitle: avsAsync.maybeWhen(
            data: (avsListe) {
              final disponibles = avsListe.where((a) => a.statut == StatutAvs.disponible).length;
              return '${avsListe.length} agents · $disponibles disponibles';
            },
            orElse: () => null,
          ),
          leadingIcon: Icons.badge_outlined,
          actions: [
            HeaderAction(
              icon: Icons.person_add_alt_1_outlined,
              tooltip: 'Ajouter un AVS',
              onTap: () => context.push(AppRoutes.coordonnateurNouvelAvs),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: avsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(avsListProvider)),
            data: (avsListe) {
              if (avsListe.isEmpty) {
                return Center(
                  child: Text('Aucun agent AVS pour le moment', style: Theme.of(context).textTheme.bodyMedium),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                itemCount: avsListe.length,
                itemBuilder: (context, index) {
                  final avs = avsListe[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                      leading: InitialsAvatar(nomComplet: avs.nomComplet, couleur: avs.statut.couleur),
                      title: Text(avs.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${avs.telephone}\n${avs.patientsAssignes} patient(s) assigné(s)'),
                      isThreeLine: true,
                      trailing: StatusChip(label: avs.statut.libelle, couleur: avs.statut.couleur),
                      onTap: () => context.push(AppRoutes.coordonnateurAvsDetail(avs.id)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErreurChargement extends StatelessWidget {
  final VoidCallback onReessayer;

  const _ErreurChargement({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            const Text('Impossible de charger l\'équipe AVS.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
