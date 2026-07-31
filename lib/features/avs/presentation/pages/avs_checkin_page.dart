import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../domain/entities/avs_entities.dart';
import '../providers/avs_providers.dart';
import '../widgets/avs_widgets.dart';

/// Onglet "Check-in" : présence présentielle géolocalisée, condition
/// préalable à la validation des rapports de la journée (README §3.2).
///
/// Le check-in ne peut être fait qu'une fois par jour : le backend le
/// refuse déjà (`presenceController.checkIn`, 400 si déjà fait), et le
/// bouton se désactive dès que `presenceDuJourProvider` renvoie une
/// présence avec `heureCheckIn` renseigné. Un récapitulatif (heures du
/// jour + historique récent) est affiché sous les boutons.
class AvsCheckinPage extends ConsumerStatefulWidget {
  const AvsCheckinPage({super.key});

  @override
  ConsumerState<AvsCheckinPage> createState() => _AvsCheckinPageState();
}

class _AvsCheckinPageState extends ConsumerState<AvsCheckinPage> {
  bool _enCours = false;

  void _rafraichir() {
    ref.invalidate(presenceDuJourProvider);
    ref.invalidate(mesPresencesProvider);
  }

  Future<bool> _confirmer({
    required String titre,
    required String message,
    required String libelleAction,
    required IconData icon,
  }) async {
    final resultat = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(icon, color: AppColors.primary, size: 32),
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(libelleAction)),
        ],
      ),
    );
    return resultat ?? false;
  }

  Future<void> _checkIn() async {
    final confirme = await _confirmer(
      titre: 'Confirmer le check-in ?',
      message: 'Ton arrivée sera enregistrée avec l\'heure actuelle et ta position. '
          'Un seul check-in est possible par jour, et il doit être fait avant que tes rapports du jour ne puissent être validés.',
      libelleAction: 'Confirmer le check-in',
      icon: Icons.login,
    );
    if (!confirme || !mounted) return;

    setState(() => _enCours = true);
    try {
      // Géolocalisation réelle branchée plus tard (package `geolocator`) ;
      // valeurs de test en attendant l'intégration native.
      await ref.read(avsActionsProvider).checkIn(latitude: 3.8480, longitude: 11.5021);
      if (mounted) context.showInfo('Check-in enregistré. Bonne journée !');
    } catch (e) {
      if (mounted) context.showError('Échec du check-in. Réessaie.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _checkOut() async {
    final confirme = await _confirmer(
      titre: 'Confirmer le check-out ?',
      message: 'Ton départ sera enregistré avec l\'heure actuelle. Fais-le une fois ta visite terminée : '
          'tu ne pourras plus faire de check-out supplémentaire aujourd\'hui après confirmation.',
      libelleAction: 'Confirmer le check-out',
      icon: Icons.logout,
    );
    if (!confirme || !mounted) return;

    setState(() => _enCours = true);
    try {
      await ref.read(avsActionsProvider).checkOut();
      if (mounted) context.showInfo('Check-out enregistré. À demain !');
    } catch (e) {
      if (mounted) context.showError('Échec du check-out. Réessaie.');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  String _heure(DateTime? d) {
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final presenceAsync = ref.watch(presenceDuJourProvider);
    final historiqueAsync = ref.watch(mesPresencesProvider);

    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Présence',
          subtitle: 'Check-in / check-out géolocalisé',
          leadingIcon: Icons.location_on_outlined,
        ),
        const Divider(height: 1),
        Expanded(
          child: presenceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => ErreurChargement(onReessayer: _rafraichir),
            data: (presence) {
              final faitCheckIn = presence?.aFaitCheckIn == true;
              final faitCheckOut = presence?.aFaitCheckOut == true;

              return RefreshIndicator(
                onRefresh: () async => _rafraichir(),
                child: ScrollRefreshListener(
                  onAtteintLeBas: _rafraichir,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              faitCheckIn ? Icons.verified_user_outlined : Icons.pin_drop_outlined,
                              size: 48,
                              color: faitCheckIn ? AppColors.success : AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              faitCheckIn ? 'Tu es présent(e) aujourd\'hui' : 'Confirme ta présence au travail',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            if (presence?.statut != null)
                              StatusChip(label: presence!.statut.libelle, couleur: presence.statut.couleur),
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: (_enCours || faitCheckIn) ? null : _checkIn,
                                icon: const Icon(Icons.login),
                                label: Text(faitCheckIn ? 'Check-in effectué' : 'Faire le check-in'),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: (_enCours || !faitCheckIn || faitCheckOut) ? null : _checkOut,
                                icon: const Icon(Icons.logout),
                                label: Text(faitCheckOut ? 'Check-out effectué' : 'Faire le check-out'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (faitCheckIn) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _RecapHeure(label: 'Arrivée', heure: _heure(presence?.heureCheckIn)),
                              Container(width: 1, height: 32, color: AppColors.border),
                              _RecapHeure(label: 'Départ', heure: _heure(presence?.heureCheckOut)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text(
                          'Le check-in matinal prouve ta présence au travail avant que tes rapports du jour ne puissent être validés. '
                          'Une marge de temps est définie : au-delà, il est marqué en retard. Un seul check-in par jour est possible.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const SectionTitle(titre: 'Récapitulatif récent'),
                      historiqueAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: LinearProgressIndicator(),
                        ),
                        error: (e, st) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text('Impossible de charger l\'historique.', style: Theme.of(context).textTheme.bodySmall),
                        ),
                        data: (historique) {
                          final recentes = List<Presence>.from(historique)..sort((a, b) => b.date.compareTo(a.date));
                          if (recentes.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              child: Text('Aucun historique pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                            );
                          }
                          return Column(
                            children: [
                              for (final p in recentes.take(7))
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 44, child: Text(_date(p.date), style: Theme.of(context).textTheme.bodySmall)),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          '${_heure(p.heureCheckIn)} → ${_heure(p.heureCheckOut)}',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                      StatusChip(label: p.statut.libelle, couleur: p.statut.couleur),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
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

class _RecapHeure extends StatelessWidget {
  final String label;
  final String heure;

  const _RecapHeure({required this.label, required this.heure});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(heure, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
