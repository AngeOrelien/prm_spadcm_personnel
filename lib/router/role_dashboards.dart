import 'package:flutter/material.dart';

import '../features/administrateur/presentation/pages/administrateur_accueil_page.dart';
import '../features/administrateur/presentation/pages/administrateur_messagerie_config_page.dart';
import '../features/administrateur/presentation/pages/administrateur_paiements_page.dart';
import '../features/administrateur/presentation/pages/administrateur_statistiques_page.dart';
import '../features/administrateur/presentation/pages/administrateur_utilisateurs_page.dart';
import '../features/auth/domain/entities/personnel.dart';
import '../features/avs/presentation/pages/avs_checkin_page.dart';
import '../features/avs/presentation/pages/avs_messages_page.dart';
import '../features/avs/presentation/pages/avs_planning_page.dart';
import '../features/avs/presentation/pages/avs_rapports_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_accueil_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_equipe_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_messagerie_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patients_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_rapports_page.dart';
import '../features/medecin/presentation/pages/medecin_messagerie_page.dart';
import '../features/medecin/presentation/pages/medecin_patients_page.dart';
import '../features/medecin/presentation/pages/medecin_prescriptions_page.dart';
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
/// [AppDashboardHeader] / son bouton overflow), façon WhatsApp — conforme
/// au README §7.2, qui ne liste "Profil" dans aucune bottom navigation de
/// l'app Personnel.
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
  // --- AVS : Planning / Rapports / Check-in / Messages (README §7.2) ---
  RolePersonnel.avs: RoleDashboardConfig(
    role: RolePersonnel.avs,
    libelleRole: 'Agent AVS',
    basePath: AppRoutes.avsDashboard,
    tabs: [
      DashboardTab(
        label: 'Planning',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        path: AppRoutes.avsPlanning,
        pageBuilder: _avsPlanning,
      ),
      DashboardTab(
        label: 'Rapports',
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
        path: AppRoutes.avsRapports,
        pageBuilder: _avsRapports,
      ),
      DashboardTab(
        label: 'Check-in',
        icon: Icons.location_on_outlined,
        selectedIcon: Icons.location_on,
        path: AppRoutes.avsCheckin,
        pageBuilder: _avsCheckin,
      ),
      DashboardTab(
        label: 'Messages',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        path: AppRoutes.avsMessages,
        pageBuilder: _avsMessages,
      ),
    ],
  ),

  // --- Médecin (rôle en étude) : Patients / Prescriptions / Messagerie ---
  RolePersonnel.medecin: RoleDashboardConfig(
    role: RolePersonnel.medecin,
    libelleRole: 'Médecin',
    basePath: AppRoutes.medecinDashboard,
    tabs: [
      DashboardTab(
        label: 'Patients',
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt,
        path: AppRoutes.medecinPatients,
        pageBuilder: _medecinPatients,
      ),
      DashboardTab(
        label: 'Prescriptions',
        icon: Icons.medication_outlined,
        selectedIcon: Icons.medication,
        path: AppRoutes.medecinPrescriptions,
        pageBuilder: _medecinPrescriptions,
      ),
      DashboardTab(
        label: 'Messagerie',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        path: AppRoutes.medecinMessagerie,
        pageBuilder: _medecinMessagerie,
      ),
    ],
  ),

  // --- Coordonnateur : Accueil / Patients / Équipe / Rapports / Messagerie ---
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
      DashboardTab(
        label: 'Messagerie',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        path: AppRoutes.coordonnateurMessagerieTab,
        pageBuilder: (context) => const CoordonnateurMessageriePage(),
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

  // --- Administrateur : Tableau de bord / Utilisateurs / Paiements / Statistiques / Messagerie-Config ---
  RolePersonnel.administrateur: RoleDashboardConfig(
    role: RolePersonnel.administrateur,
    libelleRole: 'Administrateur',
    basePath: AppRoutes.administrateurDashboard,
    tabs: [
      DashboardTab(
        label: 'Tableau de bord',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        path: AppRoutes.administrateurAccueil,
        pageBuilder: _administrateurAccueil,
      ),
      DashboardTab(
        label: 'Utilisateurs',
        icon: Icons.manage_accounts_outlined,
        selectedIcon: Icons.manage_accounts,
        path: AppRoutes.administrateurUtilisateurs,
        pageBuilder: _administrateurUtilisateurs,
      ),
      DashboardTab(
        label: 'Paiements',
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        path: AppRoutes.administrateurPaiements,
        pageBuilder: _administrateurPaiements,
      ),
      DashboardTab(
        label: 'Statistiques',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        path: AppRoutes.administrateurStatistiques,
        pageBuilder: _administrateurStatistiques,
      ),
      DashboardTab(
        label: 'Messagerie',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        path: AppRoutes.administrateurMessagerie,
        pageBuilder: _administrateurMessagerie,
      ),
    ],
  ),
};

// Fonctions statiques (plutôt que des closures inline) pour que les builders
// des `const RoleDashboardConfig` restent des tear-offs valides en `const`.
Widget _avsPlanning(BuildContext context) => const AvsPlanningPage();
Widget _avsRapports(BuildContext context) => const AvsRapportsPage();
Widget _avsCheckin(BuildContext context) => const AvsCheckinPage();
Widget _avsMessages(BuildContext context) => const AvsMessagesPage();

Widget _medecinPatients(BuildContext context) => const MedecinPatientsPage();
Widget _medecinPrescriptions(BuildContext context) => const MedecinPrescriptionsPage();
Widget _medecinMessagerie(BuildContext context) => const MedecinMessageriePage();

Widget _administrateurAccueil(BuildContext context) => const AdministrateurAccueilPage();
Widget _administrateurUtilisateurs(BuildContext context) => const AdministrateurUtilisateursPage();
Widget _administrateurPaiements(BuildContext context) => const AdministrateurPaiementsPage();
Widget _administrateurStatistiques(BuildContext context) => const AdministrateurStatistiquesPage();
Widget _administrateurMessagerie(BuildContext context) => const AdministrateurMessagerieConfigPage();
