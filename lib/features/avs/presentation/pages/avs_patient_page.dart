import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/avs_providers.dart';
import '../widgets/avs_widgets.dart';

/// Onglet "Mon patient" : informations complètes sur le(s) patient(s)
/// actuellement assigné(s) à l'AVS, avec accès direct à la rédaction d'un
/// rapport. Le cas le plus courant est un seul patient actif (affiché en
/// détail directement dans l'onglet) ; si l'AVS a plusieurs patients actifs,
/// l'onglet affiche une liste et le détail s'ouvre en page poussée (voir
/// `AvsPatientDetailPage`).
class AvsPatientPage extends ConsumerWidget {
  const AvsPatientPage({super.key});

  void _rafraichir(WidgetRef ref) {
    ref.invalidate(mesPatientsProvider);
    ref.invalidate(mesAffectationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(mesPatientsProvider);

    return Column(
      children: [
        const AppDashboardHeader.page(title: 'Mon patient', leadingIcon: Icons.favorite_border),
        const Divider(height: 1),
        Expanded(
          child: patientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => ErreurChargement(onReessayer: () => _rafraichir(ref)),
            data: (patients) {
              if (patients.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => _rafraichir(ref),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      const EmptyStateCard(
                        icon: Icons.favorite_border,
                        titre: 'Aucun patient assigné',
                        message: 'Ton coordonnateur ne t\'a pas encore affecté à un patient.',
                      ),
                    ],
                  ),
                );
              }

              if (patients.length == 1) {
                return RefreshIndicator(
                  onRefresh: () async => _rafraichir(ref),
                  child: ScrollRefreshListener(
                    onAtteintLeBas: () => _rafraichir(ref),
                    child: PatientDetailContent(patient: patients.first),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _rafraichir(ref),
                child: ScrollRefreshListener(
                  onAtteintLeBas: () => _rafraichir(ref),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    itemCount: patients.length,
                    itemBuilder: (context, index) => PatientSummaryTile(
                      patient: patients[index],
                      onTap: () => context.push(AppRoutes.avsPatientDetail(patients[index].id)),
                    ),
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

/// Contenu détaillé d'un patient : identité, infos médicales, contact
/// d'urgence, bouton "Nouveau rapport" et historique de ses rapports.
/// Réutilisé par [AvsPatientPage] (patient unique, en onglet) et
/// `AvsPatientDetailPage` (plusieurs patients, en page poussée).
class PatientDetailContent extends ConsumerWidget {
  final Patient patient;

  const PatientDetailContent({super.key, required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affectationsAsync = ref.watch(mesAffectationsProvider);
    final rapportsAsync = ref.watch(mesRapportsDuPatientProvider(patient.id));

    Affectation? affectation;
    affectationsAsync.whenData((liste) {
      for (final a in liste) {
        if (a.patientId == patient.id) affectation = a;
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      children: [
        Row(
          children: [
            InitialsAvatar(nomComplet: patient.nomComplet, photoUrl: patient.photoUrl, radius: 28, couleur: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.nomComplet, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                  if (patient.pathologie.isNotEmpty)
                    Text(patient.pathologie, style: Theme.of(context).textTheme.bodySmall),
                  if (affectation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Visites : ${affectation!.frequence}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.avsNouveauRapport, extra: patient.id),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau rapport pour ce patient'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionTitle(titre: 'Informations'),
        _InfoTile(icon: Icons.home_outlined, label: 'Adresse', valeur: patient.adresse),
        if (patient.telephone != null && patient.telephone!.isNotEmpty)
          _InfoTile(icon: Icons.phone_outlined, label: 'Téléphone', valeur: patient.telephone!),
        if (patient.age != null) _InfoTile(icon: Icons.cake_outlined, label: 'Âge', valeur: '${patient.age} ans'),
        if (patient.antecedents.isNotEmpty)
          _InfoTile(icon: Icons.history_edu_outlined, label: 'Antécédents', valeur: patient.antecedents.join(', ')),
        if (patient.allergies.isNotEmpty)
          _InfoTile(icon: Icons.warning_amber_outlined, label: 'Allergies', valeur: patient.allergies.join(', '), couleur: AppColors.error),
        if (patient.difficultesMobilite.isNotEmpty)
          _InfoTile(icon: Icons.accessible_outlined, label: 'Mobilité', valeur: patient.difficultesMobilite.join(', ')),
        if (patient.contactUrgence != null && !patient.contactUrgence!.estVide) ...[
          const SizedBox(height: AppSpacing.sm),
          const SectionTitle(titre: 'Contact d\'urgence'),
          _InfoTile(
            icon: Icons.contact_phone_outlined,
            label: patient.contactUrgence!.lien ?? 'Contact',
            valeur: '${patient.contactUrgence!.nom ?? ''} · ${patient.contactUrgence!.telephone ?? ''}',
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SectionTitle(
          titre: 'Historique des rapports',
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.avsRapports),
            child: const Text('Tout voir'),
          ),
        ),
        rapportsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Impossible de charger l\'historique.', style: Theme.of(context).textTheme.bodySmall),
          ),
          data: (rapports) {
            if (rapports.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('Aucun rapport pour ce patient pour le moment.', style: Theme.of(context).textTheme.bodySmall),
              );
            }
            return Column(
              children: [
                for (final rapport in rapports.take(5))
                  Padding(
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
                            child: Text(
                              '${rapport.date.day.toString().padLeft(2, '0')}/${rapport.date.month.toString().padLeft(2, '0')}/${rapport.date.year} · ${rapport.resume}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;
  final Color? couleur;

  const _InfoTile({required this.icon, required this.label, required this.valeur, this.couleur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: couleur ?? AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textDisabled, fontWeight: FontWeight.w600)),
                Text(valeur, style: TextStyle(fontSize: 13.5, color: couleur ?? AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
