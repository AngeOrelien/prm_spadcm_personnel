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

/// Gestion des patients : liste, recherche, ajout, et assignation rapide
/// d'un AVS depuis la fiche patient.
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
    final patients = ref.watch(patientsListProvider);
    final avsListe = ref.watch(avsListProvider);

    final filtres = _requete.isEmpty
        ? patients
        : patients
            .where((p) => p.nomComplet.toLowerCase().contains(_requete.toLowerCase()))
            .toList();

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Patients',
          subtitle: '${patients.length} patients suivis',
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
          child: filtres.isEmpty
              ? Center(
                  child: Text('Aucun patient trouvé', style: Theme.of(context).textTheme.bodyMedium),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: filtres.length,
                  itemBuilder: (context, index) {
                    final patient = filtres[index];
                    final avs = _avsDe(avsListe, patient.avsAssigneId);
                    return _PatientTile(patient: patient, avs: avs);
                  },
                ),
        ),
      ],
    );
  }

  Avs? _avsDe(List<Avs> avsListe, String? avsId) {
    if (avsId == null) return null;
    for (final a in avsListe) {
      if (a.id == avsId) return a;
    }
    return null;
  }
}

class _PatientTile extends StatelessWidget {
  final Patient patient;
  final Avs? avs;

  const _PatientTile({required this.patient, required this.avs});

  @override
  Widget build(BuildContext context) {
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
        title: Text('${patient.nomComplet} · ${patient.age} ans', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${patient.pathologie}\n${patient.adresse}'),
        isThreeLine: true,
        trailing: avs != null
            ? StatusChip(label: avs!.nomComplet, couleur: AppColors.primary)
            : StatusChip(label: 'Sans AVS', couleur: AppColors.warning),
        onTap: () => _ouvrirDetail(context),
      ),
    );
  }

  void _ouvrirDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(nomComplet: patient.nomComplet),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.nomComplet, style: Theme.of(sheetContext).textTheme.titleLarge),
                          Text('${patient.age} ans · ${patient.pathologie}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _LigneInfo(icon: Icons.location_on_outlined, label: patient.adresse),
                _LigneInfo(
                  icon: Icons.badge_outlined,
                  label: avs != null ? 'AVS assigné : ${avs!.nomComplet}' : 'Aucun AVS assigné',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push(AppRoutes.coordonnateurAffectations);
                    },
                    icon: const Icon(Icons.assignment_ind_outlined),
                    label: Text(avs != null ? 'Modifier l\'affectation' : 'Assigner un AVS'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LigneInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
