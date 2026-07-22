import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Gestion des patients : liste, recherche, ajout. Chaque ligne ouvre
/// désormais la fiche patient plein écran (voir
/// `coordonnateur_patient_detail_page.dart`) plutôt qu'un simple aperçu.
class CoordonnateurPatientsPage extends ConsumerStatefulWidget {
  const CoordonnateurPatientsPage({super.key});

  @override
  ConsumerState<CoordonnateurPatientsPage> createState() => _CoordonnateurPatientsPageState();
}

class _CoordonnateurPatientsPageState extends ConsumerState<CoordonnateurPatientsPage> {
  final _recherche = TextEditingController();
  String _requete = '';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsListProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Patients',
          subtitle: patientsAsync.maybeWhen(
            data: (patients) => '${patients.length} patients suivis',
            orElse: () => null,
          ),
          leadingIcon: Icons.people_alt_outlined,
          actions: [
            HeaderAction(
              icon: Icons.person_add_alt_1_outlined,
              tooltip: 'Ajouter un patient',
              onTap: () => context.push(AppRoutes.coordonnateurNouveauPatient),
            ),
          ],
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: TextField(
            controller: _recherche,
            onChanged: (v) => setState(() => _requete = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher un patient…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: patientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(patientsListProvider)),
            data: (patients) {
              final filtres = _requete.isEmpty
                  ? patients
                  : patients.where((p) => p.nomComplet.toLowerCase().contains(_requete.toLowerCase())).toList();

              if (filtres.isEmpty) {
                return Center(
                  child: Text('Aucun patient trouvé', style: Theme.of(context).textTheme.bodyMedium),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                itemCount: filtres.length,
                itemBuilder: (context, index) => _PatientTile(patient: filtres[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PatientTile extends StatelessWidget {
  final Patient patient;

  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    final assigne = patient.avsAssigneId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: InitialsAvatar(nomComplet: patient.nomComplet),
        title: Text(
          patient.age != null ? '${patient.nomComplet} · ${patient.age} ans' : patient.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${patient.pathologie}\n${patient.adresse}'),
        isThreeLine: true,
        trailing: assigne
            ? StatusChip(label: patient.avsAssigneNom ?? 'AVS assigné', couleur: AppColors.primary)
            : const StatusChip(label: 'Sans AVS', couleur: AppColors.warning),
        onTap: () => context.push(AppRoutes.coordonnateurPatientDetail(patient.id)),
      ),
    );
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
            const Text('Impossible de charger les patients.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
