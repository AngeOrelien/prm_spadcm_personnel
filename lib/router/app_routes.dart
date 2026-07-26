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

  // --- AVS : Accueil / Mon patient / Check-in / Messages (4 onglets) ---
  //
  // "Planning" a été remplacé par "Accueil" (l'ancien onglet pointait vers
  // `/assignations/mon-planning`, une route qui n'existe pas côté backend —
  // voir `BACKEND-TODO.md`) et "Rapports" par "Mon patient" (l'historique
  // de rapports reste accessible en page poussée, voir `avsRapports`
  // ci-dessous, désormais un simple push et non plus un onglet).
  static const avsDashboard = '/avs';
  static const avsAccueil = '/avs/accueil';
  static const avsPatient = '/avs/patient';
  static const avsCheckin = '/avs/checkin';
  static const avsMessages = '/avs/messages';
  static const avsProfil = '/avs/profil';
  static const avsNouveauRapport = '/avs/rapports/nouveau';
  static const avsRapports = '/avs/rapports';
  static const avsPatientDetailPattern = '/avs/patient/:id';
  static String avsPatientDetail(String id) => '/avs/patient/$id';
  static const avsMessagerieConversationPattern = '/avs/messages/:id';
  static String avsMessagerieConversation(String id) => '/avs/messages/$id';

  // --- Médecin (rôle en étude) : Patients / Prescriptions / Messagerie (3 onglets) ---
  static const medecinDashboard = '/medecin';
  static const medecinPatients = '/medecin/patients';
  static const medecinPrescriptions = '/medecin/prescriptions';
  static const medecinMessagerie = '/medecin/messagerie';
  static const medecinProfil = '/medecin/profil';
  static const medecinPatientDetailPattern = '/medecin/patients/:id';
  static String medecinPatientDetail(String id) => '/medecin/patients/$id';
  // Pages plein écran (context.push, donc sans bottom navigation) :
  // formulaire de prescription et fils de messagerie par patient.
  static const medecinNouvellePrescription = '/medecin/prescriptions/nouvelle';
  static const medecinMessagerieConversationPattern = '/medecin/messagerie/:id';
  static String medecinMessagerieConversation(String id) => '/medecin/messagerie/$id';

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

  // Détail plein écran d'un rapport AVS (au lieu du bottom sheet précédent)
  // et d'une présence/check-in — voir `coordonnateur_rapports_page.dart` /
  // `coordonnateur_checkins_page.dart`.
  static const coordonnateurRapportDetailPattern = '/coordonnateur/rapports/:id';
  static String coordonnateurRapportDetail(String id) => '/coordonnateur/rapports/$id';
  static const coordonnateurCheckinDetailPattern = '/coordonnateur/checkins/:id';
  static String coordonnateurCheckinDetail(String id) => '/coordonnateur/checkins/$id';

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
  // Fil de messagerie "Administration" (context.push, sans bottom navigation).
  static const administrateurMessagerieAdministrationPattern = '/administrateur/messagerie/administration';
}
