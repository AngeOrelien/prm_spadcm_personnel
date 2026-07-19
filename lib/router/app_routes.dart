/// Centralise TOUS les chemins de route de l'app Personnel, pour éviter les
/// chaînes de caractères éparpillées dans les écrans (`context.go('/avs')`
/// devient `context.go(AppRoutes.avsAccueil)`).
///
/// Organisation : routes publiques d'abord, puis un bloc par rôle. Chaque
/// bloc "dashboard" liste son chemin de base (utilisé par le redirect pour
/// savoir où envoyer l'utilisateur après connexion) et ses onglets.
abstract class AppRoutes {
  AppRoutes._();

  // --- Public (avant connexion) ---
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';

  // --- AVS ---
  static const avsDashboard = '/avs';
  static const avsAccueil = '/avs/accueil';
  static const avsPlanning = '/avs/planning';
  static const avsPatients = '/avs/patients';
  static const avsProfil = '/avs/profil';

  // --- Médecin ---
  static const medecinDashboard = '/medecin';
  static const medecinAccueil = '/medecin/accueil';
  static const medecinRendezVous = '/medecin/rendez-vous';
  static const medecinPatients = '/medecin/patients';
  static const medecinProfil = '/medecin/profil';

  // --- Coordonnateur ---
  static const coordonnateurDashboard = '/coordonnateur';
  static const coordonnateurAccueil = '/coordonnateur/accueil';
  static const coordonnateurPatients = '/coordonnateur/patients';
  static const coordonnateurEquipe = '/coordonnateur/equipe';
  static const coordonnateurRapports = '/coordonnateur/rapports';
  static const coordonnateurProfil = '/coordonnateur/profil';
  // Pages ouvertes en plein écran depuis le menu d'actions rapides ou depuis
  // un onglet (pas des onglets en soi, donc pas dans la bottom navigation).
  static const coordonnateurAffectations = '/coordonnateur/affectations';
  static const coordonnateurNouveauPatient = '/coordonnateur/patients/nouveau';
  static const coordonnateurNouvelAvs = '/coordonnateur/equipe/nouveau';

  // --- Administrateur ---
  static const administrateurDashboard = '/administrateur';
  static const administrateurAccueil = '/administrateur/accueil';
  static const administrateurPersonnel = '/administrateur/personnel';
  static const administrateurStatistiques = '/administrateur/statistiques';
  static const administrateurProfil = '/administrateur/profil';
}
