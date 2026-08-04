import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../ia/presentation/widgets/performance_avs_widgets.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

/// Onglet "Statistiques" : rapports détaillés + export PDF (AVS, patients...)
/// (README §3.4).
String _fmtDatePeriode(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class AdministrateurStatistiquesPage extends ConsumerStatefulWidget {
  const AdministrateurStatistiquesPage({super.key});

  @override
  ConsumerState<AdministrateurStatistiquesPage> createState() => _AdministrateurStatistiquesPageState();
}

class _AdministrateurStatistiquesPageState extends ConsumerState<AdministrateurStatistiquesPage> {
  bool _exportAvsEnCours = false;
  bool _exportPatientsEnCours = false;

  Future<void> _ouvrirExport(Future<String> Function() genererPdf, {required bool avs}) async {
    setState(() => avs ? _exportAvsEnCours = true : _exportPatientsEnCours = true);
    try {
      final chemin = await genererPdf();
      if (mounted) {
        context.showInfo('Export PDF généré avec succès');
        final resultat = await OpenFile.open(chemin);
        if (resultat.type != ResultType.done) {
          context.showError('Impossible d\'ouvrir le fichier : ${resultat.message}');
        }
      }
    } catch (e) {
      if (mounted) context.showError('Échec de l\'export PDF. Réessaie plus tard.');
    } finally {
      if (mounted) setState(() => avs ? _exportAvsEnCours = false : _exportPatientsEnCours = false);
    }
  }

  Future<void> _exporterPdf() => _ouvrirExport(
        () => ref.read(administrateurActionsProvider).exporterStatistiquesPdf(),
        avs: true,
      );

  /// Export "Rapport patients" — pointait par erreur vers le même export
  /// AVS avant correction (`exporterRapportPatientsPdf`, nouvelle route
  /// backend dédiée : `GET /stats/export/patients/pdf`).
  Future<void> _exporterRapportPatients() => _ouvrirExport(
        () => ref.read(administrateurActionsProvider).exporterRapportPatientsPdf(),
        avs: false,
      );

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statistiquesGlobalesProvider);
    final paiementsAsync = ref.watch(paiementsListProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Statistiques',
          subtitle: 'Retards, absences, activité',
          leadingIcon: Icons.bar_chart_outlined,
          actions: [
            HeaderAction(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: 'Export PDF (ponctualité AVS)',
              onTap: _exportAvsEnCours ? null : _exporterPdf,
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(statistiquesGlobalesProvider)),
            data: (stats) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(statistiquesGlobalesProvider);
                ref.invalidate(paiementsListProvider);
              },
              child: ListView(
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
                        StatCard(valeur: '${stats.totalPatients}', libelle: 'Patients suivis', icon: Icons.people_alt_outlined, couleur: AppColors.primary),
                        StatCard(valeur: '${stats.totalAvs}', libelle: 'AVS actifs', icon: Icons.badge_outlined, couleur: AppColors.roleAvs),
                        StatCard(valeur: '${stats.rapportsEnRetard}', libelle: 'Rapports en retard', icon: Icons.schedule_outlined, couleur: AppColors.warning),
                        StatCard(valeur: '${stats.avsAbsentsAujourdhui}', libelle: 'Absences (jour)', icon: Icons.event_busy_outlined, couleur: AppColors.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: PerformanceAvsLeaderboard(jours: 30),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SectionTitle(
                    titre: 'Paiements',
                    trailing: TextButton(
                      onPressed: () => context.go(AppRoutes.administrateurUtilisateurs),
                      child: const Text('Voir tout'),
                    ),
                  ),
                  paiementsAsync.when(
                    loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator()),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text('Impossible de charger les paiements.', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    data: (paiements) {
                      final total = paiements.fold<double>(0, (s, p) => s + p.montant);
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: AppSpacing.sm,
                              crossAxisSpacing: AppSpacing.sm,
                              childAspectRatio: 1.3,
                              children: [
                                StatCard(
                                  valeur: '${paiements.length}',
                                  libelle: 'Souscriptions/transactions',
                                  icon: Icons.receipt_long_outlined,
                                  couleur: AppColors.secondary,
                                ),
                                StatCard(
                                  valeur: '${total.toStringAsFixed(0)} FCFA',
                                  libelle: 'Total encaissé',
                                  icon: Icons.payments_outlined,
                                  couleur: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                          if (paiements.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Text('Aucun paiement pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                            )
                          else
                            for (final p in paiements.take(3))
                              ListTile(
                                leading: Icon(Icons.receipt_long_outlined, color: p.statut.couleur),
                                title: Text(p.patientNom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(p.soinLibelle),
                                trailing: Text('${p.montant.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SectionTitle(titre: 'Souscriptions & paiements'),
                  Consumer(
                    builder: (context, ref, _) {
                      final detailAsync = ref.watch(statistiquesPaiementsDetailProvider);
                      return detailAsync.when(
                        loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator()),
                        error: (e, st) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text('Impossible de charger le rapport souscriptions/paiements.', style: Theme.of(context).textTheme.bodySmall),
                        ),
                        data: (detail) {
                          final totalSouscriptions = detail.souscriptionsParStatut.fold<int>(0, (s, r) => s + r.total);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_fmtDatePeriode(detail.periodeDebut)} — ${_fmtDatePeriode(detail.periodeFin)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: AppSpacing.sm,
                                  crossAxisSpacing: AppSpacing.sm,
                                  childAspectRatio: 1.3,
                                  children: [
                                    StatCard(
                                      valeur: '${detail.totalEncaisse.toStringAsFixed(0)} FCFA',
                                      libelle: 'Total encaissé (période)',
                                      icon: Icons.payments_outlined,
                                      couleur: AppColors.success,
                                    ),
                                    StatCard(
                                      valeur: '$totalSouscriptions',
                                      libelle: 'Souscriptions (période)',
                                      icon: Icons.assignment_outlined,
                                      couleur: AppColors.secondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (detail.souscriptionsParStatut.isNotEmpty) ...[
                                  Text('Souscriptions par statut', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      for (final r in detail.souscriptionsParStatut)
                                        StatusChip(
                                          label: '${statutSouscriptionFromString(r.statut).libelle} · ${r.total}',
                                          couleur: statutSouscriptionFromString(r.statut).couleur,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                                if (detail.paiementsParStatut.isNotEmpty) ...[
                                  Text('Paiements par statut', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      for (final r in detail.paiementsParStatut)
                                        StatusChip(
                                          label: '${statutPaiementFromString(r.statut).libelle} · ${r.total}',
                                          couleur: statutPaiementFromString(r.statut).couleur,
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SectionTitle(titre: 'Exports disponibles'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        _ExportTile(
                          icon: Icons.badge_outlined,
                          titre: 'Rapport de ponctualité AVS',
                          sousTitre: 'Détail jour par jour par agent + synthèse générale',
                          enCours: _exportAvsEnCours,
                          onTap: _exporterPdf,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ExportTile(
                          icon: Icons.people_alt_outlined,
                          titre: 'Rapport patients',
                          sousTitre: 'Horaires, retards par patient + synthèse générale',
                          enCours: _exportPatientsEnCours,
                          onTap: _exporterRapportPatients,
                        ),
                      ],
                    ),
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

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String sousTitre;
  final bool enCours;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.titre,
    required this.sousTitre,
    required this.enCours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enCours ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(sousTitre, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.file_download_outlined, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
