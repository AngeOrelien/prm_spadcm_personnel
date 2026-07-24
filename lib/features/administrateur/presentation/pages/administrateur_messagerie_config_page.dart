import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../../../shared/widgets/pages/messagerie_stub_page.dart';

/// Onglet "Messagerie / Config" : vue d'ensemble des échanges + réglages
/// globaux de l'app (README §3.4 & §7.2).
class AdministrateurMessagerieConfigPage extends StatelessWidget {
  const AdministrateurMessagerieConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Messagerie & config',
          subtitle: 'Supervision et réglages',
          leadingIcon: Icons.settings_outlined,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              const _SectionLabel(titre: 'Messagerie'),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.support_agent_outlined, color: AppColors.primary, size: 20),
                ),
                title: const Text('Fils Administration', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Conversations avec les AVS et coordonnateurs'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MessagerieStubPage(
                      interlocuteurNom: 'Fils Administration',
                      interlocuteurSousTitre: 'Toutes équipes',
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              const _SectionLabel(titre: 'Réglages de l\'application'),
              const ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Alertes retards, absences, paiements'),
                trailing: Switch(value: true, onChanged: null),
              ),
              const ListTile(
                leading: Icon(Icons.timer_outlined),
                title: Text('Marge de tolérance check-in', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('15 minutes avant \'en retard\''),
                trailing: Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ),
              const ListTile(
                leading: Icon(Icons.security_outlined),
                title: Text('Rôles et permissions', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Gérer les droits par rôle'),
                trailing: Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String titre;

  const _SectionLabel({required this.titre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        titre.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}
