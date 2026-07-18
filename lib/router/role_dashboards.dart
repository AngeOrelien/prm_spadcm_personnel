import 'package:flutter/material.dart';

import '../features/auth/domain/entities/personnel.dart';
import 'app_routes.dart';

/// Un onglet de bottom navigation : icône + libellé + chemin de route.
class DashboardTab {
  final String label;
  final IconData icon;
  final String path;

  const DashboardTab({required this.label, required this.icon, required this.path});
}

/// Config complète du dashboard d'un rôle : chemin de base (utilisé par le
/// redirect pour envoyer l'utilisateur au bon endroit après connexion) et
/// liste des onglets de sa bottom navigation.
///
/// Le dernier onglet de chaque rôle est conventionnellement "Profil" — le
/// header y renvoie quand on tape sur l'avatar (voir [RoleDashboardShell]).
class RoleDashboardConfig {
  final RolePersonnel role;
  final String libelleRole;
  final String basePath;
  final List<DashboardTab> tabs;

  const RoleDashboardConfig({
    required this.role,
    required this.libelleRole,
    required this.basePath,
    required this.tabs,
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
      DashboardTab(label: 'Profil', icon: Icons.person_outline, path: AppRoutes.avsProfil),
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
      DashboardTab(label: 'Profil', icon: Icons.person_outline, path: AppRoutes.medecinProfil),
    ],
  ),
  RolePersonnel.coordonnateur: const RoleDashboardConfig(
    role: RolePersonnel.coordonnateur,
    libelleRole: 'Coordonnateur',
    basePath: AppRoutes.coordonnateurDashboard,
    tabs: [
      DashboardTab(label: 'Accueil', icon: Icons.home_outlined, path: AppRoutes.coordonnateurAccueil),
      DashboardTab(label: 'Équipe', icon: Icons.groups_outlined, path: AppRoutes.coordonnateurEquipe),
      DashboardTab(label: 'Interventions', icon: Icons.assignment_outlined, path: AppRoutes.coordonnateurInterventions),
      DashboardTab(label: 'Profil', icon: Icons.person_outline, path: AppRoutes.coordonnateurProfil),
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
      DashboardTab(label: 'Profil', icon: Icons.person_outline, path: AppRoutes.administrateurProfil),
    ],
  ),
};
