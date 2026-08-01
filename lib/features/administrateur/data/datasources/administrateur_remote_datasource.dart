import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/services/api_client.dart';
import '../../../avs/data/models/avs_models.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../../coordonnateur/data/models/coordonnateur_models.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
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

  /// Active/désactive un compte. Correspond à `PATCH /api/utilisateurs/:id/statut`
  /// avec `{ estActif }` (voir `changerStatutCompte` côté backend — le
  /// endpoint générique `PATCH /:id` sert lui à modifier les infos du
  /// compte, pas son statut, et n'a pas de champ `actif`).
  Future<void> basculerActivation(String id, bool actif) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.utilisateurs}/$id/statut', data: {'estActif': actif});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Édite les infos d'un compte (`PATCH /api/utilisateurs/:id`) — pas le
  /// mot de passe ni le rôle, voir `UtilisateurModel.toUpdateJson`.
  Future<Utilisateur> modifierUtilisateur(String id, Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.patch('${ApiConstants.utilisateurs}/$id', data: corps);
      return UtilisateurModel.fromJson(response.data['utilisateur'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Suppression définitive d'un compte (`DELETE /api/utilisateurs/:id`) —
  /// le backend refuse déjà l'auto-suppression et la suppression du dernier
  /// admin (voir `utilisateurController.supprimerUtilisateur`), donc pas de
  /// garde supplémentaire nécessaire côté app au-delà de la confirmation.
  Future<void> supprimerUtilisateur(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.utilisateurs}/$id');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Catalogue de soins SPAD (soins_catalogue) ---

  Future<List<Soin>> listerSoins({bool? actif, String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.soins,
        queryParameters: {
          if (actif != null) 'actif': actif.toString(),
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': 200,
        },
      );
      final data = response.data['soins'] as List;
      return data.map((json) => SoinModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Soin> creerSoin(Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.soins, data: corps);
      return SoinModel.fromJson(response.data['soin'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Soin> modifierSoin(String id, Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.patch('${ApiConstants.soins}/$id', data: corps);
      return SoinModel.fromJson(response.data['soin'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> changerStatutSoin(String id, bool actif) async {
    try {
      await _apiClient.dio.patch(ApiConstants.soinStatut(id), data: {'actif': actif});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Téléverse une image/vidéo pour un soin (`role` = "couverture" |
  /// "galerie" | "video", voir `soinController.televerserMediaSoin`).
  Future<Soin> televerserMediaSoin(String id, String cheminFichier, {String role = 'galerie'}) async {
    try {
      final nomFichier = cheminFichier.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'role': role,
        'fichier': await MultipartFile.fromFile(cheminFichier, filename: nomFichier),
      });
      final response = await _apiClient.dio.post(ApiConstants.soinMedia(id), data: formData);
      return SoinModel.fromJson(response.data['soin'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Remplace un média existant (nouveau fichier téléversé à la place de
  /// l'ancien, dont le fichier physique est supprimé côté backend) —
  /// `PATCH /api/soins/:id/media`. `ancienUrl` est ignoré pour "couverture"
  /// (champ unique) ; requis pour "galerie"/"video" pour identifier
  /// l'élément à remplacer dans le tableau.
  Future<Soin> remplacerMediaSoin(
    String id,
    String cheminFichier, {
    required String role,
    String? ancienUrl,
  }) async {
    try {
      final nomFichier = cheminFichier.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'role': role,
        if (ancienUrl != null) 'ancienUrl': ancienUrl,
        'fichier': await MultipartFile.fromFile(cheminFichier, filename: nomFichier),
      });
      final response = await _apiClient.dio.patch(ApiConstants.soinMedia(id), data: formData);
      return SoinModel.fromJson(response.data['soin'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Supprime un média (référence en base + fichier physique local/R2) —
  /// `DELETE /api/soins/:id/media`. `url` est requis pour "galerie"/"video",
  /// ignoré pour "couverture" (voir `soinController.supprimerMediaSoin`).
  Future<Soin> supprimerMediaSoin(String id, {required String role, String? url}) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.soinMedia(id),
        data: {'role': role, if (url != null) 'url': url},
      );
      return SoinModel.fromJson(response.data['soin'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Suppression définitive (`DELETE /api/soins/:id`) — le backend refuse
  /// (409) si des souscriptions existent déjà pour ce soin ; dans ce cas on
  /// relaie le message d'erreur du backend tel quel (voir `ApiException`).
  Future<void> supprimerSoin(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.soins}/$id');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Souscriptions (vue back-office) ---

  Future<List<Souscription>> listerSouscriptions({String? statut}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.souscriptions,
        queryParameters: {if (statut != null) 'statut': statut},
      );
      final data = response.data['souscriptions'] as List;
      return data.map((json) => SouscriptionModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<Souscription> modifierSouscription(String id, Map<String, dynamic> corps) async {
    try {
      final response = await _apiClient.dio.patch('${ApiConstants.souscriptions}/$id', data: corps);
      return SouscriptionModel.fromJson(response.data['souscription'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> annulerSouscription(String id) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.souscriptions}/$id/annuler');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  Future<void> terminerSouscription(String id) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.souscriptions}/$id/terminer');
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Suppression définitive d'une souscription (housekeeping back-office) —
  /// action irréversible, toujours confirmée côté UI avant l'appel.
  Future<void> supprimerSouscription(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.souscriptions}/$id');
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

  /// Combine les chiffres clés temps réel (`/stats/operationnel`) et le
  /// montant réellement encaissé aujourd'hui (`/stats/paiements`, filtré sur
  /// la journée en cours) — le premier endpoint ne renvoie qu'un compteur de
  /// paiements réussis du jour, pas leur montant cumulé.
  Future<StatistiquesGlobales> obtenirStatistiques() async {
    try {
      final aujourdhui = DateTime.now();
      final debutJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day).toIso8601String();

      final responses = await Future.wait([
        _apiClient.dio.get(ApiConstants.statistiquesOperationnelles),
        _apiClient.dio.get(
          ApiConstants.statistiquesPaiements,
          queryParameters: {'dateDebut': debutJour},
        ),
      ]);

      final stats = responses[0].data['stats'] as Map<String, dynamic>;
      // `/stats/paiements` renvoie `totalEncaisse` à la racine de la
      // réponse (pas sous une clé `stats`), contrairement à `/operationnel`.
      final totalEncaisse = responses[1].data['totalEncaisse'];

      return StatistiquesGlobalesModel.fromJson({...stats, 'totalEncaisse': totalEncaisse});
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Rapport "Souscriptions & paiements" (`GET /stats/paiements`) sur une
  /// période donnée — répartition des souscriptions et des paiements par
  /// statut, et montant total encaissé. Par défaut, les 30 derniers jours
  /// (même fenêtre par défaut que côté backend).
  Future<StatistiquesPaiementsDetail> obtenirStatistiquesPaiementsDetail({DateTime? dateDebut, DateTime? dateFin}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.statistiquesPaiements,
        queryParameters: {
          if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String(),
          if (dateFin != null) 'dateFin': dateFin.toIso8601String(),
        },
      );
      return StatistiquesPaiementsDetailModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  // --- Messagerie (`/api/conversations`) — même branchement que AVS et
  // coordonnateur (voir `AvsRemoteDataSource`). Contrairement à l'AVS,
  // l'administrateur n'a PAS besoin de replier silencieusement les erreurs
  // sur l'annuaire : `GET /utilisateurs/role/:role` lui est ouvert côté
  // backend (voir `utilisateurRoutes.js`), donc il peut vraiment contacter
  // tout le monde (AVS, médecins, coordonnateurs, patients/familles). ---

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

  /// Annuaire par rôle (`avs`, `medecin`, `coordonnateur`, `patient`), pour
  /// que l'administrateur puisse démarrer une conversation avec n'importe
  /// quel groupe depuis l'onglet Messagerie. Repli silencieux sur liste
  /// vide en cas d'erreur réseau plutôt que de casser tout l'onglet pour
  /// une seule section.
  Future<List<PersonnelAnnuaire>> listerPersonnelParRole(String role) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.utilisateursParRole(role));
      final data = (response.data['utilisateurs'] ?? response.data['data'] ?? const []) as List;
      return data.map((json) => PersonnelAnnuaireModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException {
      return const [];
    }
  }

  /// Télécharge le PDF exporté par le backend (`GET /api/stats/export/pdf`,
  /// qui renvoie directement le binaire — pas de JSON avec une url) et
  /// l'enregistre dans un fichier temporaire. Retourne le chemin local du
  /// fichier, à ouvrir/partager côté UI.
  Future<String> exporterStatistiquesPdf() async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        ApiConstants.statistiquesExportPdf,
        options: Options(responseType: ResponseType.bytes),
      );
      final horodatage = DateTime.now().millisecondsSinceEpoch;
      final fichier = File('${Directory.systemTemp.path}/statistiques_spadcm_$horodatage.pdf');
      await fichier.writeAsBytes(response.data!);
      return fichier.path;
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }

  /// Même principe que [exporterStatistiquesPdf], mais pour le rapport
  /// détaillé de suivi des patients (`GET /stats/export/patients/pdf`) —
  /// horaires, retards par patient et synthèse générale.
  Future<String> exporterRapportPatientsPdf() async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        ApiConstants.statistiquesExportPatientsPdf,
        options: Options(responseType: ResponseType.bytes),
      );
      final horodatage = DateTime.now().millisecondsSinceEpoch;
      final fichier = File('${Directory.systemTemp.path}/rapport_patients_spadcm_$horodatage.pdf');
      await fichier.writeAsBytes(response.data!);
      return fichier.path;
    } on DioException catch (e) {
      throw ApiClient.toAppException(e);
    }
  }
}
