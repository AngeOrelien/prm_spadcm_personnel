import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Retient si l'écran d'accueil (onboarding, 3 pages) a déjà été vu, pour ne
/// l'afficher qu'une seule fois au tout premier lancement de l'app — sur le
/// même modèle que `SecureStorageService`/`RapportsLocauxService` (un seul
/// point de vérité par responsabilité, construit sur `flutter_secure_storage`,
/// déjà une dépendance de l'app).
class OnboardingService {
  final FlutterSecureStorage _storage;
  static const _cle = 'onboarding_termine';

  OnboardingService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> aDejaVuOnboarding() async {
    final valeur = await _storage.read(key: _cle);
    return valeur == 'true';
  }

  Future<void> marquerCommeVu() async {
    await _storage.write(key: _cle, value: 'true');
  }
}
