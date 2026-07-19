import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Page d'accueil du coordonnateur : vue d'ensemble de son activité
/// (patients, équipe AVS, affectations, rapports à valider) + accès rapide
/// aux tâches courantes.
///
/// Header "greeting" (avatar + "Bonjour, X") : c'est la seule page du
/// dashboard qui utilise ce mode, les autres pages ont un header "titre".
class CoordonnateurAccueilPage extends ConsumerWidget {
  const CoordonnateurAccueilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;
    final patients = ref.watch(patientsListProvider);
    final avsListe = ref.watch(avsListProvider);
    final affectations = ref.watch(affectationsListProvider);
    final rapportsEnAttente = ref.watch(rapportsEnAttenteProvider);
    final rapports = ref.watch(rapportsListProvider);

    final avsDisponibles = avsListe.where((a) => a.statut == StatutAvs.disponible).length;

    return Column(
      children: [
        AppDashboardHeader.greeting(
          nomComplet: personnel?.nomComplet ?? '',
          libelleRole: 'Coordonnateur',
          onTapProfil: () => context.go(AppRoutes.coordonnateurProfil),
          actions: [
            HeaderAction(
              icon: Icons.notifications_outlined,
              tooltip: 'Notifications',
              badge: rapportsEnAttente > 0,
              onTap: () => context.showInfo('Notifications bientôt disponibles.'),
            ),
            HeaderAction(
              icon: Icons.settings_outlined,
              tooltip: 'Paramètres',
              onTap: () => context.go(AppRoutes.coordonnateurProfil),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
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
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      valeur: '${patients.length}',
                      libelle: 'Patients suivis',
                      icon: Icons.people_alt_outlined,
                      couleur: AppColors.primary,
                      onTap: () => context.go(AppRoutes.coordonnateurPatients),
                    ),
                    StatCard(
                      valeur: '${avsListe.length}',
                      libelle: '$avsDisponibles AVS disponibles',
                      icon: Icons.badge_outlined,
                      couleur: AppColors.info,
                      onTap: () => context.go(AppRoutes.coordonnateurEquipe),
                    ),
                    StatCard(
                      valeur: '${affectations.length}',
                      libelle: 'Affectations actives',
                      icon: Icons.assignment_ind_outlined,
                      couleur: AppColors.roleCoordonnateur,
                      onTap: () => context.push(AppRoutes.coordonnateurAffectations),
                    ),
                    StatCard(
                      valeur: '$rapportsEnAttente',
                      libelle: 'Rapports à valider',
                      icon: Icons.fact_check_outlined,
                      couleur: AppColors.secondary,
                      onTap: () => context.go(AppRoutes.coordonnateurRapports),
                    ),
                  ],
                ),
              ),
              SectionTitle(
                titre: 'Rapports récents des AVS',
                trailing: TextButton(
                  onPressed: () => context.go(AppRoutes.coordonnateurRapports),
                  child: const Text('Tout voir'),
                ),
              ),
              for (final rapport in rapports.take(3))
                _RapportApercu(rapport: rapport, avsListe: avsListe, patients: patients),
              const SizedBox(height: AppSpacing.sm),
              SectionTitle(titre: 'Équipe AVS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final avs in avsListe)
                      Chip(
                        avatar: InitialsAvatar(nomComplet: avs.nomComplet, couleur: avs.statut.couleur),
                        label: Text(avs.nomComplet),
                        backgroundColor: AppColors.surfaceMuted,
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

class _RapportApercu extends StatelessWidget {
  final RapportAvs rapport;
  final List<Avs> avsListe;
  final List<Patient> patients;

  const _RapportApercu({required this.rapport, required this.avsListe, required this.patients});

  @override
  Widget build(BuildContext context) {
    final avs = _trouverAvs(avsListe, rapport.avsId);
    final patient = _trouverPatient(patients, rapport.patientId);

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
            InitialsAvatar(nomComplet: avs?.nomComplet ?? '?'),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${avs?.nomComplet ?? 'AVS'} · ${patient?.nomComplet ?? 'Patient'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    rapport.resume,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
