/// Centralise TOUS les chemins de route de l'app Personnel, pour éviter les
/// chaînes de caractères éparpillées dans les écrans (`context.go('/avs')`
/// devient `context.go(AppRoutes.avsAccueil)`).
///
/// Organisation : routes publiques d'abord, puis un bloc par rôle. Chaque
/// bloc "dashboard" liste son chemin de base (utilisé par le redirect pour
/// savoir où envoyer l'utilisateur après connexion) et ses onglets.
///
/// Aucun rôle de l'app Personnel n'a d'onglet "Profil" dans sa bottom
/// navigation (voir README section 7.2) : la page profil reste accessible
/// pour tous via le menu "⋮" du header.
abstract class AppRoutes {
  AppRoutes._();

  // --- Public (avant connexion) ---
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';

  // --- AVS : Planning / Rapports / Check-in / Messages (4 onglets) ---
  static const avsDashboard = '/avs';
  static const avsPlanning = '/avs/planning';
  static const avsRapports = '/avs/rapports';
  static const avsCheckin = '/avs/checkin';
  static const avsMessages = '/avs/messages';
  static const avsProfil = '/avs/profil';
  static const avsNouveauRapport = '/avs/rapports/nouveau';
  static const avsRapportDetailPattern = '/avs/rapports/:id';
  static String avsRapportDetail(String id) => '/avs/rapports/$id';
  static const avsMessagerieAdministrationPattern = '/avs/messages/administration';
  static const avsMessageriePatientPattern = '/avs/messages/patient/:id';
  static String avsMessageriePatient(String id) => '/avs/messages/patient/$id';

  // --- Médecin (rôle en étude) : Patients / Prescriptions / Messagerie (3 onglets) ---
  static const medecinDashboard = '/medecin';
  static const medecinPatients = '/medecin/patients';
  static const medecinPrescriptions = '/medecin/prescriptions';
  static const medecinMessagerie = '/medecin/messagerie';
  static const medecinProfil = '/medecin/profil';
  static const medecinPatientDetailPattern = '/medecin/patients/:id';
  static String medecinPatientDetail(String id) => '/medecin/patients/$id';

  // --- Coordonnateur : Accueil / Patients / Équipe / Rapports / Messagerie (5 onglets) ---
  static const coordonnateurDashboard = '/coordonnateur';
  static const coordonnateurAccueil = '/coordonnateur/accueil';
  static const coordonnateurPatients = '/coordonnateur/patients';
  static const coordonnateurEquipe = '/coordonnateur/equipe';
  static const coordonnateurRapports = '/coordonnateur/rapports';
  static const coordonnateurMessagerieTab = '/coordonnateur/messagerie';
  static const coordonnateurProfil = '/coordonnateur/profil';
  // Pages ouvertes en plein écran depuis le menu d'actions rapides ou depuis
  // un onglet (pas des onglets en soi, donc pas dans la bottom navigation).
  static const coordonnateurAffectations = '/coordonnateur/affectations';
  static const coordonnateurNouveauPatient = '/coordonnateur/patients/nouveau';
  static const coordonnateurNouvelAvs = '/coordonnateur/equipe/nouveau';
  // Fiches détail plein écran (patient / AVS) + messagerie — routes
  // paramétrées, construites via les fonctions ci-dessous plutôt que des
  // constantes fixes.
  static const coordonnateurPatientDetailPattern = '/coordonnateur/patients/:id';
  static const coordonnateurAvsDetailPattern = '/coordonnateur/equipe/:id';
  static const coordonnateurMessagerieConversationPattern = '/coordonnateur/messagerie/:id';

  static String coordonnateurPatientDetail(String id) => '/coordonnateur/patients/$id';
  static String coordonnateurAvsDetail(String id) => '/coordonnateur/equipe/$id';
  static String coordonnateurMessagerieConversation(String id) => '/coordonnateur/messagerie/$id';

  // --- Administrateur : Tableau de bord / Utilisateurs / Paiements / Statistiques / Messagerie (5 onglets) ---
  static const administrateurDashboard = '/administrateur';
  static const administrateurAccueil = '/administrateur/accueil';
  static const administrateurUtilisateurs = '/administrateur/utilisateurs';
  static const administrateurPaiements = '/administrateur/paiements';
  static const administrateurStatistiques = '/administrateur/statistiques';
  static const administrateurMessagerie = '/administrateur/messagerie';
  static const administrateurProfil = '/administrateur/profil';
  static const administrateurNouvelUtilisateur = '/administrateur/utilisateurs/nouveau';
  static const administrateurUtilisateurDetailPattern = '/administrateur/utilisateurs/:id';
  static String administrateurUtilisateurDetail(String id) => '/administrateur/utilisateurs/$id';
}
