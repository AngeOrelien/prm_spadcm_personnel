import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/medecin_providers.dart';
import '../widgets/medecin_widgets.dart';
import 'medecin_prescription_form_page.dart';

/// Onglet "Prescriptions" : traitements émis, actifs ou terminés.
class MedecinPrescriptionsPage extends ConsumerWidget {
  const MedecinPrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traitementsAsync = ref.watch(traitementsProvider);

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Prescriptions',
          subtitle: 'Traitements émis',
          leadingIcon: Icons.medication_outlined,
          actions: [
            HeaderAction(
              icon: Icons.add,
              tooltip: 'Nouvelle prescription',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MedecinPrescriptionFormPage()),
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: traitementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(traitementsProvider)),
            data: (traitements) {
              if (traitements.isEmpty) {
                return Center(
                  child: EmptyStateCard(
                    icon: Icons.medication_outlined,
                    titre: 'Aucune prescription',
                    message: 'Émets une prescription depuis le bouton "+".',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MedecinPrescriptionFormPage()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle prescription'),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(traitementsProvider),
                child: ListView.builder(
                  itemCount: traitements.length,
                  itemBuilder: (context, index) {
                    final t = traitements[index];
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
                                  Text(t.medicament, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${t.patientNom} · ${t.posologie}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            StatusChip(label: t.statut.libelle, couleur: t.statut.couleur),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
