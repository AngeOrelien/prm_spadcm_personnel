import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/avs_entities.dart';
import '../providers/avs_providers.dart';
import '../widgets/avs_widgets.dart';

/// Onglet "Accueil" de l'AVS (remplace l'ancien onglet "Planning", qui
/// pointait vers une route backend inexistante — voir `BACKEND-TODO.md`) :
/// vue d'ensemble rapide de la journée (statut de présence, patient assigné,
/// stats de ponctualité, derniers rapports).
class AvsAccueilPage extends ConsumerWidget {
  const AvsAccueilPage({super.key});

  void _rafraichirTout(WidgetRef ref) {
    ref.invalidate(presenceDuJourProvider);
    ref.invalidate(mesPatientsProvider);
    ref.invalidate(mesRapportsProvider);
    ref.invalidate(mesStatistiquesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;
    final presenceAsync = ref.watch(presenceDuJourProvider);
    final patientsAsync = ref.watch(mesPatientsProvider);
    final rapportsAsync = ref.watch(mesRapportsProvider);
    final statsAsync = ref.watch(mesStatistiquesProvider);

    final patients = patientsAsync.whenOrNull(data: (v) => v) ?? const <Patient>[];
    final rapports = rapportsAsync.whenOrNull(data: (v) => v) ?? const <RapportAvs>[];
    final chargementInitial = presenceAsync.isLoading && !presenceAsync.hasValue;

    return Column(
      children: [
        AppDashboardHeader.greeting(
          nomComplet: personnel?.nomComplet ?? '',
          libelleRole: 'Agent AVS',
          onTapProfil: () => context.push(AppRoutes.avsProfil),
          actions: [
            HeaderAction(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              onTap: () => context.showInfo('Notifications bientôt disponibles.'),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: chargementInitial
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => _rafraichirTout(ref),
                  child: ScrollRefreshListener(
                    onAtteintLeBas: () => _rafraichirTout(ref),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                          child: presenceAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (e, st) => const SizedBox.shrink(),
                            data: (presence) => _CartePresenceRapide(presence: presence),
                          ),
                        ),
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
                              StatCard(
                                valeur: '${patients.length}',
                                libelle: patients.length > 1 ? 'Patients suivis' : 'Patient suivi',
                                icon: Icons.favorite_border,
                                couleur: AppColors.primary,
                                onTap: () => context.go(AppRoutes.avsPatient),
                              ),
                              StatCard(
                                valeur: '${rapports.length}',
                                libelle: 'Rapports envoyés',
                                icon: Icons.fact_check_outlined,
                                couleur: AppColors.secondary,
                                onTap: () => context.push(AppRoutes.avsRapports),
                              ),
                              statsAsync.when(
                                loading: () => const StatCard(valeur: '—', libelle: 'Ponctualité', icon: Icons.timer_outlined, couleur: AppColors.info),
                                error: (e, st) => const StatCard(valeur: '—', libelle: 'Ponctualité', icon: Icons.timer_outlined, couleur: AppColors.info),
                                data: (stats) => StatCard(
                                  valeur: '${(stats.tauxPonctualite * 100).round()}%',
                                  libelle: 'Ponctualité rapports',
                                  icon: Icons.timer_outlined,
                                  couleur: AppColors.info,
                                ),
                              ),
                              statsAsync.when(
                                loading: () => const StatCard(valeur: '—', libelle: 'Absences', icon: Icons.event_busy_outlined, couleur: AppColors.error),
                                error: (e, st) => const StatCard(valeur: '—', libelle: 'Absences', icon: Icons.event_busy_outlined, couleur: AppColors.error),
                                data: (stats) => StatCard(
                                  valeur: '${stats.absences}',
                                  libelle: 'Absences',
                                  icon: Icons.event_busy_outlined,
                                  couleur: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SectionTitle(
                          titre: patients.length > 1 ? 'Mes patients' : 'Mon patient',
                          trailing: TextButton(
                            onPressed: () => context.go(AppRoutes.avsPatient),
                            child: const Text('Voir tout'),
                          ),
                        ),
                        if (patients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Text('Aucun patient assigné pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                          )
                        else
                          for (final patient in patients.take(2))
                            PatientSummaryTile(patient: patient, onTap: () => context.go(AppRoutes.avsPatient)),
                        const SizedBox(height: AppSpacing.sm),
                        SectionTitle(
                          titre: 'Rapports récents',
                          trailing: TextButton(
                            onPressed: () => context.push(AppRoutes.avsRapports),
                            child: const Text('Tout voir'),
                          ),
                        ),
                        if (rapports.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Text('Aucun rapport pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                          )
                        else
                          for (final rapport in rapports.take(3)) _RapportRecentTile(rapport: rapport, patients: patients),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CartePresenceRapide extends StatelessWidget {
  final Presence? presence;

  const _CartePresenceRapide({required this.presence});

  @override
  Widget build(BuildContext context) {
    final aFaitCheckIn = presence?.aFaitCheckIn ?? false;
    final couleur = aFaitCheckIn ? AppColors.success : AppColors.warning;

    return Material(
      color: couleur.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.go(AppRoutes.avsCheckin),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: couleur.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(aFaitCheckIn ? Icons.check_circle : Icons.login, color: couleur),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  aFaitCheckIn
                      ? 'Check-in effectué aujourd\'hui${presence?.aFaitCheckOut == true ? ' · check-out fait' : ''}'
                      : 'Check-in du jour pas encore effectué',
                  style: TextStyle(fontWeight: FontWeight.w600, color: couleur, fontSize: 13.5),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _RapportRecentTile extends StatelessWidget {
  final RapportAvs rapport;
  final List<Patient> patients;

  const _RapportRecentTile({required this.rapport, required this.patients});

  @override
  Widget build(BuildContext context) {
    Patient? patient;
    for (final p in patients) {
      if (p.id == rapport.patientId) {
        patient = p;
        break;
      }
    }

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
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.nomComplet ?? 'Patient',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(rapport.resume, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
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
