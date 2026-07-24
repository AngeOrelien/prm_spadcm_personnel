import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../../coordonnateur/data/models/coordonnateur_models.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../domain/entities/avs_entities.dart';
import '../models/avs_models.dart';

/// Toutes les requêtes du feature AVS vers `prm-spad-backend`. Même pattern
/// que `CoordonnateurRemoteDataSource` : réutilise l'[ApiClient] unique,
/// convertit chaque erreur Dio en [AppException] lisible.
///
/// `avsId` reste un paramètre nommé (avec valeur par défaut) pour ne pas
/// casser les appelants, mais n'est plus utilisé dans les requêtes : le vrai
/// backend identifie l'AVS connecté via son JWT, pas via ce paramètre.
class AvsRemoteDataSource {
  final ApiClient _apiClient;

  AvsRemoteDataSource(this._apiClient);

  // --- Planning ---

  Future<List<VisitePlanifiee>> obtenirMonPlanning({String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.planningAvs);
      final data = response.data['planning'] as List;
      return data.map((json) => VisitePlanifieeModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Rapports journaliers ---

  Future<List<RapportAvs>> obtenirMesRapports({String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.rapportsAvs);
      final data = response.data['rapports'] as List;
      return data.map((json) => RapportModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<RapportAvs> creerRapport(Map<String, dynamic> corps, {String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.rapports, data: corps);
      return RapportModel.fromJson(response.data['rapport'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Présence / check-in ---

  Future<Presence?> presenceDuJour({String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.presences, queryParameters: {'jour': 'aujourdhui'});
      final data = response.data['presence'];
      if (data == null) return null;
      return PresenceModel.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Presence> checkIn({required double latitude, required double longitude, String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.presenceCheckIn,
        data: {'geolocalisation': {'latitude': latitude, 'longitude': longitude}},
      );
      return PresenceModel.fromJson(response.data['presence'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Presence> checkOut({String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.presenceCheckOut);
      return PresenceModel.fromJson(response.data['presence'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Statistiques personnelles de ponctualité ---

  Future<StatistiquesPonctualiteAvs> mesStatistiques({String avsId = 'avs-01'}) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.statistiques}/mes-stats');
      final json = response.data['statistiques'] as Map<String, dynamic>;
      return StatistiquesPonctualiteAvs(
        rapportsATemps: json['rapportsATemps'] ?? 0,
        rapportsEnRetard: json['rapportsEnRetard'] ?? 0,
        checkinsATemps: json['checkinsATemps'] ?? 0,
        checkinsEnRetard: json['checkinsEnRetard'] ?? 0,
        absences: json['absences'] ?? 0,
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
