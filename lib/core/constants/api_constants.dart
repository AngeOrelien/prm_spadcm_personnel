/// Configuration de l'accès au backend Node/Express (prm-spad-backend).
///
/// En développement, le backend tourne en local sur le port 4000.
/// - Émulateur Android  -> 10.0.2.2 (alias de "localhost" de la machine hôte)
/// - Simulateur iOS     -> localhost fonctionne directement
/// - Appareil physique  -> remplace par l'IP locale de ta machine (ex: 192.168.1.x)
///
/// Surcharge possible au lancement sans toucher au code :
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  // --- Auth : compte personnel provisionné par un admin, connexion 100% OTP email ---
  static const String requestOtp = '/auth/request-otp';
  static const String verifyLoginOtp = '/auth/verify-login-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';

  // --- Coordonnateur : patients, équipe AVS, affectations, rapports ---
  static const String patients = '/patients';
  static const String avsEquipe = '/utilisateurs/avs/equipe';
  static const String assignations = '/assignations';
  static const String rapports = '/rapports';
  static const String rapportsEnAttente = '/rapports/en-attente';

  // --- AVS : planning, rapports journaliers, présence ---
  static const String planningAvs = '/assignations/mon-planning';
  static const String rapportsAvs = '/rapports/mes-rapports';
  static const String presences = '/presences';
  static const String presenceCheckIn = '/presences/check-in';
  static const String presenceCheckOut = '/presences/check-out';

  // --- Administrateur : utilisateurs, paiements, statistiques ---
  static const String utilisateurs = '/utilisateurs';
  static const String paiements = '/paiements';
  static const String souscriptions = '/souscriptions';
  static const String statistiques = '/statistiques';
  static const String statistiquesExportPdf = '/statistiques/export-pdf';

  // --- Médecin (rôle en étude) : dossiers, traitements, rendez-vous ---
  static const String traitements = '/traitements';
  static const String rendezvous = '/rendezvous';

  // --- Messagerie (branchement prévu plus tard) ---
  static const String conversations = '/conversations';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
