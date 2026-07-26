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

extension _StatutPresenceLibelleX on StatutPresenceCoordonnateur {
  String get libelle => switch (this) {
    StatutPresenceCoordonnateur.present => 'Présent',
    StatutPresenceCoordonnateur.retard => 'En retard',
    StatutPresenceCoordonnateur.absent => 'Absent',
  };

  Color get couleur => switch (this) {
    StatutPresenceCoordonnateur.present => AppColors.success,
    StatutPresenceCoordonnateur.retard => AppColors.warning,
    StatutPresenceCoordonnateur.absent => AppColors.error,
  };
}

/// Onglet "Suivi" du coordonnateur : regroupe la validation des rapports
/// d'intervention AVS et la vue des check-in/check-out du jour, sous deux
/// sous-onglets — auparavant deux idées séparées, réunies ici pour que le
/// coordonnateur ait tout le suivi quotidien au même endroit.
class CoordonnateurRapportsPage extends StatefulWidget {
  const CoordonnateurRapportsPage({super.key});

  @override
  State<CoordonnateurRapportsPage> createState() => _CoordonnateurRapportsPageState();
}

class _CoordonnateurRapportsPageState extends State<CoordonnateurRapportsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Suivi',
          subtitle: 'Rapports d\'intervention et check-in des AVS',
          leadingIcon: Icons.fact_check_outlined,
        ),
        const Divider(height: 1),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Rapports'),
            Tab(text: 'Check-in'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _RapportsTab(),
              _CheckinsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sous-onglet Rapports
// ---------------------------------------------------------------------------

class _RapportsTab extends ConsumerStatefulWidget {
  const _RapportsTab();

  @override
  ConsumerState<_RapportsTab> createState() => _RapportsTabState();
}

class _RapportsTabState extends ConsumerState<_RapportsTab> {
  StatutRapport? _filtre; // null = tous

  @override
  Widget build(BuildContext context) {
    final rapportsAsync = ref.watch(rapportsListProvider);
    final avsAsync = ref.watch(avsListProvider);
    final patientsAsync = ref.watch(patientsListProvider);

    final avsListe = avsAsync.whenOrNull(data: (v) => v) ?? const <Avs>[];
    final patients = patientsAsync.whenOrNull(data: (v) => v) ?? const <Patient>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FiltreChip(label: 'Tous', selectionne: _filtre == null, onTap: () => setState(() => _filtre = null)),
                const SizedBox(width: 8),
                for (final statut in StatutRapport.values) ...[
                  _FiltreChip(
                    label: statut.libelle,
                    selectionne: _filtre == statut,
                    onTap: () => setState(() => _filtre = statut),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: rapportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(rapportsListProvider)),
            data: (rapports) {
              final filtres = _filtre == null ? rapports : rapports.where((r) => r.statut == _filtre).toList();
              if (filtres.isEmpty) {
                return Center(child: Text('Aucun rapport', style: Theme.of(context).textTheme.bodyMedium));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(rapportsListProvider),
                child: ScrollRefreshListener(
                  onAtteintLeBas: () => ref.invalidate(rapportsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: filtres.length,
                    itemBuilder: (context, index) {
                      final rapport = filtres[index];
                      final avs = _trouverAvs(avsListe, rapport.avsId);
                      final patient = _trouverPatient(patients, rapport.patientId);
                      return _RapportCard(rapport: rapport, avs: avs, patient: patient);
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

  Avs? _trouverAvs(List<Avs> liste, String id) {
    for (final a in liste) {
      if (a.id == id) return a;
    }
    return null;
  }

  Patient? _trouverPatient(List<Patient> liste, String id) {
    for (final p in liste) {
      if (p.id == id) return p;
    }
    return null;
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
      labelStyle: TextStyle(
        color: selectionne ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selectionne ? FontWeight.w600 : FontWeight.w400,
      ),
      backgroundColor: AppColors.surfaceMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill), side: BorderSide.none),
    );
  }
}

/// Carte résumé d'un rapport dans la liste — le tap ouvre désormais une
/// vraie page de détail plein écran (`CoordonnateurRapportDetailPage`),
/// cohérente avec les fiches patient/AVS, au lieu d'un bottom sheet.
class _RapportCard extends StatelessWidget {
  final RapportAvs rapport;
  final Avs? avs;
  final Patient? patient;

  const _RapportCard({required this.rapport, required this.avs, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(AppRoutes.coordonnateurRapportDetail(rapport.id)),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(nomComplet: avs?.nomComplet ?? '?', couleur: AppColors.roleAvs, photoUrl: avs?.photoUrl),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(avs?.nomComplet ?? 'AVS inconnu', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Patient : ${patient?.nomComplet ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(rapport.resume, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(_formaterDate(rapport.date), style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    'Voir le rapport',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formaterDate(DateTime date) {
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Sous-onglet Check-in
// ---------------------------------------------------------------------------

/// Vue d'ensemble des check-in/check-out du jour pour toute l'équipe AVS
/// (`GET /api/presences/aujourdhui/vue-ensemble`). Le tap sur un agent ouvre
/// son historique complet de présence (`CoordonnateurCheckinDetailPage`).
class _CheckinsTab extends ConsumerWidget {
  const _CheckinsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presencesAsync = ref.watch(presencesAujourdhuiProvider);

    return presencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(presencesAujourdhuiProvider)),
      data: (presences) {
        if (presences.isEmpty) {
          return Center(
            child: Text('Aucun check-in enregistré aujourd\'hui.', style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        final present = presences.where((p) => p.statut == StatutPresenceCoordonnateur.present).length;
        final retard = presences.where((p) => p.statut == StatutPresenceCoordonnateur.retard).length;
        final absent = presences.where((p) => p.statut == StatutPresenceCoordonnateur.absent).length;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(presencesAujourdhuiProvider),
          child: ScrollRefreshListener(
            onAtteintLeBas: () => ref.invalidate(presencesAujourdhuiProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
              children: [
                Row(
                  children: [
                    Expanded(child: _CompteurStatut(label: 'Présents', valeur: present, couleur: AppColors.success)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _CompteurStatut(label: 'Retards', valeur: retard, couleur: AppColors.warning)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _CompteurStatut(label: 'Absents', valeur: absent, couleur: AppColors.error)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final presence in presences) _CheckinLigne(presence: presence),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompteurStatut extends StatelessWidget {
  final String label;
  final int valeur;
  final Color couleur;

  const _CompteurStatut({required this.label, required this.valeur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text('$valeur', style: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 20)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CheckinLigne extends StatelessWidget {
  final PresenceAvs presence;

  const _CheckinLigne({required this.presence});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push(AppRoutes.coordonnateurCheckinDetail(presence.avsId)),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              InitialsAvatar(nomComplet: presence.avsNom ?? '?', couleur: presence.statut.couleur),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(presence.avsNom ?? 'AVS', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      presence.heureCheckIn != null
                          ? 'Entrée à ${_formaterHeure(presence.heureCheckIn!)}'
                          : 'Pas encore de check-in',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(label: presence.statut.libelle, couleur: presence.statut.couleur),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  String _formaterHeure(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
            const Text('Impossible de charger les données.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
