import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/medecin_providers.dart';

/// Onglet "Patients" : dossiers médicaux des patients liés au médecin
/// (rôle en étude, accès volontairement restreint — README §7.2).
class MedecinPatientsPage extends ConsumerWidget {
  const MedecinPatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;
    final patientsAsync = ref.watch(mesPatientsMedecinProvider);

    return Column(
      children: [
        AppDashboardHeader.greeting(nomComplet: personnel?.nomComplet ?? '', libelleRole: 'Médecin'),
        const Divider(height: 1),
        Expanded(
          child: patientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(mesPatientsMedecinProvider)),
            data: (patients) {
              if (patients.isEmpty) {
                return const Center(
                  child: EmptyStateCard(
                    icon: Icons.folder_shared_outlined,
                    titre: 'Aucun dossier',
                    message: 'Les patients qui te sont liés apparaîtront ici.',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(mesPatientsMedecinProvider),
                child: ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];
                    return ListTile(
                      onTap: () => context.push(AppRoutes.medecinPatientDetail(p.id)),
                      leading: InitialsAvatar(nomComplet: p.nomComplet, couleur: AppColors.roleMedecin),
                      title: Text(p.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.age} ans · ${p.pathologiePrincipale}'),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
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
