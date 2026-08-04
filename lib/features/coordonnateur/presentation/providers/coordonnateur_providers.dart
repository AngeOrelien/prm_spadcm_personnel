import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../data/datasources/coordonnateur_remote_datasource.dart';
import '../../data/models/coordonnateur_models.dart';
import '../../domain/entities/coordonnateur_entities.dart';

// ---------------------------------------------------------------------------
// Providers branchés sur le vrai backend `prm-spad-backend` (voir
// `data/datasources/coordonnateur_remote_datasource.dart`). Chaque liste est
// un [FutureProvider] : les pages consomment un `AsyncValue<List<...>>` et
// gèrent elles-mêmes chargement/erreur (voir `.when(...)` dans les pages).
// Les mutations (créer/valider/rejeter...) passent par [CoordonnateurActions]
// puis invalident les providers de liste concernés pour rafraîchir l'UI.
// ---------------------------------------------------------------------------

final coordonnateurRemoteDataSourceProvider = Provider<CoordonnateurRemoteDataSource>((ref) {
  return CoordonnateurRemoteDataSource(ref.watch(apiClientProvider));
});

/// Liste des patients suivis (recherche optionnelle côté serveur).
final patientsListProvider = FutureProvider.autoDispose<List<Patient>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerPatients();
});

/// Détail d'un patient précis (fiche complète + AVS assigné).
final patientDetailProvider = FutureProvider.autoDispose.family<Patient, String>((ref, id) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).obtenirPatient(id);
});

/// Équipe AVS avec charge de travail (`patientsAssignes`) déjà calculée côté API.
final avsListProvider = FutureProvider.autoDispose<List<Avs>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerEquipeAvs();
});

/// Toutes les affectations (actives + terminées), utilisées par la vue
/// calendrier et les fiches détail patient/AVS.
final affectationsListProvider = FutureProvider.autoDispose<List<Affectation>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerAffectations();
});

/// Affectations d'un patient précis (fiche détail patient).
final affectationsDuPatientProvider = FutureProvider.autoDispose.family<List<Affectation>, String>((ref, patientId) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerAffectations(patientId: patientId);
});

/// Affectations d'un AVS précis (fiche détail AVS).
final affectationsDeLavsProvider = FutureProvider.autoDispose.family<List<Affectation>, String>((ref, avsId) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerAffectations(avsId: avsId);
});

/// Tous les rapports (page "Rapports", filtrable côté UI).
final rapportsListProvider = FutureProvider.autoDispose<List<RapportAvs>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerRapports();
});

/// Rapports d'un patient précis (fiche détail patient : "Derniers rapports").
final rapportsDuPatientProvider = FutureProvider.autoDispose.family<List<RapportAvs>, String>((ref, patientId) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerRapports(patientId: patientId);
});

/// Rapports d'un AVS précis (fiche détail AVS).
final rapportsDeLavsProvider = FutureProvider.autoDispose.family<List<RapportAvs>, String>((ref, avsId) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerRapports(avsId: avsId);
});

/// File d'attente de validation médicale (compteur pour l'accueil + header).
final rapportsEnAttenteListProvider = FutureProvider.autoDispose<List<RapportAvs>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerRapportsEnAttente();
});

final rapportsEnAttenteProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(rapportsEnAttenteListProvider).maybeWhen(
        data: (liste) => liste.length,
        orElse: () => 0,
      );
});

final patientsNonAssignesProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(patientsListProvider).maybeWhen(
        data: (liste) => liste.where((p) => p.avsAssigneId == null).length,
        orElse: () => 0,
      );
});

/// Id de l'utilisateur connecté, utilisé pour savoir "qui est l'autre" dans
/// une conversation et si un message vient de moi.
final _currentUserIdProvider = Provider.autoDispose<String>((ref) {
  return ref.watch(authControllerProvider).value?.id ?? '';
});

/// Chiffres clés du tableau de bord (`/api/stats/operationnel`) : alertes
/// ouvertes, rendez-vous à venir, présences du jour, rapports en retard...
/// Alimente les cartes supplémentaires de l'accueil coordonnateur.
final statistiquesOperationnellesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).statistiquesOperationnelles();
});

/// Liste des conversations du coordonnateur (onglet Messagerie).
final conversationsListProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  final currentUserId = ref.watch(_currentUserIdProvider);
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerConversations(currentUserId);
});

/// Messages d'une conversation précise (fil de discussion ouvert).
final messagesProvider = FutureProvider.autoDispose.family<List<MessageConversation>, String>((ref, conversationId) {
  final currentUserId = ref.watch(_currentUserIdProvider);
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerMessages(conversationId, currentUserId);
});

/// Annuaire par rôle (médecins / administrateurs / autres coordonnateurs),
/// pour la messagerie coordonnateur — le coordonnateur peut contacter tout
/// le monde, comme l'administrateur et le médecin.
final personnelAnnuaireProvider = FutureProvider.autoDispose.family<List<PersonnelAnnuaire>, String>((ref, role) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerPersonnelParRole(role);
});

/// Vue d'ensemble des présences/check-in du jour (onglet Check-in).
final presencesAujourdhuiProvider = FutureProvider.autoDispose<List<PresenceAvs>>((ref) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).vueEnsembleDuJour();
});

/// Historique des présences d'un AVS précis (fiche détail check-in).
final presencesDeLavsProvider = FutureProvider.autoDispose.family<List<PresenceAvs>, String>((ref, avsId) {
  return ref.watch(coordonnateurRemoteDataSourceProvider).listerPresences(avsId: avsId);
});

/// Actions qui modifient des données côté serveur, puis invalident les
/// providers de liste concernés pour que l'UI se rafraîchisse automatiquement.
class CoordonnateurActions {
  final Ref _ref;

  CoordonnateurActions(this._ref);

  CoordonnateurRemoteDataSource get _ds => _ref.read(coordonnateurRemoteDataSourceProvider);

  Future<void> ajouterPatient({
    required String nom,
    required String prenom,
    DateTime? dateNaissance,
    required String adresse,
    required String pathologie,
    List<String> antecedents = const [],
    List<String> allergies = const [],
    List<String> difficultesMobilite = const [],
    String? telephone,
    String? email,
    String? motDePasse,
  }) async {
    await _ds.creerPatient(
      PatientModel.toCreateJson(
        nom: nom,
        prenom: prenom,
        dateNaissance: dateNaissance,
        adresse: adresse,
        pathologie: pathologie,
        antecedents: antecedents,
        allergies: allergies,
        difficultesMobilite: difficultesMobilite,
        telephone: telephone,
        email: email,
        motDePasse: motDePasse,
      ),
    );
    _ref.invalidate(patientsListProvider);
  }

  /// Enregistre la localisation GPS du domicile d'un patient (c'est le
  /// coordonnateur qui la renseigne, voir README §10.3) — invalide la fiche
  /// détail et la liste pour que le nouveau statut de géolocalisation
  /// s'affiche immédiatement.
  Future<void> definirLocalisationPatient(String patientId, {required double latitude, required double longitude}) async {
    await _ds.definirLocalisationPatient(patientId, latitude: latitude, longitude: longitude);
    _ref.invalidate(patientDetailProvider(patientId));
    _ref.invalidate(patientsListProvider);
  }

  /// Définit l'heure limite de rapport propre à un AVS (voir README §10.2) —
  /// invalide la liste équipe pour que la fiche AVS affiche la nouvelle heure.
  Future<void> definirHeureRapportAvs(String avsId, {required String heureRapportLimite}) async {
    await _ds.definirHeureRapportAvs(avsId, heureRapportLimite: heureRapportLimite);
    _ref.invalidate(avsListProvider);
  }

  Future<void> creerAffectation({
    required String patientId,
    required String avsId,
    required String frequence,
    required DateTime dateDebut,
    String? notes,
  }) async {
    await _ds.creerAffectation(
      patientId: patientId,
      avsId: avsId,
      frequence: frequence,
      dateDebut: dateDebut,
      notes: notes,
    );
    _ref.invalidate(affectationsListProvider);
    _ref.invalidate(patientsListProvider);
    _ref.invalidate(avsListProvider);
    _ref.invalidate(patientDetailProvider(patientId));
  }

  Future<void> terminerAffectation(String id, {String? patientId}) async {
    await _ds.terminerAffectation(id);
    _ref.invalidate(affectationsListProvider);
    _ref.invalidate(patientsListProvider);
    _ref.invalidate(avsListProvider);
    if (patientId != null) _ref.invalidate(patientDetailProvider(patientId));
  }

  Future<void> validerRapport(String id) async {
    await _ds.validerRapport(id);
    _ref.invalidate(rapportsListProvider);
    _ref.invalidate(rapportsEnAttenteListProvider);
  }

  Future<void> rejeterRapport(String id, {String? motif}) async {
    await _ds.rejeterRapport(id, motif: motif);
    _ref.invalidate(rapportsListProvider);
    _ref.invalidate(rapportsEnAttenteListProvider);
  }

  /// Ouvre (ou crée) le fil de discussion privé avec [participantId] — à
  /// appeler avant de naviguer vers la page de conversation, pour obtenir un
  /// vrai id de conversation plutôt que d'utiliser l'id du patient/AVS.
  Future<Conversation> ouvrirConversationAvec(String participantId, {String? patientContexteId}) {
    final currentUserId = _ref.read(_currentUserIdProvider);
    return _ds.creerOuObtenirConversation(participantId, currentUserId, patientContexteId: patientContexteId);
  }

  Future<void> envoyerMessage(String conversationId, String contenu) async {
    final currentUserId = _ref.read(_currentUserIdProvider);
    await _ds.envoyerMessage(conversationId, contenu, currentUserId);
    _ref.invalidate(messagesProvider(conversationId));
    _ref.invalidate(conversationsListProvider);
  }

  Future<void> marquerConversationLue(String conversationId) async {
    await _ds.marquerConversationLue(conversationId);
    _ref.invalidate(conversationsListProvider);
  }
}

final coordonnateurActionsProvider = Provider<CoordonnateurActions>((ref) {
  return CoordonnateurActions(ref);
});
