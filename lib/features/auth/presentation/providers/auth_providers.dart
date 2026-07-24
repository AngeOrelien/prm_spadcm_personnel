import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/personnel.dart';
import '../../domain/repositories/auth_repository.dart';

// --- Injection de dépendances (chaque provider ne connaît que la couche du dessous) ---

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageServiceProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

// --- État de session (qui est connecté ?) ---
//
// AsyncValue<Personnel?> :
//  - loading  -> restauration de session en cours (écran splash)
//  - data(null)      -> personne connectée -> écran login
//  - data(Personnel) -> connecté -> écran d'accueil
//  - error    -> restauration impossible, traité comme non-connecté

class AuthController extends AsyncNotifier<Personnel?> {
  @override
  Future<Personnel?> build() {
    return ref.read(authRepositoryProvider).restaurerSession();
  }

  void connecte(Personnel personnel) {
    state = AsyncData(personnel);
  }

  Future<void> deconnecter() async {
    await ref.read(authRepositoryProvider).deconnecter();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Personnel?>(
  AuthController.new,
);

// --- État du flux de connexion en 2 étapes (email -> code OTP) ---

enum OtpLoginStep { saisieEmail, saisieCode }

class OtpLoginState {
  final OtpLoginStep step;
  final String email;
  final String motDePasse;
  final bool isLoading;
  final String? errorMessage;

  const OtpLoginState({
    this.step = OtpLoginStep.saisieEmail,
    this.email = '',
    this.motDePasse = '',
    this.isLoading = false,
    this.errorMessage,
  });

  OtpLoginState copyWith({
    OtpLoginStep? step,
    String? email,
    String? motDePasse,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OtpLoginState(
      step: step ?? this.step,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OtpLoginController extends StateNotifier<OtpLoginState> {
  final AuthRepository _authRepository;
  final AuthController _authController;

  OtpLoginController(this._authRepository, this._authController)
      : super(const OtpLoginState());

  // ==========================================================================
  // ⚠️ OTP désactivé temporairement — on réactivera plus tard.
  //
  // `demanderCode`/`renvoyerCode`/`verifierCode` (flux à 2 étapes : mot de
  // passe puis code OTP) sont conservées ci-dessous en commentaire. Pour
  // réactiver : décommenter ces 3 méthodes, décommenter les méthodes
  // correspondantes dans `AuthRepository`/`AuthRepositoryImpl`, puis dans
  // `login_email_page.dart` faire à nouveau naviguer `_soumettre` vers
  // `AppRoutes.otp` (au lieu d'appeler `connecter` ci-dessous directement).
  // ==========================================================================

  // /// Étape 1 : vérifie email + mot de passe côté serveur, puis déclenche
  // /// l'envoi du code OTP par email si les identifiants sont valides.
  // Future<bool> demanderCode({
  //   required String email,
  //   required String motDePasse,
  // }) async {
  //   state = state.copyWith(isLoading: true, clearError: true);
  //   try {
  //     await _authRepository.demanderCodeConnexion(
  //       email: email,
  //       motDePasse: motDePasse,
  //     );
  //     state = state.copyWith(
  //       isLoading: false,
  //       email: email,
  //       motDePasse: motDePasse,
  //       step: OtpLoginStep.saisieCode,
  //     );
  //     return true;
  //   } on AppException catch (e) {
  //     state = state.copyWith(isLoading: false, errorMessage: e.message);
  //     return false;
  //   }
  // }

  // /// Renvoie un nouveau code OTP en réutilisant l'email + mot de passe déjà
  // /// validés à l'étape 1 (évite de redemander le mot de passe uniquement
  // /// pour un renvoi de code).
  // Future<bool> renvoyerCode() {
  //   return demanderCode(email: state.email, motDePasse: state.motDePasse);
  // }

  // Future<bool> verifierCode(String code) async {
  //   state = state.copyWith(isLoading: true, clearError: true);
  //   try {
  //     final personnel = await _authRepository.verifierCodeConnexion(
  //       email: state.email,
  //       code: code,
  //     );
  //     _authController.connecte(personnel);
  //     state = state.copyWith(isLoading: false);
  //     return true;
  //   } on AppException catch (e) {
  //     state = state.copyWith(isLoading: false, errorMessage: e.message);
  //     return false;
  //   }
  // }

  /// Connexion temporaire SANS étape OTP : vérifie email + mot de passe et
  /// connecte directement (voir `AuthRepository.connecterSansOtp`).
  Future<bool> connecter({
    required String email,
    required String motDePasse,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, email: email, motDePasse: motDePasse);
    try {
      final personnel = await _authRepository.connecterSansOtp(
        email: email,
        motDePasse: motDePasse,
      );
      _authController.connecte(personnel);
      state = state.copyWith(isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    }
  }

  /// Retour à la saisie de l'email (ex: mauvaise adresse tapée).
  void reinitialiser() {
    state = const OtpLoginState();
  }
}

final otpLoginControllerProvider =
    StateNotifierProvider.autoDispose<OtpLoginController, OtpLoginState>((ref) {
  return OtpLoginController(
    ref.read(authRepositoryProvider),
    ref.read(authControllerProvider.notifier),
  );
});
