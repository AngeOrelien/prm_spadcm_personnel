import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../data/datasources/administrateur_remote_datasource.dart';
import '../../domain/entities/administrateur_entities.dart';

final administrateurRemoteDataSourceProvider = Provider<AdministrateurRemoteDataSource>((ref) {
  return AdministrateurRemoteDataSource(ref.watch(apiClientProvider));
});

final utilisateursListProvider = FutureProvider.autoDispose<List<Utilisateur>>((ref) {
  return ref.watch(administrateurRemoteDataSourceProvider).listerUtilisateurs();
});

final paiementsListProvider = FutureProvider.autoDispose<List<Paiement>>((ref) {
  return ref.watch(administrateurRemoteDataSourceProvider).listerPaiements();
});

final statistiquesGlobalesProvider = FutureProvider.autoDispose<StatistiquesGlobales>((ref) {
  return ref.watch(administrateurRemoteDataSourceProvider).obtenirStatistiques();
});

/// Rapport "Souscriptions & paiements" de l'onglet Statistiques (30 derniers
/// jours par défaut, même fenêtre que le backend).
final statistiquesPaiementsDetailProvider = FutureProvider.autoDispose<StatistiquesPaiementsDetail>((ref) {
  return ref.watch(administrateurRemoteDataSourceProvider).obtenirStatistiquesPaiementsDetail();
});

// --- Ressources : catalogue de soins ---

final soinsListProvider = FutureProvider.autoDispose<List<Soin>>((ref) {
  return ref.watch(administrateurRemoteDataSourceProvider).listerSoins();
});

// --- Ressources : souscriptions ---

final souscriptionsListProvider = FutureProvider.autoDispose<List<Souscription>>((ref) {
  return ref.watch(administrateurRemoteDataSourceProvider).listerSouscriptions();
});

/// Id de l'administrateur connecté — nécessaire pour la messagerie, qui ne
/// s'auto-filtre pas côté serveur (même remarque que côté AVS/Coordonnateur).
String _monId(Ref ref) => ref.watch(authControllerProvider).value?.id ?? '';

/// Conversations de l'administrateur connecté (onglet Messagerie).
final administrateurConversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  final id = _monId(ref);
  return ref.watch(administrateurRemoteDataSourceProvider).listerConversations(id);
});

/// Messages d'une conversation précise (fil de discussion ouvert).
final administrateurMessagesProvider = FutureProvider.autoDispose.family<List<MessageConversation>, String>((ref, conversationId) {
  final id = _monId(ref);
  return ref.watch(administrateurRemoteDataSourceProvider).listerMessages(conversationId, id);
});

/// Annuaire par rôle (`avs`, `medecin`, `coordonnateur`, `patient`) pour la
/// messagerie administrateur — contrairement à l'AVS, l'admin peut vraiment
/// contacter tout le monde (route ouverte côté backend pour son rôle).
final personnelAnnuaireProvider = FutureProvider.autoDispose.family<List<PersonnelAnnuaire>, String>((ref, role) {
  return ref.watch(administrateurRemoteDataSourceProvider).listerPersonnelParRole(role);
});

class AdministrateurActions {
  final Ref _ref;

  AdministrateurActions(this._ref);

  AdministrateurRemoteDataSource get _ds => _ref.read(administrateurRemoteDataSourceProvider);
  String get _monIdActuel => _ref.read(authControllerProvider).value?.id ?? '';

  Future<void> creerUtilisateur(Map<String, dynamic> corps) async {
    await _ds.creerUtilisateur(corps);
    _ref.invalidate(utilisateursListProvider);
  }

  Future<void> basculerActivation(String id, bool actif) async {
    await _ds.basculerActivation(id, actif);
    _ref.invalidate(utilisateursListProvider);
  }

  Future<void> modifierUtilisateur(String id, Map<String, dynamic> corps) async {
    await _ds.modifierUtilisateur(id, corps);
    _ref.invalidate(utilisateursListProvider);
  }

  Future<void> supprimerUtilisateur(String id) async {
    await _ds.supprimerUtilisateur(id);
    _ref.invalidate(utilisateursListProvider);
  }

  Future<String> exporterStatistiquesPdf() => _ds.exporterStatistiquesPdf();

  Future<String> exporterRapportPatientsPdf() => _ds.exporterRapportPatientsPdf();

  // --- Catalogue de soins ---

  Future<Soin> creerSoin(Map<String, dynamic> corps) async {
    final soin = await _ds.creerSoin(corps);
    _ref.invalidate(soinsListProvider);
    return soin;
  }

  Future<void> modifierSoin(String id, Map<String, dynamic> corps) async {
    await _ds.modifierSoin(id, corps);
    _ref.invalidate(soinsListProvider);
  }

  Future<void> changerStatutSoin(String id, bool actif) async {
    await _ds.changerStatutSoin(id, actif);
    _ref.invalidate(soinsListProvider);
  }

  Future<Soin> televerserMediaSoin(String id, String cheminFichier, {String role = 'galerie'}) async {
    final soin = await _ds.televerserMediaSoin(id, cheminFichier, role: role);
    _ref.invalidate(soinsListProvider);
    return soin;
  }

  Future<Soin> remplacerMediaSoin(
    String id,
    String cheminFichier, {
    required String role,
    String? ancienUrl,
  }) async {
    final soin = await _ds.remplacerMediaSoin(id, cheminFichier, role: role, ancienUrl: ancienUrl);
    _ref.invalidate(soinsListProvider);
    return soin;
  }

  Future<Soin> supprimerMediaSoin(String id, {required String role, String? url}) async {
    final soin = await _ds.supprimerMediaSoin(id, role: role, url: url);
    _ref.invalidate(soinsListProvider);
    return soin;
  }

  Future<void> supprimerSoin(String id) async {
    await _ds.supprimerSoin(id);
    _ref.invalidate(soinsListProvider);
  }

  // --- Souscriptions ---

  Future<void> modifierSouscription(String id, Map<String, dynamic> corps) async {
    await _ds.modifierSouscription(id, corps);
    _ref.invalidate(souscriptionsListProvider);
  }

  Future<void> annulerSouscription(String id) async {
    await _ds.annulerSouscription(id);
    _ref.invalidate(souscriptionsListProvider);
  }

  Future<void> terminerSouscription(String id) async {
    await _ds.terminerSouscription(id);
    _ref.invalidate(souscriptionsListProvider);
  }

  Future<void> supprimerSouscription(String id) async {
    await _ds.supprimerSouscription(id);
    _ref.invalidate(souscriptionsListProvider);
  }

  /// Ouvre (ou crée) le fil de discussion privé avec [participantId].
  Future<Conversation> ouvrirConversationAvec(String participantId, {String? patientContexteId}) {
    return _ds.creerOuObtenirConversation(participantId, _monIdActuel, patientContexteId: patientContexteId);
  }

  Future<void> envoyerMessage(String conversationId, String contenu) async {
    await _ds.envoyerMessage(conversationId, contenu, _monIdActuel);
    _ref.invalidate(administrateurMessagesProvider(conversationId));
    _ref.invalidate(administrateurConversationsProvider);
  }

  Future<void> marquerConversationLue(String conversationId) async {
    await _ds.marquerConversationLue(conversationId);
    _ref.invalidate(administrateurConversationsProvider);
  }
}

final administrateurActionsProvider = Provider<AdministrateurActions>((ref) {
  return AdministrateurActions(ref);
});
