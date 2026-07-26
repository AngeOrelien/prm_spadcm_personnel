import 'dart:io';

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
}
