import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../../shared/widgets/pages/messagerie_stub_page.dart';
import '../providers/avs_providers.dart';

/// Onglet "Messages" : deux types de fils — Administration (besoins
/// matériel/logistique) et un fil par patient/famille assigné (README §3.2).
class AvsMessagesPage extends ConsumerWidget {
  const AvsMessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planningAsync = ref.watch(monPlanningProvider);
    final patientsUniques = <String, String>{};
    planningAsync.whenData((visites) {
      for (final v in visites) {
        patientsUniques[v.patientId] = v.patientNom;
      }
    });

    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Messages',
          subtitle: 'Administration et familles',
          leadingIcon: Icons.forum_outlined,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            children: [
              _FilTile(
                titre: 'Administration',
                sousTitre: 'Besoins matériel & logistique',
                icone: Icons.support_agent_outlined,
                couleur: AppColors.roleAdministrateur,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MessagerieStubPage(
                      interlocuteurNom: 'Administration',
                      interlocuteurSousTitre: 'Support logistique',
                    ),
                  ),
                ),
              ),
              const SectionTitle(titre: 'Familles / patients'),
              if (patientsUniques.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Aucun échange pour l\'instant.', style: Theme.of(context).textTheme.bodySmall),
                )
              else
                for (final entry in patientsUniques.entries)
                  _FilTile(
                    titre: entry.value,
                    sousTitre: 'Famille / patient',
                    icone: Icons.family_restroom_outlined,
                    couleur: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MessagerieStubPage(
                          interlocuteurNom: entry.value,
                          interlocuteurSousTitre: 'Patient / famille',
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilTile extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  const _FilTile({
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: couleur.withOpacity(0.12),
        child: Icon(icone, color: couleur, size: 20),
      ),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sousTitre),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
    );
  }
}
