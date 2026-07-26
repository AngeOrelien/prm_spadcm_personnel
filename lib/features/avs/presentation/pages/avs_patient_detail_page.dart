import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../providers/avs_providers.dart';
import 'avs_patient_page.dart';

/// Détail d'un patient précis, en page poussée (cas où l'AVS a plusieurs
/// patients actifs — voir `AvsPatientPage`). Route hors du shell de
/// dashboard, donc [Scaffold] explicite (même correctif que sur
/// `AvsProfilPage` pour éviter l'écran noir).
class AvsPatientDetailPage extends ConsumerWidget {
  final String patientId;

  const AvsPatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(mesPatientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: [
            const AppDashboardHeader.page(title: 'Fiche patient', leadingIcon: Icons.favorite_border, showBackButton: true),
            const Divider(height: 1),
            Expanded(
              child: patientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(mesPatientsProvider)),
                data: (patients) {
                  Patient? patient;
                  for (final p in patients) {
                    if (p.id == patientId) patient = p;
                  }
                  if (patient == null) {
                    return const Center(child: Text('Patient introuvable.'));
                  }
                  return PatientDetailContent(patient: patient);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
