import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/medecin_providers.dart';

/// Onglet "Messagerie" : un fil par patient suivi.
class MedecinMessageriePage extends ConsumerWidget {
  const MedecinMessageriePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(mesPatientsMedecinProvider);

    return Column(
      children: [
        const AppDashboardHeader.page(title: 'Messagerie', subtitle: 'Un fil par patient', leadingIcon: Icons.forum_outlined),
        const Divider(height: 1),
        Expanded(
          child: patientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const SizedBox.shrink(),
            data: (patients) {
              if (patients.isEmpty) {
                return Center(
                  child: Text('Aucun échange pour l\'instant.', style: Theme.of(context).textTheme.bodySmall),
                );
              }
              return ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final p = patients[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(Icons.person_outline, color: AppColors.roleMedecin, size: 20),
                    ),
                    title: Text(p.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.pathologiePrincipale),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                    onTap: () => context.push(
                      AppRoutes.medecinMessagerieConversation(p.id),
                      extra: {'nom': p.nomComplet, 'sousTitre': 'Patient'},
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
