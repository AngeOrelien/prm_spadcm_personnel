import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/administrateur_providers.dart';

/// Onglet "Statistiques" : rapports détaillés + export PDF (AVS, patients...)
/// (README §3.4).
class AdministrateurStatistiquesPage extends ConsumerStatefulWidget {
  const AdministrateurStatistiquesPage({super.key});

  @override
  ConsumerState<AdministrateurStatistiquesPage> createState() => _AdministrateurStatistiquesPageState();
}

class _AdministrateurStatistiquesPageState extends ConsumerState<AdministrateurStatistiquesPage> {
  bool _exportEnCours = false;

  Future<void> _exporterPdf() async {
    setState(() => _exportEnCours = true);
    try {
      await ref.read(administrateurActionsProvider).exporterStatistiquesPdf();
      if (mounted) context.showInfo('Export PDF généré. Tu le retrouveras dans tes téléchargements.');
    } catch (e) {
      if (mounted) context.showError('Échec de l\'export PDF. Réessaie plus tard.');
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statistiquesGlobalesProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Statistiques',
          subtitle: 'Retards, absences, activité',
          leadingIcon: Icons.bar_chart_outlined,
          actions: [
            HeaderAction(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: 'Export PDF',
              onTap: _exportEnCours ? null : _exporterPdf,
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(statistiquesGlobalesProvider)),
            data: (stats) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(statistiquesGlobalesProvider),
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
                  const SectionTitle(titre: 'Exports disponibles'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        _ExportTile(
                          icon: Icons.badge_outlined,
                          titre: 'Rapport de ponctualité AVS',
                          sousTitre: 'Retards, absences par agent',
                          enCours: _exportEnCours,
                          onTap: _exporterPdf,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ExportTile(
                          icon: Icons.people_alt_outlined,
                          titre: 'Rapport patients',
                          sousTitre: 'Suivi, souscriptions actives',
                          enCours: _exportEnCours,
                          onTap: _exporterPdf,
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
