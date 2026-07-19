import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/role_dashboards.dart';
import '../widgets/side_quick_actions_menu.dart';

/// Scaffold commun à TOUS les dashboards (AVS, Médecin, Coordonnateur,
/// Administrateur) : contenu de l'onglet actif au milieu, bottom navigation
/// (thème sombre) en bas, et — si le rôle en définit — un petit menu
/// d'actions rapides sur le bord gauche.
///
/// Contrairement à une version précédente, ce shell n'impose plus de header
/// unique en haut de chaque page : chaque page (voir les pages du feature
/// `coordonnateur`) dessine désormais son propre [AppDashboardHeader],
/// personnalisé selon son contenu (titre, sous-titre, actions à droite).
///
/// Un seul widget pour les 4 rôles : ce qui change d'un rôle à l'autre (les
/// onglets, les actions rapides) vient uniquement de [RoleDashboardConfig]
/// (voir `router/role_dashboards.dart`), pas de ce fichier.
class RoleDashboardShell extends ConsumerWidget {
  final RoleDashboardConfig config;
  final StatefulNavigationShell navigationShell;

  const RoleDashboardShell({
    super.key,
    required this.config,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: navigationShell),
            if (config.quickActions.isNotEmpty)
              SideQuickActionsMenu(actions: config.quickActions),
          ],
        ),
      ),
      bottomNavigationBar: _DarkNavigationBar(
        config: config,
        navigationShell: navigationShell,
      ),
    );
  }
}

/// Bottom navigation en thème sombre, volontairement indépendant du thème
/// clair du reste de l'app (voir `AppColors.navBackground` & co).
class _DarkNavigationBar extends StatelessWidget {
  final RoleDashboardConfig config;
  final StatefulNavigationShell navigationShell;

  const _DarkNavigationBar({required this.config, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.navBackground,
          indicatorColor: AppColors.navIndicator,
          surfaceTintColor: Colors.transparent,
          height: 64,
          labelTextStyle: MaterialStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(MaterialState.selected) ? FontWeight.w600 : FontWeight.w400,
              color: states.contains(MaterialState.selected) ? AppColors.navSelected : AppColors.navUnselected,
            ),
          ),
          iconTheme: MaterialStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected) ? AppColors.navSelected : AppColors.navUnselected,
            ),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in config.tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon ?? tab.icon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
