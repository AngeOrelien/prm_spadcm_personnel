/// Exception applicative unique utilisée dans toutes les couches data/domain.
///
/// On reste volontairement simple pour démarrer : un seul type d'exception
/// avec un message lisible (déjà traduit en français par le backend la
/// plupart du temps) et un code HTTP optionnel pour les cas où l'UI doit
/// réagir différemment (ex: 401 -> déconnexion forcée).
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}
