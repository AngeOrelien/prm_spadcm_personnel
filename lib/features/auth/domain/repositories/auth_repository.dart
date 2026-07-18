import '../entities/personnel.dart';

abstract class AuthRepository {
  /// Étape 1 du login : vérifie l'email + mot de passe, puis demande
  /// l'envoi d'un code OTP à l'email donné (le code n'est envoyé que si les
  /// identifiants sont corrects).
  Future<void> demanderCodeConnexion({
    required String email,
    required String motDePasse,
  });

  /// Étape 2 du login : vérifie le code reçu par email, sauvegarde les
  /// tokens en stockage sécurisé et renvoie le profil connecté.
  Future<Personnel> verifierCodeConnexion({
    required String email,
    required String code,
  });

  /// Restaure une session existante à partir du token stocké (ex: au
  /// démarrage de l'app), ou renvoie null si aucune session valide.
  Future<Personnel?> restaurerSession();

  Future<void> deconnecter();
}
