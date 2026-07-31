import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/avs_entities.dart';
import '../providers/avs_providers.dart';

/// Historique complet des rapports journaliers de l'AVS (tous patients
/// confondus), avec statut de validation ET ponctualité de remise.
///
/// Affiche aussi, tout en haut, les rapports créés hors-ligne ou dont
/// l'envoi a échoué faute de connexion (`rapportsNonSynchronisesProvider`) :
/// l'AVS ne perd jamais sa saisie, et peut réessayer l'envoi d'un tap sur
/// "Réessayer" — voir `AvsActions.reessayerEnvoiRapport` /
/// `RapportsLocauxService`. L'heure de création d'origine (pas celle du
/// retry) reste affichée.
///
/// N'est plus un onglet de la bottom nav (remplacé par l'onglet "Mon
/// patient", qui montre l'historique propre au patient assigné) — reste
/// accessible en page poussée depuis l'accueil et depuis "Mon patient" ("Voir
/// tout"). D'où le [Scaffold] explicite : ce widget est désormais toujours
/// utilisé hors du shell de dashboard.
class AvsRapportsPage extends ConsumerStatefulWidget {
  const AvsRapportsPage({super.key});

  @override
  ConsumerState<AvsRapportsPage> createState() => _AvsRapportsPageState();
}

class _AvsRapportsPageState extends ConsumerState<AvsRapportsPage> {
  String? _idLocalEnCoursDeRetry;

  Future<void> _reessayer(RapportLocal rapportLocal) async {
    setState(() => _idLocalEnCoursDeRetry = rapportLocal.idLocal);
    try {
      await ref.read(avsActionsProvider).reessayerEnvoiRapport(rapportLocal);
      if (mounted) context.showInfo('Rapport envoyé avec succès.');
    } catch (e) {
      if (mounted) context.showError('Toujours pas de connexion au serveur. Nouvelle tentative plus tard.');
    } finally {
      if (mounted) setState(() => _idLocalEnCoursDeRetry = null);
    }
  }

  void _rafraichirTout() {
    ref.invalidate(mesRapportsProvider);
    ref.invalidate(rapportsNonSynchronisesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final rapportsAsync = ref.watch(mesRapportsProvider);
    final nonSyncAsync = ref.watch(rapportsNonSynchronisesProvider);
    final nonSync = nonSyncAsync.whenOrNull(data: (v) => v) ?? const <RapportLocal>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: [
            AppDashboardHeader.page(
              title: 'Mes rapports',
              subtitle: 'Historique et statut de remise',
              leadingIcon: Icons.fact_check_outlined,
              showBackButton: true,
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
                error: (err, st) => ErreurChargement(onReessayer: _rafraichirTout),
                data: (rapports) {
                  if (rapports.isEmpty && nonSync.isEmpty) {
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
                    onRefresh: () async => _rafraichirTout(),
                    child: ScrollRefreshListener(
                      onAtteintLeBas: _rafraichirTout,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        children: [
                          for (final rapportLocal in nonSync)
                            _RapportNonSyncTile(
                              rapportLocal: rapportLocal,
                              enCours: _idLocalEnCoursDeRetry == rapportLocal.idLocal,
                              onReessayer: () => _reessayer(rapportLocal),
                            ),
                          if (nonSync.isNotEmpty && rapports.isNotEmpty) const Divider(height: AppSpacing.lg),
                          for (final rapport in rapports) _RapportTile(rapport: rapport),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile d'un rapport en attente de synchronisation (créé hors-ligne, ou
/// dont l'envoi a échoué). Toujours affichée tout en haut de la liste, avec
/// un visuel distinct (bordure orange) et un bouton "Réessayer".
class _RapportNonSyncTile extends StatelessWidget {
  final RapportLocal rapportLocal;
  final bool enCours;
  final VoidCallback onReessayer;

  const _RapportNonSyncTile({required this.rapportLocal, required this.enCours, required this.onReessayer});

  String _heure(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.warning, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rapportLocal.patientNom.isEmpty ? 'Rapport en attente' : 'Rapport pour ${rapportLocal.patientNom}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Créé le ${_date(rapportLocal.creeLe)} à ${_heure(rapportLocal.creeLe)} · pas encore envoyé',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                  if (rapportLocal.derniereErreur != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      rapportLocal.derniereErreur!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            enCours
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : OutlinedButton.icon(
                    onPressed: onReessayer,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Réessayer'),
                  ),
          ],
        ),
      ),
    );
  }
}

class _RapportTile extends StatelessWidget {
  final RapportAvs rapport;

  const _RapportTile({required this.rapport});

  @override
  Widget build(BuildContext context) {
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
                  if (rapport.statutRemise != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      rapport.statutRemise == StatutRemiseRapport.aTemps ? 'Remis à temps' : 'Remis en retard',
                      style: TextStyle(
                        fontSize: 11,
                        color: rapport.statutRemise == StatutRemiseRapport.aTemps ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
          ],
        ),
      ),
    );
  }
}
