import '../entities/personnel.dart';

abstract class AuthRepository {
  /// Étape 1 du login : demande l'envoi d'un code OTP à l'email donné.
  Future<void> demanderCodeConnexion(String email);

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
