import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../router/role_dashboards.dart';
import '../widgets/app_dashboard_header.dart';

/// Scaffold commun à TOUS les dashboards (AVS, Médecin, Coordonnateur,
/// Administrateur) : header (profil + notifications + paramètres) en haut,
/// contenu de l'onglet actif au milieu, bottom navigation en bas.
///
/// Un seul widget pour les 4 rôles : ce qui change d'un rôle à l'autre (les
/// onglets) vient uniquement de [RoleDashboardConfig] (voir
/// `router/role_dashboards.dart`), pas de ce fichier.
class RoleDashboardShell extends ConsumerWidget {
  final RoleDashboardConfig config;
  final StatefulNavigationShell navigationShell;

  const RoleDashboardShell({
    super.key,
    required this.config,
    required this.navigationShell,
  });

  void _ouvrirMenuParametres(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.showInfo('Paramètres bientôt disponibles.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref.read(authControllerProvider.notifier).deconnecter();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppDashboardHeader(
              nomComplet: personnel?.nomComplet ?? '',
              libelleRole: config.libelleRole,
              onTapProfil: () => navigationShell.goBranch(config.tabs.length - 1),
              onTapNotifications: () => context.showInfo('Notifications bientôt disponibles.'),
              onTapParametres: () => _ouvrirMenuParametres(context, ref),
            ),
            const Divider(height: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in config.tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
