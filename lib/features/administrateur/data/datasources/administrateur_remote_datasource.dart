import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../models/administrateur_models.dart';

/// Toutes les requêtes du feature Administrateur vers `prm-spad-backend`.
class AdministrateurRemoteDataSource {
  final ApiClient _apiClient;

  AdministrateurRemoteDataSource(this._apiClient);

  // --- Utilisateurs (tous rôles) ---

  Future<List<Utilisateur>> listerUtilisateurs({String? role, String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.utilisateurs,
        queryParameters: {if (role != null) 'role': role, if (search != null && search.isNotEmpty) 'search': search},
      );
      final data = response.data['utilisateurs'] as List;
      return data.map((json) => UtilisateurModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Utilisateur> creerUtilisateur(Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.utilisateurs, data: corps);
      return UtilisateurModel.fromJson(response.data['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> basculerActivation(String id, bool actif) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.utilisateurs}/$id', data: {'actif': actif});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Paiements ---

  Future<List<Paiement>> listerPaiements() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.paiements);
      final data = response.data['paiements'] as List;
      return data.map((json) => PaiementModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Statistiques ---

  Future<StatistiquesGlobales> obtenirStatistiques() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.statistiques);
      return StatistiquesGlobalesModel.fromJson(response.data['statistiques'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<String> exporterStatistiquesPdf() async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.statistiquesExportPdf);
      return response.data['url']?.toString() ?? '';
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
