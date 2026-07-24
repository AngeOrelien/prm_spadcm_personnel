import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

/// Onglet "Utilisateurs" : CRUD des comptes de tous rôles, activation /
/// désactivation (README §3.4).
class AdministrateurUtilisateursPage extends ConsumerStatefulWidget {
  const AdministrateurUtilisateursPage({super.key});

  @override
  ConsumerState<AdministrateurUtilisateursPage> createState() => _AdministrateurUtilisateursPageState();
}

class _AdministrateurUtilisateursPageState extends ConsumerState<AdministrateurUtilisateursPage> {
  RoleUtilisateur? _filtreRole;

  @override
  Widget build(BuildContext context) {
    final utilisateursAsync = ref.watch(utilisateursListProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Utilisateurs',
          subtitle: 'Tous rôles confondus',
          leadingIcon: Icons.manage_accounts_outlined,
          actions: [
            HeaderAction(
              icon: Icons.person_add_alt_1_outlined,
              tooltip: 'Ajouter un utilisateur',
              onTap: () => context.push(AppRoutes.administrateurNouvelUtilisateur),
            ),
          ],
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FiltreChip(label: 'Tous', selectionne: _filtreRole == null, onTap: () => setState(() => _filtreRole = null)),
                for (final role in RoleUtilisateur.values)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: _FiltreChip(
                      label: role.libelle,
                      selectionne: _filtreRole == role,
                      onTap: () => setState(() => _filtreRole = role),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: utilisateursAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(utilisateursListProvider)),
            data: (utilisateurs) {
              final filtres = _filtreRole == null ? utilisateurs : utilisateurs.where((u) => u.role == _filtreRole).toList();
              if (filtres.isEmpty) {
                return const Center(
                  child: EmptyStateCard(
                    icon: Icons.people_outline,
                    titre: 'Aucun utilisateur',
                    message: 'Aucun compte ne correspond à ce filtre.',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(utilisateursListProvider),
                child: ListView.builder(
                  itemCount: filtres.length,
                  itemBuilder: (context, index) {
                    final u = filtres[index];
                    return ListTile(
                      leading: InitialsAvatar(nomComplet: u.nomComplet, couleur: u.role.couleur),
                      title: Text(u.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(label: u.role.libelle, couleur: u.role.couleur),
                          const SizedBox(width: AppSpacing.xs),
                          Switch(
                            value: u.actif,
                            onChanged: (v) => ref.read(administrateurActionsProvider).basculerActivation(u.id, v),
                          ),
                        ],
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

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool selectionne;
  final VoidCallback onTap;

  const _FiltreChip({required this.label, required this.selectionne, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectionne,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySurface,
      labelStyle: TextStyle(color: selectionne ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w600),
    );
  }
}
