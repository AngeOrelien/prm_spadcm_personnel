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

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
