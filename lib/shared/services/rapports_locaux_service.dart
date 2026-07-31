import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/avs/domain/entities/avs_entities.dart';

/// Persiste localement les rapports journaliers dont l'envoi au serveur a
/// échoué (pas de réseau, serveur injoignable...), pour que l'AVS les
/// retrouve dans "Mes rapports" — tout en haut de l'historique, avec un
/// bouton "Réessayer" — plutôt que de perdre sa saisie. Un seul point de
/// vérité, sur le même modèle que `SecureStorageService` pour les tokens.
///
/// Volontairement construit sur `flutter_secure_storage` (déjà une
/// dépendance de l'app, voir `secure_storage_service.dart`) plutôt que
/// d'introduire un nouveau package de stockage local.
class RapportsLocauxService {
  final FlutterSecureStorage _storage;
  static const _cle = 'rapports_en_attente_de_synchronisation';

  RapportsLocauxService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<List<RapportLocal>> lister() async {
    final brut = await _storage.read(key: _cle);
    if (brut == null || brut.isEmpty) return const [];
    try {
      final liste = jsonDecode(brut) as List;
      return liste.map((e) => RapportLocal.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      // Donnée locale corrompue (ex: changement de format) : on repart d'une
      // liste vide plutôt que de faire planter tout l'écran "Mes rapports".
      return const [];
    }
  }

  Future<void> _sauvegarderTout(List<RapportLocal> rapports) async {
    final brut = jsonEncode(rapports.map((r) => r.toJson()).toList());
    await _storage.write(key: _cle, value: brut);
  }

  Future<void> ajouter(RapportLocal rapport) async {
    final rapports = await lister();
    rapports.add(rapport);
    await _sauvegarderTout(rapports);
  }

  Future<void> supprimer(String idLocal) async {
    final rapports = await lister();
    rapports.removeWhere((r) => r.idLocal == idLocal);
    await _sauvegarderTout(rapports);
  }

  Future<void> marquerErreur(String idLocal, String erreur) async {
    final rapports = await lister();
    final index = rapports.indexWhere((r) => r.idLocal == idLocal);
    if (index == -1) return;
    rapports[index] = rapports[index].copierAvec(derniereErreur: erreur);
    await _sauvegarderTout(rapports);
  }
}
