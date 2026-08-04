import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../domain/entities/ia_entities.dart';
import '../models/ia_models.dart';

/// Toutes les requêtes du feature IA vers `prm_spadcm_backend`, qui relaie
/// lui-même vers le service séparé `prm-spadcm-ia` (voir
/// `assistantController.js` et `iaController.js`). L'app n'appelle JAMAIS
/// le service IA directement — toujours via ce backend, seul détenteur du
/// jeton de service interne.
///
/// Les réponses IA (LLM, agrégations) peuvent prendre plus de temps qu'un
/// CRUD classique : chaque appel ici étend le `receiveTimeout` par défaut
/// de l'[ApiClient] plutôt que de le changer globalement pour toute l'app.
class IaRemoteDataSource {
  final ApiClient _apiClient;

  IaRemoteDataSource(this._apiClient);

  static const _delaiReponseIa = Duration(seconds: 45);

  /// Envoie un message à l'assistant IA. `historique` : échanges précédents
  /// de la conversation en cours (le service IA est sans état, l'app doit
  /// le renvoyer à chaque appel). `patientId` optionnel : à fournir si
  /// l'utilisateur consulte le dossier d'un patient précis, pour enrichir
  /// la réponse avec ses données (RAG côté service IA).
  Future<ReponseChatIa> envoyerMessage({
    required String message,
    List<MessageChatIa> historique = const [],
    String? patientId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.assistantChat,
        data: {
          'message': message,
          'historique': historique
              .map((m) => {
                    'role': m.role == RoleMessageChat.utilisateur ? 'user' : 'assistant',
                    'contenu': m.contenu,
                  })
              .toList(),
          if (patientId != null) 'patientId': patientId,
        },
        options: Options(receiveTimeout: _delaiReponseIa, sendTimeout: _delaiReponseIa),
      );
      return ReponseChatIaModel.fromJson({'reponse': response.data['reponse']});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<ResumeRapports> resumeRapports({
    required String patientId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.iaResumeRapports,
        data: {
          'patientId': patientId,
          if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String().split('T').first,
          if (dateFin != null) 'dateFin': dateFin.toIso8601String().split('T').first,
        },
        options: Options(receiveTimeout: _delaiReponseIa, sendTimeout: _delaiReponseIa),
      );
      return ResumeRapportsModel.fromJson(response.data['donnees'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<EvolutionSante> evolutionSante({required String patientId, int jours = 30}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.iaEvolutionSante,
        data: {'patientId': patientId, 'jours': jours},
      );
      return EvolutionSanteModel.fromJson(response.data['donnees'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Sans `avsId` : classement de tous les AVS (coordonnateur/administrateur
  /// uniquement — un AVS qui appelle cet endpoint reçoit toujours son
  /// propre score, `avsId` est ignoré et forcé côté serveur, voir
  /// `iaController.js`).
  Future<PerformanceAvs> performanceAvs({String? avsId, int jours = 30}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.iaPerformanceAvs,
        data: {if (avsId != null) 'avsId': avsId, 'jours': jours},
      );
      return PerformanceAvsModel.fromJson(response.data['donnees'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<List<ResultatRechercheSemantique>> rechercheSemantique({
    required String requete,
    String? patientId,
    int topK = 5,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.iaRechercheSemantique,
        data: {'requete': requete, if (patientId != null) 'patientId': patientId, 'topK': topK},
      );
      final donnees = response.data['donnees'] as Map<String, dynamic>;
      return (donnees['resultats'] as List? ?? [])
          .map((e) => ResultatRechercheSemantiqueModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<AlertesIntelligentes> alertesIntelligentes({required String patientId}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.iaAlertesIntelligentes,
        data: {'patientId': patientId},
      );
      return AlertesIntelligentesModel.fromJson(response.data['donnees'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
