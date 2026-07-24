/// Interrupteur central : tant que `prm-spad-backend` n'expose pas encore
/// tous les endpoints consommés par cette app (seul `auth` est en place côté
/// serveur au moment de l'écriture), chaque `RemoteDataSource` peut servir
/// des données quasi-statiques en mémoire (voir `core/mock/mock_store.dart`)
/// au lieu d'appeler le backend réel via Dio.
///
/// Objectif : permettre de faire tourner et présenter l'app (démonstration,
/// tests utilisateurs, captures d'écran) sans dépendre de l'avancement du
/// backend, tout en gardant le vrai code d'appel API intact et prêt à
/// reprendre la main dès qu'un endpoint est disponible.
///
/// Bascule sans toucher au code :
///   flutter run --dart-define=USE_MOCK_DATA=false
///
/// Important : l'authentification (`auth_remote_datasource.dart`) n'est PAS
/// concernée par ce flag — elle appelle toujours le vrai backend, puisque
/// c'est la partie déjà développée et testée (OTP email, JWT).
class AppConfig {
  AppConfig._();

  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// Latence artificielle pour que les écrans de chargement, pull-to-refresh
  /// et indicateurs restent visibles/testables même en mode maquette.
  static const Duration mockLatency = Duration(milliseconds: 450);
}
