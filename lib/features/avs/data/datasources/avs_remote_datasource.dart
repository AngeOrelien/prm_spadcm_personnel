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
/// L'AVS est identifié via son JWT sur toutes les routes qui s'auto-filtrent
/// côté serveur (`/rapports`, `/presences`). Les routes qui ne s'auto-
/// filtrent PAS (`/assignations`, `/patients`... — voir commentaires
/// ci-dessous) reçoivent explicitement `avsId`/`currentUserId` en paramètre.
class AvsRemoteDataSource {
  final ApiClient _apiClient;

  AvsRemoteDataSource(this._apiClient);

  // --- Mon (mes) patient(s) ---
  //
  // `GET /patients` s'auto-filtre déjà sur l'AVS connecté côté backend
  // (voir `patientController.listerPatients` : pour un AVS, restreint aux
  // patients de ses affectations actives) — pas besoin de filtre côté app.

  Future<List<Patient>> mesPatients() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.patients);
      final data = response.data['patients'] as List;
      return data.map((json) => PatientModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Affectations actives de l'AVS connecté (donne la fréquence de visite et
  /// la date de début par patient). `/assignations` ne s'auto-filtre PAS
  /// côté serveur (contrairement à `/patients` et `/rapports`) : `avsId`
  /// doit être passé explicitement.
  Future<List<Affectation>> mesAffectationsActives(String avsId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.assignations,
        queryParameters: {'avsId': avsId, 'statut': 'active'},
      );
      final data = response.data['assignations'] as List;
      return data.map((json) => AffectationModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Rapports journaliers ---

  Future<List<RapportAvs>> mesRapports({String? patientId}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.rapports,
        queryParameters: {if (patientId != null) 'patientId': patientId},
      );
      final data = response.data['rapports'] as List;
      return data.map((json) => RapportModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<RapportAvs> creerRapport(Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.rapports, data: corps);
      return RapportModel.fromJson(response.data['rapport'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Présence / check-in ---

  /// Présence du jour de l'AVS connecté — `GET /presences/moi/aujourdhui`.
  ///
  /// ⚠️ Correctif : appelait auparavant `GET /presences?jour=aujourdhui`, un
  /// paramètre que le backend ignore totalement (voir
  /// `presenceController.listerPresences`, qui ne connaît que
  /// `avsId`/`statut`/`date`) — l'appel renvoyait donc TOUT l'historique de
  /// présences sous la clé `presences` (liste), jamais la clé singulière
  /// `presence` lue par l'app, et le check-in du jour semblait donc toujours
  /// manquant même une fois fait.
  Future<Presence?> presenceDuJour() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.presenceMoiAujourdhui);
      final data = response.data['presence'];
      if (data == null) return null;
      return PresenceModel.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Historique des présences de l'AVS connecté (`GET /presences`,
  /// auto-filtré côté serveur). Alimente le récapitulatif de l'onglet
  /// Check-in et le calcul des statistiques personnelles de ponctualité.
  Future<List<Presence>> mesPresences() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.presences);
      final data = response.data['presences'] as List;
      return data.map((json) => PresenceModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Presence> checkIn({required double latitude, required double longitude}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.presenceCheckIn,
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return PresenceModel.fromJson(response.data['presence'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Presence> checkOut() async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.presenceCheckOut);
      return PresenceModel.fromJson(response.data['presence'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Messagerie (`/api/conversations`) — même branchement que le
  // coordonnateur, voir `CoordonnateurRemoteDataSource`. ---

  Future<List<Conversation>> listerConversations(String currentUserId) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.conversations);
      final data = response.data['conversations'] as List;
      return data.map((json) => ConversationModel.fromJson(json as Map<String, dynamic>, currentUserId)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

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
      return data.map((json) => MessageModel.fromJson(json as Map<String, dynamic>, currentUserId)).toList();
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

  // --- Annuaire collègues (coordonnateurs / médecins / administrateurs)
  // pour la messagerie AVS : `GET /utilisateurs/role/:role` est désormais
  // ouvert au rôle AVS côté backend, mais restreint aux 3 rôles ci-dessus
  // (voir `utilisateurController.listerUtilisateursParRole`) — l'AVS
  // communique par ailleurs avec le(s) patient(s) qui lui sont affectés via
  // `mesPatients()` ci-dessus, un endpoint distinct et déjà auto-filtré.
  Future<List<PersonnelAnnuaire>> listerPersonnelParRole(String role) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.utilisateursParRole(role));
      final data = (response.data['utilisateurs'] ?? response.data['data'] ?? const []) as List;
      return data.map((json) => PersonnelAnnuaireModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
