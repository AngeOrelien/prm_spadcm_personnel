import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/entities/personnel.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/personnel_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._remoteDataSource, this._storage);

  @override
  Future<void> demanderCodeConnexion({
    required String email,
    required String motDePasse,
  }) {
    return _remoteDataSource.demanderOtp(
      email: email.trim().toLowerCase(),
      motDePasse: motDePasse,
    );
  }

  @override
  Future<Personnel> verifierCodeConnexion({
    required String email,
    required String code,
  }) async {
    final data = await _remoteDataSource.verifierOtp(
      email: email.trim().toLowerCase(),
      code: code.trim(),
    );

    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    return PersonnelModel.fromJson(data['utilisateur'] as Map<String, dynamic>);
  }

  @override
  Future<Personnel?> restaurerSession() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) return null;

    try {
      return await _remoteDataSource.obtenirProfil();
    } catch (_) {
      // token invalide/expiré et non rafraîchissable -> pas de session
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<void> deconnecter() => _storage.clear();
}
