import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Ordre de tri disponible pour l'équipe AVS.
enum _TriEquipe { aucun, disponibiliteDabord }

/// Gestion de l'équipe AVS : liste des agents, leur statut (disponible / en
/// intervention / absent), recherche par nom, tri par disponibilité, et le
/// nombre de patients qui leur sont assignés. Chaque ligne ouvre la fiche AVS
/// plein écran (voir `coordonnateur_avs_detail_page.dart`).
class CoordonnateurEquipePage extends ConsumerStatefulWidget {
  const CoordonnateurEquipePage({super.key});

  @override
  ConsumerState<CoordonnateurEquipePage> createState() => _CoordonnateurEquipePageState();
}

class _CoordonnateurEquipePageState extends ConsumerState<CoordonnateurEquipePage> {
  final _recherche = TextEditingController();
  String _requete = '';
  _TriEquipe _tri = _TriEquipe.aucun;
  bool _seulementDisponibles = false;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  List<Avs> _appliquerFiltresEtTri(List<Avs> avsListe) {
    var resultat = _requete.isEmpty
        ? List<Avs>.from(avsListe)
        : avsListe.where((a) => a.nomComplet.toLowerCase().contains(_requete.toLowerCase())).toList();

    if (_seulementDisponibles) {
      resultat = resultat.where((a) => a.statut == StatutAvs.disponible).toList();
    }

    if (_tri == _TriEquipe.disponibiliteDabord) {
      int rang(StatutAvs s) => switch (s) {
            StatutAvs.disponible => 0,
            StatutAvs.enIntervention => 1,
            StatutAvs.absent => 2,
          };
      resultat.sort((a, b) => rang(a.statut).compareTo(rang(b.statut)));
    }

    return resultat;
  }

  @override
  Widget build(BuildContext context) {
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
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _recherche,
                  onChanged: (v) => setState(() => _requete = v),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un AVS…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _BoutonTriDisponibilite(
                tri: _tri,
                seulementDisponibles: _seulementDisponibles,
                onTriChange: (t) => setState(() => _tri = t),
                onSeulementDisponiblesChange: (v) => setState(() => _seulementDisponibles = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: avsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(avsListProvider)),
            data: (avsListe) {
              final filtres = _appliquerFiltresEtTri(avsListe);

              if (filtres.isEmpty) {
                return Center(
                  child: Text(
                    avsListe.isEmpty ? 'Aucun agent AVS pour le moment' : 'Aucun AVS trouvé',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(avsListProvider),
                child: ScrollRefreshListener(
                  onAtteintLeBas: () => ref.invalidate(avsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: filtres.length,
                    itemBuilder: (context, index) {
                      final avs = filtres[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                          leading: InitialsAvatar(nomComplet: avs.nomComplet, couleur: avs.statut.couleur, photoUrl: avs.photoUrl),
                          title: Text(avs.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${avs.telephone}\n${avs.patientsAssignes} patient(s) assigné(s)'),
                          isThreeLine: true,
                          trailing: StatusChip(label: avs.statut.libelle, couleur: avs.statut.couleur),
                          onTap: () => context.push(AppRoutes.coordonnateurAvsDetail(avs.id)),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bouton "trier/filtrer par disponibilité" : un menu compact au lieu d'une
/// rangée de chips, pour ne pas surcharger l'en-tête à côté de la recherche.
class _BoutonTriDisponibilite extends StatelessWidget {
  final _TriEquipe tri;
  final bool seulementDisponibles;
  final ValueChanged<_TriEquipe> onTriChange;
  final ValueChanged<bool> onSeulementDisponiblesChange;

  const _BoutonTriDisponibilite({
    required this.tri,
    required this.seulementDisponibles,
    required this.onTriChange,
    required this.onSeulementDisponiblesChange,
  });

  bool get _actif => tri == _TriEquipe.disponibiliteDabord || seulementDisponibles;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _actif ? AppColors.primarySurface : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: PopupMenuButton<String>(
        tooltip: 'Trier par disponibilité',
        icon: Icon(Icons.tune, color: _actif ? AppColors.primary : AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        onSelected: (valeur) {
          switch (valeur) {
            case 'trier_disponibilite':
              onTriChange(tri == _TriEquipe.disponibiliteDabord ? _TriEquipe.aucun : _TriEquipe.disponibiliteDabord);
              break;
            case 'seulement_disponibles':
              onSeulementDisponiblesChange(!seulementDisponibles);
              break;
          }
        },
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            value: 'trier_disponibilite',
            checked: tri == _TriEquipe.disponibiliteDabord,
            child: const Text('Disponibles en premier'),
          ),
          CheckedPopupMenuItem(
            value: 'seulement_disponibles',
            checked: seulementDisponibles,
            child: const Text('Afficher seulement les disponibles'),
          ),
        ],
      ),
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
