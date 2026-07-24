import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/medecin_entities.dart';
import '../models/medecin_models.dart';

/// Toutes les requêtes du feature Médecin vers `prm-spad-backend`.
///
/// ⚠️ Le rôle Médecin reste "à l'étude" côté backend (README §11, phase 8) :
/// ces endpoints (`/patients?medecin=moi`, `/traitements`) peuvent ne pas
/// encore exister sur le serveur — les appels échoueront proprement via
/// [AppException] tant qu'ils ne sont pas implémentés.
class MedecinRemoteDataSource {
  final ApiClient _apiClient;

  MedecinRemoteDataSource(this._apiClient);

  Future<List<DossierMedicalPatient>> listerMesPatients() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.patients, queryParameters: {'medecin': 'moi'});
      final data = response.data['patients'] as List;
      return data.map((json) => DossierMedicalPatientModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<Traitement>> listerTraitements() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.traitements);
      final data = response.data['traitements'] as List;
      return data.map((json) => TraitementModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Traitement> prescrire(Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.traitements, data: corps);
      return TraitementModel.fromJson(response.data['traitement'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
