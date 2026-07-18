import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../models/personnel_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<void> demanderOtp(String email) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.requestOtp,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Map<String, dynamic>> verifierOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.verifyLoginOtp,
        data: {'email': email, 'code': code},
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
