import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/mock/mock_store.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../models/coordonnateur_models.dart';

/// Toutes les requêtes du feature Coordonnateur vers `prm-spad-backend`.
/// Même pattern que `AuthRemoteDataSource` : réutilise l'[ApiClient] unique
/// (token + refresh automatiques déjà gérés), convertit chaque erreur Dio en
/// [AppException] lisible.
///
/// Tant que `AppConfig.useMockData` est actif, chaque méthode sert des
/// données quasi-statiques depuis [MockStore] au lieu d'appeler le backend
/// (voir `core/config/app_config.dart`).
class CoordonnateurRemoteDataSource {
  final ApiClient _apiClient;

  CoordonnateurRemoteDataSource(this._apiClient);

  // --- Patients ---

  Future<List<Patient>> listerPatients({String? search}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.patients(search: search);
    }
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.patients,
        queryParameters: {if (search != null && search.isNotEmpty) 'search': search, 'limit': 100},
      );
      final data = response.data['patients'] as List;
      return data.map((json) => PatientModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Patient> obtenirPatient(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.patient(id);
    }
    try {
      final response = await _apiClient.dio.get('${ApiConstants.patients}/$id');
      final json = Map<String, dynamic>.from(response.data['patient'] as Map);
      if (response.data['avsAssigne'] != null) {
        json['avsAssigne'] = response.data['avsAssigne'];
      }
      return PatientModel.fromJson(json);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Patient> creerPatient(Map<String, dynamic> corps) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.ajouterPatient(corps);
    }
    try {
      final response = await _apiClient.dio.post(ApiConstants.patients, data: corps);
      return PatientModel.fromJson(response.data['patient'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Équipe AVS ---

  Future<List<Avs>> listerEquipeAvs() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.equipeAvs();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.avsEquipe);
      final data = response.data['equipe'] as List;
      return data.map((json) => AvsModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Affectations ---

  Future<List<Affectation>> listerAffectations({String? patientId, String? avsId, String? statut}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.affectationsFiltrees(patientId: patientId, avsId: avsId);
    }
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.assignations,
        queryParameters: {
          if (patientId != null) 'patientId': patientId,
          if (avsId != null) 'avsId': avsId,
          if (statut != null) 'statut': statut,
        },
      );
      final data = response.data['assignations'] as List;
      return data.map((json) => AffectationModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Affectation> creerAffectation({
    required String patientId,
    required String avsId,
    required String frequence,
    required DateTime dateDebut,
    String? notes,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.creerAffectation(patientId: patientId, avsId: avsId, frequence: frequence, dateDebut: dateDebut, notes: notes);
    }
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.assignations,
        data: {
          'patientId': patientId,
          'avsId': avsId,
          'frequence': frequence,
          'dateDebut': dateDebut.toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return AffectationModel.fromJson(response.data['assignation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> terminerAffectation(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      MockStore.terminerAffectation(id);
      return;
    }
    try {
      await _apiClient.dio.patch('${ApiConstants.assignations}/$id/terminer');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Rapports ---

  Future<List<RapportAvs>> listerRapports({String? patientId, String? avsId}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.tousLesRapports(patientId: patientId, avsId: avsId);
    }
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.rapports,
        queryParameters: {
          if (patientId != null) 'patientId': patientId,
          if (avsId != null) 'avsId': avsId,
        },
      );
      final data = response.data['rapports'] as List;
      return data.map((json) => RapportModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<RapportAvs>> listerRapportsEnAttente() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockStore.rapportsEnAttente();
    }
    try {
      final response = await _apiClient.dio.get(ApiConstants.rapportsEnAttente);
      final data = response.data['rapports'] as List;
      return data.map((json) => RapportModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> validerRapport(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      MockStore.validerRapport(id);
      return;
    }
    try {
      await _apiClient.dio.patch('${ApiConstants.rapports}/$id/valider');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> rejeterRapport(String id, {String? motif}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      MockStore.rejeterRapport(id, motif: motif);
      return;
    }
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.rapports}/$id/rejeter',
        data: {if (motif != null && motif.isNotEmpty) 'motifRejet': motif},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
