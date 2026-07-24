import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../providers/avs_providers.dart';
import '../widgets/avs_widgets.dart';

/// Onglet "Check-in" : présence présentielle géolocalisée, condition
/// préalable à la validation des rapports de la journée (README §3.2).
class AvsCheckinPage extends ConsumerStatefulWidget {
  const AvsCheckinPage({super.key});

  @override
  ConsumerState<AvsCheckinPage> createState() => _AvsCheckinPageState();
}

class _AvsCheckinPageState extends ConsumerState<AvsCheckinPage> {
  bool _enCours = false;

  Future<void> _checkIn() async {
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

  @override
  Widget build(BuildContext context) {
    final presenceAsync = ref.watch(presenceDuJourProvider);

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
            error: (err, st) => ErreurChargement(onReessayer: () => ref.invalidate(presenceDuJourProvider)),
            data: (presence) {
              final faitCheckIn = presence?.aFaitCheckIn == true;
              final faitCheckOut = presence?.aFaitCheckOut == true;

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(presenceDuJourProvider),
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
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        'Le check-in matinal prouve ta présence au travail avant que tes rapports du jour ne puissent être validés. '
                        'Une marge de temps est définie : au-delà, il est marqué en retard.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
