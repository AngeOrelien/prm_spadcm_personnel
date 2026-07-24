import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/mock_store.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/medecin_entities.dart';
import '../models/medecin_models.dart';

/// Tant que `AppConfig.useMockData` est actif, chaque méthode sert des
/// données quasi-statiques depuis [MockStore] au lieu d'appeler le backend
/// (voir `core/config/app_config.dart`) — pertinent ici en particulier
/// puisque le rôle Médecin reste "à l'étude" côté backend (README §11,
/// phase 8) : aucun endpoint dédié n'existe encore.
class MedecinRemoteDataSource {
  final ApiClient _apiClient;

  MedecinRemoteDataSource(this._apiClient);

  Future<List<DossierMedicalPatient>> listerMesPatients() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.dossiersMedicaux();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.patients, queryParameters: {'medecin': 'moi'});
      final data = response.data['patients'] as List;
      return data.map((json) => DossierMedicalPatientModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Traitement>> listerTraitements() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.listerTraitements();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.traitements);
      final data = response.data['traitements'] as List;
      return data.map((json) => TraitementModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Traitement> prescrire(Map<String, dynamic> corps) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.prescrire(corps);
    }
    try {
      final response = await _apiClient.dio.post(ApiConstants.traitements, data: corps);
      return TraitementModel.fromJson(response.data['traitement'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
