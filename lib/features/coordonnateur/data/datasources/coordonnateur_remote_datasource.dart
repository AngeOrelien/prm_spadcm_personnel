import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../models/coordonnateur_models.dart';

/// Toutes les requêtes du feature Coordonnateur vers `prm-spad-backend`.
/// Même pattern que `AuthRemoteDataSource` : réutilise l'[ApiClient] unique
/// (token + refresh automatiques déjà gérés), convertit chaque erreur Dio en
/// [AppException] lisible.
class CoordonnateurRemoteDataSource {
  final ApiClient _apiClient;

  CoordonnateurRemoteDataSource(this._apiClient);

  // --- Patients ---

  Future<List<Patient>> listerPatients({String? search}) async {
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
    try {
      final response = await _apiClient.dio.post(ApiConstants.patients, data: corps);
      return PatientModel.fromJson(response.data['patient'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Équipe AVS ---

  Future<List<Avs>> listerEquipeAvs() async {
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
    try {
      await _apiClient.dio.patch('${ApiConstants.assignations}/$id/terminer');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Rapports ---

  Future<List<RapportAvs>> listerRapports({String? patientId, String? avsId}) async {
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
    try {
      final response = await _apiClient.dio.get(ApiConstants.rapportsEnAttente);
      final data = response.data['rapports'] as List;
      return data.map((json) => RapportModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> validerRapport(String id) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.rapports}/$id/valider');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> rejeterRapport(String id, {String? motif}) async {
    try {
      await _apiClient.dio.patch(
        '${ApiConstants.rapports}/$id/rejeter',
        data: {if (motif != null && motif.isNotEmpty) 'motifRejet': motif},
      );
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Messagerie (`/api/conversations`) ---

  Future<List<Conversation>> listerConversations(String currentUserId) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.conversations);
      final data = response.data['conversations'] as List;
      return data
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>, currentUserId))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Crée une conversation privée avec [participantId], ou récupère celle
  /// qui existe déjà (le backend est idempotent pour les conversations
  /// privées à 2 participants — voir `creerConversation`).
  Future<Conversation> creerOuObtenirConversation(String participantId, String currentUserId, {String? patientContexteId}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.conversations,
        data: {
          'participantsIds': [participantId],
          'type': 'privee',
          if (patientContexteId != null) 'patientContexteId': patientContexteId,
        },
      );
      return ConversationModel.fromJson(response.data['conversation'] as Map<String, dynamic>, currentUserId);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<MessageConversation>> listerMessages(String conversationId, String currentUserId, {DateTime? avant}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.conversations}/$conversationId/messages',
        queryParameters: {if (avant != null) 'avant': avant.toIso8601String()},
      );
      final data = response.data['messages'] as List;
      return data
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>, currentUserId))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<MessageConversation> envoyerMessage(String conversationId, String contenu, String currentUserId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.conversations}/$conversationId/messages',
        data: {'contenu': contenu},
      );
      return MessageModel.fromJson(response.data['message'] as Map<String, dynamic>, currentUserId);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> marquerConversationLue(String conversationId) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.conversations}/$conversationId/marquer-lu');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Présences / check-in (`/api/presences`) ---

  Future<List<PresenceAvs>> listerPresences({String? avsId, DateTime? date, String? statut}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.presences,
        queryParameters: {
          if (avsId != null) 'avsId': avsId,
          if (date != null) 'date': date.toIso8601String(),
          if (statut != null) 'statut': statut,
        },
      );
      final data = response.data['presences'] as List;
      return data.map((json) => PresenceCoordonnateurModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Vue temps réel du jour : qui est présent / en retard / absent.
  Future<List<PresenceAvs>> vueEnsembleDuJour() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.presences}/aujourdhui/vue-ensemble');
      final data = response.data['vue'] as List;
      final aujourdhui = DateTime.now();
      return data
          .map((json) => PresenceCoordonnateurModel.fromVueEnsembleJson(json as Map<String, dynamic>, aujourdhui))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Statistiques (`/api/stats/operationnel`) ---

  Future<Map<String, dynamic>> statistiquesOperationnelles() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.statistiquesOperationnelles);
      return Map<String, dynamic>.from(response.data['stats'] as Map);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
