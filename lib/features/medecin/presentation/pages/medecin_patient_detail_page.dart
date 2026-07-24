import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../providers/medecin_providers.dart';
import '../widgets/medecin_widgets.dart';

/// Fiche patient consultée par le médecin : pathologie principale et
/// traitements en cours (accès restreint au dossier médical uniquement,
/// pas aux données administratives — README §7.2).
class MedecinPatientDetailPage extends ConsumerWidget {
  final String patientId;

  const MedecinPatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(mesPatientsMedecinProvider);
    final traitementsAsync = ref.watch(traitementsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Dossier médical'),
      ),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(mesPatientsMedecinProvider)),
        data: (patients) {
          final correspondants = patients.where((p) => p.id == patientId).toList();
          if (correspondants.isEmpty) {
            return const Center(child: Text('Patient introuvable'));
          }
          final patient = correspondants.first;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Column(
                  children: [
                    InitialsAvatar(nomComplet: patient.nomComplet, couleur: AppColors.roleMedecin, radius: 32),
                    const SizedBox(height: AppSpacing.sm),
                    Text(patient.nomComplet, style: Theme.of(context).textTheme.titleLarge),
                    Text('${patient.age} ans', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionTitle(titre: 'Pathologie principale'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(patient.pathologiePrincipale, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionTitle(titre: 'Traitements en cours'),
              traitementsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LinearProgressIndicator()),
                error: (e, st) => const SizedBox.shrink(),
                data: (traitements) {
                  final ceux = traitements.where((t) => t.patientNom == patient.nomComplet).toList();
                  if (ceux.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text('Aucun traitement en cours.', style: Theme.of(context).textTheme.bodySmall),
                    );
                  }
                  return Column(
                    children: [
                      for (final t in ceux)
                        ListTile(
                          leading: Icon(Icons.medication_outlined, color: t.statut.couleur),
                          title: Text(t.medicament, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(t.posologie),
                          trailing: StatusChip(label: t.statut.libelle, couleur: t.statut.couleur),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
