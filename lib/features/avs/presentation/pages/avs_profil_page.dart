import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../providers/avs_providers.dart';

/// Profil de l'AVS : infos de compte + statistiques personnelles de
/// ponctualité (README §7.2).
class AvsProfilPage extends ConsumerWidget {
  const AvsProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;
    final statsAsync = ref.watch(mesStatistiquesProvider);

    return Column(
      children: [
        const AppDashboardHeader.page(title: 'Profil', leadingIcon: Icons.person_outline, showBackButton: true),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Column(
                  children: [
                    InitialsAvatar(nomComplet: personnel?.nomComplet ?? '', radius: 32),
                    const SizedBox(height: AppSpacing.sm),
                    Text(personnel?.nomComplet ?? '', style: Theme.of(context).textTheme.titleLarge),
                    Text(personnel?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    const StatusChip(label: 'Agent AVS', couleur: AppColors.roleAvs),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionTitle(titre: 'Statistiques de ponctualité'),
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(mesStatistiquesProvider)),
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      valeur: '${stats.rapportsATemps}',
                      libelle: 'Rapports à temps',
                      icon: Icons.check_circle_outline,
                      couleur: AppColors.success,
                    ),
                    StatCard(
                      valeur: '${stats.rapportsEnRetard}',
                      libelle: 'Rapports en retard',
                      icon: Icons.schedule_outlined,
                      couleur: AppColors.warning,
                    ),
                    StatCard(
                      valeur: '${stats.checkinsATemps}',
                      libelle: 'Check-ins à temps',
                      icon: Icons.login,
                      couleur: AppColors.primary,
                    ),
                    StatCard(
                      valeur: '${stats.absences}',
                      libelle: 'Absences',
                      icon: Icons.event_busy_outlined,
                      couleur: AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
