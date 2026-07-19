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
class CoordonnateurEquipePage extends ConsumerWidget {
  const CoordonnateurEquipePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avsListe = ref.watch(avsListProvider);
    final disponibles = avsListe.where((a) => a.statut == StatutAvs.disponible).length;

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Équipe AVS',
          subtitle: '${avsListe.length} agents · $disponibles disponibles',
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
          child: ListView.builder(
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
                  onTap: () => _ouvrirDetailAvs(context, avs),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _ouvrirDetailAvs(BuildContext context, Avs avs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(nomComplet: avs.nomComplet, couleur: avs.statut.couleur),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(avs.nomComplet, style: Theme.of(sheetContext).textTheme.titleLarge),
                          Text(avs.telephone),
                        ],
                      ),
                    ),
                    StatusChip(label: avs.statut.libelle, couleur: avs.statut.couleur),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('${avs.patientsAssignes} patient(s) actuellement assigné(s) à cet agent.'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.coordonnateurAffectations);
                    },
                    icon: const Icon(Icons.assignment_ind_outlined),
                    label: const Text('Gérer ses affectations'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
