import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../../avs/data/models/avs_models.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../../coordonnateur/data/models/coordonnateur_models.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
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

  // --- Messagerie (`/api/conversations`) — même branchement que les autres
  // rôles, voir `CoordonnateurRemoteDataSource`. ---

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

  // --- Annuaire (AVS / coordonnateurs / médecins / administrateurs), pour
  // démarrer une conversation depuis l'onglet Messagerie. Le médecin peut
  // contacter tout le monde (route ouverte côté backend pour son rôle — voir
  // `utilisateurRoutes.js`). ---
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
