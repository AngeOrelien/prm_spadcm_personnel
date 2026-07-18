import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import 'secure_storage_service.dart';

/// Un seul Dio pour toute l'app :
/// - attache automatiquement l'access token sur chaque requête
/// - tente un refresh-token automatique sur un 401, puis rejoue la requête
/// - convertit toute erreur Dio en [AppException] avec le message du backend
class ApiClient {
  final Dio dio;
  final SecureStorageService _storage;

  ApiClient(this._storage)
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null && !options.path.contains('/auth/request-otp') &&
              !options.path.contains('/auth/verify-login-otp')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path.contains('/auth/refresh-token');

          if (isUnauthorized && !isRefreshCall) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null) {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $refreshed';
              try {
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (_) {
                // le retry a échoué, on laisse tomber sur l'erreur d'origine
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _tryRefreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final newAccessToken = response.data['accessToken'] as String?;
      if (newAccessToken != null) {
        await _storage.saveAccessToken(newAccessToken);
        return newAccessToken;
      }
    } catch (_) {
      // le refresh token est probablement expiré -> l'utilisateur devra se reconnecter
      await _storage.clear();
    }
    return null;
  }

  /// Convertit une [DioException] en [AppException] avec le message renvoyé
  /// par le backend (`{ success: false, message: "..." }`), sinon un message
  /// générique.
  static AppException toAppException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    String message = 'Une erreur est survenue, réessayez.';

    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Le serveur met trop de temps à répondre.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Impossible de joindre le serveur. Vérifie ta connexion.';
    }

    return AppException(message, statusCode: statusCode);
  }
}
