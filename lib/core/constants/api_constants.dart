import '../config/env_config.dart';

/// Configuration de l'accès au backend Node/Express (prm-spad-backend).
///
/// L'URL de base est désormais pilotée par `EnvConfig` (voir
/// `core/config/env_config.dart`), lui-même lu depuis le fichier `.env` à la
/// racine du projet. Pour basculer entre le backend local et celui déployé
/// sur Vercel, modifie la ligne `APP_ENV` dans `.env` — rien à changer ici.
///
/// - Émulateur Android + backend local -> `adb reverse tcp:4000 tcp:4000`,
///   puis `API_BASE_URL_LOCAL=http://localhost:4000/api` dans `.env`.
/// - Appareil physique sur le même Wi-Fi que la machine -> remplace
///   temporairement par l'IP locale, ou utilise la surcharge
///   `--dart-define=API_BASE_URL=http://192.168.1.50:4000/api`.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => EnvConfig.apiBaseUrl;

  // --- Auth : compte personnel provisionné par un admin, connexion OTP email ---
  //
  // ⚠️ Vérification OTP temporairement désactivée côté app (voir
  // `auth_remote_datasource.dart`, `auth_repository.dart` et
  // `auth_providers.dart` — blocs commentés "OTP désactivé temporairement").
  // Les constantes ci-dessous restent définies pour ne rien casser à la
  // réactivation ; `testLogin` est utilisé en attendant (routes de test du
  // backend, montées uniquement si NODE_ENV !== 'production').
  static const String requestOtp = '/auth/request-otp';
  static const String verifyLoginOtp = '/auth/verify-login-otp';

  /// Connexion sans étape OTP (email + mot de passe), le temps que la
  /// vérification par email soit réactivée côté app. Correspond à la route
  /// `POST /api/auth/test/login` du backend.
  static const String testLogin = '/auth/test/login';

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
