import 'package:flutter/material.dart';

import '../features/auth/domain/entities/personnel.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_accueil_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_equipe_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patients_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_rapports_page.dart';
import 'app_routes.dart';

/// Construit le contenu d'un onglet. Reçoit le [BuildContext] pour pouvoir
/// naviguer (context.push, context.go...) depuis la page elle-même.
typedef DashboardPageBuilder = Widget Function(BuildContext context);

/// Un onglet de bottom navigation : icône + libellé + chemin de route.
///
/// [pageBuilder] fournit le contenu réel de l'onglet (header personnalisé
/// inclus : chaque page dessine son propre en-tête, voir
/// `AppDashboardHeader`). Si absent, [RoleDashboardShell] retombe sur
/// [DashboardTabPlaceholder] — utile pour les rôles pas encore développés.
class DashboardTab {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String path;
  final DashboardPageBuilder? pageBuilder;

  const DashboardTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.path,
    this.pageBuilder,
  });
}

/// Une action rapide du petit menu vertical façon WhatsApp (le menu qui
/// s'ouvre depuis le côté gauche de l'écran). Chaque action pousse vers une
/// route précise.
class QuickAction {
  final String label;
  final IconData icon;
  final String route;

  const QuickAction({required this.label, required this.icon, required this.route});
}

/// Config complète du dashboard d'un rôle : chemin de base (utilisé par le
/// redirect pour envoyer l'utilisateur au bon endroit après connexion),
/// liste des onglets de sa bottom navigation, et actions rapides du menu
/// latéral (peut être vide : le menu ne s'affiche alors pas du tout).
///
/// "Profil" n'est PLUS un onglet de bottom navigation pour aucun rôle : il
/// est accessible pour tous depuis le menu "⋮" du header (voir
/// [AppDashboardHeader] / son bouton overflow), façon WhatsApp.
class RoleDashboardConfig {
  final RolePersonnel role;
  final String libelleRole;
  final String basePath;
  final List<DashboardTab> tabs;
  final List<QuickAction> quickActions;

  const RoleDashboardConfig({
    required this.role,
    required this.libelleRole,
    required this.basePath,
    required this.tabs,
    this.quickActions = const [],
  });
}

/// Point unique à modifier pour ajouter/renommer/réordonner les onglets
/// d'un rôle donné, sans toucher au router lui-même.
final Map<RolePersonnel, RoleDashboardConfig> roleDashboards = {
  RolePersonnel.avs: const RoleDashboardConfig(
    role: RolePersonnel.avs,
    libelleRole: 'Agent AVS',
    basePath: AppRoutes.avsDashboard,
    tabs: [
      DashboardTab(label: 'Accueil', icon: Icons.home_outlined, path: AppRoutes.avsAccueil),
      DashboardTab(label: 'Planning', icon: Icons.calendar_month_outlined, path: AppRoutes.avsPlanning),
      DashboardTab(label: 'Patients', icon: Icons.people_alt_outlined, path: AppRoutes.avsPatients),
    ],
  ),
  RolePersonnel.medecin: const RoleDashboardConfig(
    role: RolePersonnel.medecin,
    libelleRole: 'Médecin',
    basePath: AppRoutes.medecinDashboard,
    tabs: [
      DashboardTab(label: 'Accueil', icon: Icons.home_outlined, path: AppRoutes.medecinAccueil),
      DashboardTab(label: 'Rendez-vous', icon: Icons.event_note_outlined, path: AppRoutes.medecinRendezVous),
      DashboardTab(label: 'Patients', icon: Icons.people_alt_outlined, path: AppRoutes.medecinPatients),
    ],
  ),
  RolePersonnel.coordonnateur: RoleDashboardConfig(
    role: RolePersonnel.coordonnateur,
    libelleRole: 'Coordonnateur',
    basePath: AppRoutes.coordonnateurDashboard,
    tabs: [
      DashboardTab(
        label: 'Accueil',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        path: AppRoutes.coordonnateurAccueil,
        pageBuilder: (context) => const CoordonnateurAccueilPage(),
      ),
      DashboardTab(
        label: 'Patients',
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt,
        path: AppRoutes.coordonnateurPatients,
        pageBuilder: (context) => const CoordonnateurPatientsPage(),
      ),
      DashboardTab(
        label: 'Équipe',
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        path: AppRoutes.coordonnateurEquipe,
        pageBuilder: (context) => const CoordonnateurEquipePage(),
      ),
      DashboardTab(
        label: 'Rapports',
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
        path: AppRoutes.coordonnateurRapports,
        pageBuilder: (context) => const CoordonnateurRapportsPage(),
      ),
    ],
    quickActions: const [
      QuickAction(
        label: 'Nouvelle affectation',
        icon: Icons.assignment_ind_outlined,
        route: AppRoutes.coordonnateurAffectations,
      ),
      QuickAction(
        label: 'Ajouter un patient',
        icon: Icons.person_add_alt_1_outlined,
        route: AppRoutes.coordonnateurNouveauPatient,
      ),
      QuickAction(
        label: 'Ajouter un AVS',
        icon: Icons.badge_outlined,
        route: AppRoutes.coordonnateurNouvelAvs,
      ),
    ],
  ),
  RolePersonnel.administrateur: const RoleDashboardConfig(
    role: RolePersonnel.administrateur,
    libelleRole: 'Administrateur',
    basePath: AppRoutes.administrateurDashboard,
    tabs: [
      DashboardTab(label: 'Accueil', icon: Icons.home_outlined, path: AppRoutes.administrateurAccueil),
      DashboardTab(label: 'Personnel', icon: Icons.badge_outlined, path: AppRoutes.administrateurPersonnel),
      DashboardTab(label: 'Statistiques', icon: Icons.bar_chart_outlined, path: AppRoutes.administrateurStatistiques),
    ],
  ),
};
