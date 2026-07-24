import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../models/personnel_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  // ==========================================================================
  // ⚠️ OTP désactivé temporairement — on réactivera plus tard.
  //
  // Le flux à 2 facteurs (email + mot de passe, puis code OTP par email)
  // reste implémenté ci-dessous en commentaire pour être réactivé sans tout
  // réécrire. Pour réactiver :
  //   1. Décommenter `demanderOtp` et `verifierOtp` ci-dessous.
  //   2. Dans `auth_repository.dart`/`auth_repository_impl.dart`, décommenter
  //      `demanderCodeConnexion`/`verifierCodeConnexion`.
  //   3. Dans `auth_providers.dart`, décommenter les méthodes OTP de
  //      `OtpLoginController` et restaurer leur usage.
  //   4. Dans `login_email_page.dart`, faire à nouveau naviguer `_soumettre`
  //      vers `AppRoutes.otp` au lieu de connecter directement.
  // ==========================================================================

  // /// Étape 1 du login : le backend vérifie d'abord l'email + mot de passe,
  // /// et n'envoie le code OTP par email que si la paire est correcte.
  // Future<void> demanderOtp({required String email, required String motDePasse}) async {
  //   try {
  //     await _apiClient.dio.post(
  //       ApiConstants.requestOtp,
  //       data: {'email': email, 'motDePasse': motDePasse},
  //     );
  //   } on DioException catch (e) {
  //     throw ApiClient.toAppException(e);
  //   }
  // }

  // Future<Map<String, dynamic>> verifierOtp({
  //   required String email,
  //   required String code,
  // }) async {
  //   try {
  //     final response = await _apiClient.dio.post(
  //       ApiConstants.verifyLoginOtp,
  //       data: {'email': email, 'code': code},
  //     );
  //     return response.data as Map<String, dynamic>;
  //   } on DioException catch (e) {
  //     throw ApiClient.toAppException(e);
  //   }
  // }

  /// Connexion temporaire SANS étape OTP (email + mot de passe uniquement),
  /// le temps que la vérification par email soit réactivée. Appelle la route
  /// de test du backend `POST /api/auth/test/login`, elle-même montée
  /// uniquement si `NODE_ENV !== 'production'` côté serveur.
  Future<Map<String, dynamic>> connecterSansOtp({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.testLogin,
        data: {'email': email, 'motDePasse': motDePasse},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<PersonnelModel> obtenirProfil() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      return PersonnelModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
