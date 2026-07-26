import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/role_dashboards.dart';
import '../../../auth/domain/entities/personnel.dart';
import '../../../../shared/widgets/ai/ai_floating_button.dart';
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
            // Chat IA flottant : demandé pour le dashboard AVS (voir
            // README de la passe en cours). Placé ici (dans le shell
            // partagé par tous les rôles) plutôt que dans chaque page, pour
            // qu'il apparaisse sur les 4 onglets sans dupliquer le code —
            // limité au rôle AVS pour l'instant pour ne rien changer aux
            // autres dashboards, déjà éprouvés.
            if (config.role == RolePersonnel.avs) const AiFloatingButton(),
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

/// Bottom navigation en thème sombre "flottant" : une pilule arrondie avec
/// ombre portée, détachée des bords de l'écran, volontairement indépendante
/// du thème clair du reste de l'app (voir `AppColors.navBackground` & co).
/// L'onglet actif se détache via un indicateur pilule + icône/label dans
/// l'accent turquoise de la marque, pour rester lisible sur fond noir.
class _DarkNavigationBar extends StatelessWidget {
  final RoleDashboardConfig config;
  final StatefulNavigationShell navigationShell;

  const _DarkNavigationBar({
    required this.config,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF10181D),
      child: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.navIndicator,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            indicatorShape: const StadiumBorder(),
            labelTextStyle: MaterialStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 11,
                fontWeight: states.contains(MaterialState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(MaterialState.selected)
                    ? AppColors.navSelected
                    : AppColors.navUnselected,
              ),
            ),
            iconTheme: MaterialStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 23,
                color: states.contains(MaterialState.selected)
                    ? AppColors.navSelected
                    : AppColors.navUnselected,
              ),
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
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
      ),
    );
  }
}
