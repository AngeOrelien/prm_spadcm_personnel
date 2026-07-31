import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../../shared/widgets/misc/confirm_action_dialog.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

String _fmtDate(DateTime? d) => d == null ? '—' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Onglet "Ressources" : CRUD complet des trois ressources gérées par
/// l'administrateur — comptes personnel, souscriptions et catalogue de
/// soins SPAD (`soins_catalogue`) — réunis dans un même onglet de bottom
/// navigation avec trois sous-onglets. Anciennement "Utilisateurs &
/// Souscriptions" (voir historique) ; le sous-onglet "Souscriptions"
/// affiche désormais les vraies souscriptions (pas seulement les paiements),
/// et un nouveau sous-onglet "Soins" gère le catalogue affiché aux patients.
class AdministrateurUtilisateursPage extends ConsumerStatefulWidget {
  const AdministrateurUtilisateursPage({super.key});

  @override
  ConsumerState<AdministrateurUtilisateursPage> createState() => _AdministrateurUtilisateursPageState();
}

class _AdministrateurUtilisateursPageState extends ConsumerState<AdministrateurUtilisateursPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this)
    ..addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  RoleUtilisateur? _filtreRole;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Bascule l'activation d'un compte, après confirmation — action
  /// sensible (un compte désactivé ne peut plus se connecter).
  Future<void> _confirmerBasculement(Utilisateur u, bool nouveauStatut) async {
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: nouveauStatut ? 'Réactiver ce compte ?' : 'Désactiver ce compte ?',
      message: nouveauStatut
          ? '${u.nomComplet} pourra de nouveau se connecter à l\'application.'
          : '${u.nomComplet} ne pourra plus se connecter à l\'application tant que le compte n\'est pas réactivé.',
      libelleConfirmer: nouveauStatut ? 'Réactiver' : 'Désactiver',
      destructif: !nouveauStatut,
    );
    if (confirme != true) return;
    await ref.read(administrateurActionsProvider).basculerActivation(u.id, nouveauStatut);
  }

  HeaderAction? get _actionAjout {
    switch (_tabController.index) {
      case 0:
        return HeaderAction(
          icon: Icons.person_add_alt_1_outlined,
          tooltip: 'Ajouter un utilisateur',
          onTap: () => context.push(AppRoutes.administrateurNouvelUtilisateur),
        );
      case 2:
        return HeaderAction(
          icon: Icons.add_circle_outline,
          tooltip: 'Ajouter un soin au catalogue',
          onTap: () => context.push(AppRoutes.administrateurNouveauSoin),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionAjout = _actionAjout;
    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Ressources',
          subtitle: 'Utilisateurs, souscriptions et catalogue de soins',
          leadingIcon: Icons.inventory_2_outlined,
          actions: [if (actionAjout != null) actionAjout],
        ),
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Utilisateurs'), Tab(text: 'Souscriptions'), Tab(text: 'Soins')],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OngletUtilisateurs(
                filtreRole: _filtreRole,
                onFiltreChange: (r) => setState(() => _filtreRole = r),
                onBasculerActivation: _confirmerBasculement,
              ),
              const _OngletSouscriptions(),
              const _OngletSoins(),
            ],
          ),
        ),
      ],
    );
  }
}

class _OngletUtilisateurs extends ConsumerWidget {
  final RoleUtilisateur? filtreRole;
  final void Function(RoleUtilisateur?) onFiltreChange;
  final Future<void> Function(Utilisateur, bool) onBasculerActivation;

  const _OngletUtilisateurs({
    required this.filtreRole,
    required this.onFiltreChange,
    required this.onBasculerActivation,
  });

  Future<void> _supprimer(BuildContext context, WidgetRef ref, Utilisateur u) async {
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: 'Supprimer ce compte ?',
      message: '${u.nomComplet} sera définitivement supprimé(e) et ne pourra plus se connecter. Cette action est irréversible.',
      libelleConfirmer: 'Supprimer',
      destructif: true,
      icone: Icons.delete_outline,
    );
    if (confirme != true) return;
    try {
      await ref.read(administrateurActionsProvider).supprimerUtilisateur(u.id);
      if (context.mounted) context.showInfo('Compte supprimé.');
    } catch (e) {
      if (context.mounted) context.showError('Échec de la suppression.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilisateursAsync = ref.watch(utilisateursListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FiltreChip(label: 'Tous', selectionne: filtreRole == null, onTap: () => onFiltreChange(null)),
                for (final role in RoleUtilisateur.values)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: _FiltreChip(
                      label: role.libelle,
                      selectionne: filtreRole == role,
                      onTap: () => onFiltreChange(role),
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
              final filtres = filtreRole == null ? utilisateurs : utilisateurs.where((u) => u.role == filtreRole).toList();
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
                      onTap: () => context.push(AppRoutes.administrateurUtilisateurModifier(u.id), extra: u),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(label: u.role.libelle, couleur: u.role.couleur),
                          const SizedBox(width: AppSpacing.xs),
                          Switch(
                            value: u.actif,
                            onChanged: (v) => onBasculerActivation(u, v),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'modifier') {
                                context.push(AppRoutes.administrateurUtilisateurModifier(u.id), extra: u);
                              } else if (v == 'supprimer') {
                                _supprimer(context, ref, u);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                              PopupMenuItem(value: 'supprimer', child: Text('Supprimer', style: TextStyle(color: AppColors.error))),
                            ],
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

/// Sous-onglet "Souscriptions" : vraies souscriptions (`souscriptions` côté
/// backend), avec CRUD complet (voir `AdministrateurSouscriptionDetailPage`
/// pour l'édition/suppression/annulation/résiliation).
class _OngletSouscriptions extends ConsumerWidget {
  const _OngletSouscriptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final souscriptionsAsync = ref.watch(souscriptionsListProvider);

    return souscriptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(souscriptionsListProvider)),
      data: (souscriptions) {
        if (souscriptions.isEmpty) {
          return const Center(
            child: EmptyStateCard(
              icon: Icons.assignment_outlined,
              titre: 'Aucune souscription',
              message: 'Les souscriptions des patients aux soins du catalogue apparaîtront ici.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(souscriptionsListProvider),
          child: ListView.builder(
            itemCount: souscriptions.length,
            itemBuilder: (context, index) {
              final s = souscriptions[index];
              return ListTile(
                leading: Icon(Icons.assignment_outlined, color: s.statut.couleur),
                title: Text(s.patientNom, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.soinNom} · ${_fmtDate(s.dateDebut)} → ${_fmtDate(s.dateFin)}'),
                onTap: () => context.push(AppRoutes.administrateurSouscriptionDetail(s.id), extra: s),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (s.montant != null) Text('${s.montant!.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    StatusChip(label: s.statut.libelle, couleur: s.statut.couleur),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Sous-onglet "Soins" : catalogue de soins SPAD (`soins_catalogue`) — CRUD
/// complet avec images/vidéos, voir `AdministrateurSoinFormPage`.
class _OngletSoins extends ConsumerWidget {
  const _OngletSoins();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soinsAsync = ref.watch(soinsListProvider);

    return soinsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(soinsListProvider)),
      data: (soins) {
        if (soins.isEmpty) {
          return const Center(
            child: EmptyStateCard(
              icon: Icons.medical_services_outlined,
              titre: 'Catalogue vide',
              message: 'Ajoute une première offre de soins pour qu\'elle apparaisse dans l\'application.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(soinsListProvider),
          child: ListView.builder(
            itemCount: soins.length,
            itemBuilder: (context, index) {
              final s = soins[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: s.imageCouverture != null ? NetworkImage(s.imageCouverture!) : null,
                  child: s.imageCouverture == null ? const Icon(Icons.medical_services_outlined, color: AppColors.primary) : null,
                ),
                title: Text(s.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.prix.toStringAsFixed(0)} ${s.devise}${s.frequenceVisites != null ? " · ${s.frequenceVisites}" : ""}'),
                onTap: () => context.push(AppRoutes.administrateurSoinModifier(s.id), extra: s),
                trailing: StatusChip(
                  label: s.actif ? 'En vitrine' : 'Retiré',
                  couleur: s.actif ? AppColors.success : AppColors.textDisabled,
                ),
              );
            },
          ),
        );
      },
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
