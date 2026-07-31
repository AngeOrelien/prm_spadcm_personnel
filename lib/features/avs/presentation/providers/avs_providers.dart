import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/services/rapports_locaux_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../data/datasources/avs_remote_datasource.dart';
import '../../domain/entities/avs_entities.dart';

// ---------------------------------------------------------------------------
// Providers branchés sur le vrai backend `prm-spad-backend` (voir
// `data/datasources/avs_remote_datasource.dart`). Même pattern que le
// feature Coordonnateur : chaque liste est un [FutureProvider], les
// mutations passent par [AvsActions] puis invalident les providers de liste
// concernés pour rafraîchir l'UI.
// ---------------------------------------------------------------------------

final avsRemoteDataSourceProvider = Provider<AvsRemoteDataSource>((ref) {
  return AvsRemoteDataSource(ref.watch(apiClientProvider));
});

/// Stockage local des rapports dont l'envoi a échoué (pas de réseau) — voir
/// `RapportsLocauxService`.
final rapportsLocauxServiceProvider = Provider<RapportsLocauxService>((ref) {
  return RapportsLocauxService();
});

/// Rapports en attente de synchronisation (créés hors-ligne ou dont l'envoi
/// a échoué), affichés en tête de "Mes rapports" avec un bouton "Réessayer".
final rapportsNonSynchronisesProvider = FutureProvider.autoDispose<List<RapportLocal>>((ref) {
  return ref.watch(rapportsLocauxServiceProvider).lister();
});

/// Id de l'AVS connecté — nécessaire pour les routes qui ne s'auto-filtrent
/// pas côté serveur (`/assignations`, messagerie).
String _monId(Ref ref) => ref.watch(authControllerProvider).value?.id ?? '';

/// Patient(s) actuellement assigné(s) à l'AVS connecté (onglet "Mon
/// patient"). La grande majorité des AVS n'ont qu'un seul patient actif à la
/// fois, mais l'UI gère aussi le cas de plusieurs patients.
final mesPatientsProvider = FutureProvider.autoDispose<List<Patient>>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).mesPatients();
});

/// Affectations actives de l'AVS connecté (fréquence de visite, date de
/// début) — complète `mesPatientsProvider` pour l'affichage détaillé.
final mesAffectationsProvider = FutureProvider.autoDispose<List<Affectation>>((ref) {
  final id = _monId(ref);
  if (id.isEmpty) return Future.value(const []);
  return ref.watch(avsRemoteDataSourceProvider).mesAffectationsActives(id);
});

/// Historique de mes rapports journaliers (tous patients confondus).
final mesRapportsProvider = FutureProvider.autoDispose<List<RapportAvs>>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).mesRapports();
});

/// Rapports concernant un patient précis (onglet "Mon patient").
final mesRapportsDuPatientProvider = FutureProvider.autoDispose.family<List<RapportAvs>, String>((ref, patientId) {
  return ref.watch(avsRemoteDataSourceProvider).mesRapports(patientId: patientId);
});

/// Présence (check-in/out) du jour.
final presenceDuJourProvider = FutureProvider.autoDispose<Presence?>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).presenceDuJour();
});

/// Historique des présences (récapitulatif de l'onglet Check-in + calcul des
/// statistiques personnelles).
final mesPresencesProvider = FutureProvider.autoDispose<List<Presence>>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).mesPresences();
});

/// Statistiques personnelles de ponctualité, calculées côté app à partir de
/// `mesRapportsProvider` (champ `statutRemise`) et `mesPresencesProvider`
/// (champ `statut`) — voir le commentaire sur `StatistiquesPonctualiteAvs`.
final mesStatistiquesProvider = FutureProvider.autoDispose<StatistiquesPonctualiteAvs>((ref) async {
  final rapports = await ref.watch(mesRapportsProvider.future);
  final presences = await ref.watch(mesPresencesProvider.future);

  final rapportsATemps = rapports.where((r) => r.statutRemise == StatutRemiseRapport.aTemps).length;
  final rapportsEnRetard = rapports.where((r) => r.statutRemise == StatutRemiseRapport.enRetard).length;
  final checkinsATemps = presences.where((p) => p.statut == StatutPresence.aLheure).length;
  final checkinsEnRetard = presences.where((p) => p.statut == StatutPresence.enRetard).length;
  final absences = presences.where((p) => p.statut == StatutPresence.absent).length;

  return StatistiquesPonctualiteAvs(
    rapportsATemps: rapportsATemps,
    rapportsEnRetard: rapportsEnRetard,
    checkinsATemps: checkinsATemps,
    checkinsEnRetard: checkinsEnRetard,
    absences: absences,
  );
});

/// Conversations de l'AVS connecté (onglet Messages).
final avsConversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  final id = _monId(ref);
  return ref.watch(avsRemoteDataSourceProvider).listerConversations(id);
});

/// Messages d'une conversation précise (fil de discussion ouvert).
final avsMessagesProvider = FutureProvider.autoDispose.family<List<MessageConversation>, String>((ref, conversationId) {
  final id = _monId(ref);
  return ref.watch(avsRemoteDataSourceProvider).listerMessages(conversationId, id);
});

/// Annuaire par rôle (coordonnateurs / médecins / administrateurs), pour la
/// messagerie AVS. Repli silencieux sur liste vide tant que le backend ne
/// permet pas à un AVS d'appeler cette route — voir `BACKEND-TODO.md`.
final personnelAnnuaireProvider = FutureProvider.autoDispose.family<List<PersonnelAnnuaire>, String>((ref, role) {
  return ref.watch(avsRemoteDataSourceProvider).listerPersonnelParRole(role);
});

class AvsActions {
  final Ref _ref;

  AvsActions(this._ref);

  AvsRemoteDataSource get _ds => _ref.read(avsRemoteDataSourceProvider);
  String get _monIdActuel => _ref.read(authControllerProvider).value?.id ?? '';

  /// Envoie le rapport au serveur. Si la connexion ne passe pas (pas de
  /// réponse HTTP du tout — timeout/serveur injoignable, voir
  /// [AppException.statusCode] nul), le rapport n'est PAS perdu : il est
  /// gardé localement (voir `RapportsLocauxService`) pour réessai ultérieur,
  /// et [RapportEnregistreLocalementException] est levée pour que l'UI
  /// affiche un message différent d'un échec pur et simple.
  ///
  /// Une erreur applicative renvoyée PAR le serveur (validation, 4xx/5xx
  /// explicite) n'est en revanche pas mise en attente : elle est remontée
  /// telle quelle, le problème ne se réglera pas tout seul en réessayant.
  Future<void> creerRapport(Map<String, dynamic> corps, {required String patientNom}) async {
    try {
      await _ds.creerRapport(corps);
      _ref.invalidate(mesRapportsProvider);
      if (corps['patientId'] != null) {
        _ref.invalidate(mesRapportsDuPatientProvider(corps['patientId'].toString()));
      }
      _ref.invalidate(mesStatistiquesProvider);
    } on AppException catch (e) {
      if (e.statusCode == null) {
        await _ref.read(rapportsLocauxServiceProvider).ajouter(
              RapportLocal(
                idLocal: DateTime.now().microsecondsSinceEpoch.toString(),
                patientId: corps['patientId']?.toString() ?? '',
                patientNom: patientNom,
                creeLe: DateTime.now(),
                corps: corps,
              ),
            );
        _ref.invalidate(rapportsNonSynchronisesProvider);
        throw const RapportEnregistreLocalementException();
      }
      rethrow;
    }
  }

  /// Réessaie l'envoi d'un rapport resté en attente de synchronisation. En
  /// cas de nouvel échec réseau, il reste simplement dans la liste locale
  /// (avec le message d'erreur mis à jour) pour un prochain essai.
  Future<void> reessayerEnvoiRapport(RapportLocal rapportLocal) async {
    final service = _ref.read(rapportsLocauxServiceProvider);
    try {
      await _ds.creerRapport(rapportLocal.corps);
      await service.supprimer(rapportLocal.idLocal);
      _ref.invalidate(rapportsNonSynchronisesProvider);
      _ref.invalidate(mesRapportsProvider);
      _ref.invalidate(mesRapportsDuPatientProvider(rapportLocal.patientId));
      _ref.invalidate(mesStatistiquesProvider);
    } on AppException catch (e) {
      await service.marquerErreur(rapportLocal.idLocal, e.message);
      _ref.invalidate(rapportsNonSynchronisesProvider);
      rethrow;
    }
  }

  Future<void> checkIn({required double latitude, required double longitude}) async {
    await _ds.checkIn(latitude: latitude, longitude: longitude);
    _ref.invalidate(presenceDuJourProvider);
    _ref.invalidate(mesPresencesProvider);
    _ref.invalidate(mesStatistiquesProvider);
  }

  Future<void> checkOut() async {
    await _ds.checkOut();
    _ref.invalidate(presenceDuJourProvider);
    _ref.invalidate(mesPresencesProvider);
    _ref.invalidate(mesStatistiquesProvider);
  }

  /// Ouvre (ou crée) le fil de discussion privé avec [participantId].
  Future<Conversation> ouvrirConversationAvec(String participantId, {String? patientContexteId}) {
    return _ds.creerOuObtenirConversation(participantId, _monIdActuel, patientContexteId: patientContexteId);
  }

  Future<void> envoyerMessage(String conversationId, String contenu) async {
    await _ds.envoyerMessage(conversationId, contenu, _monIdActuel);
    _ref.invalidate(avsMessagesProvider(conversationId));
    _ref.invalidate(avsConversationsProvider);
  }

  Future<void> marquerConversationLue(String conversationId) async {
    await _ds.marquerConversationLue(conversationId);
    _ref.invalidate(avsConversationsProvider);
  }
}

final avsActionsProvider = Provider<AvsActions>((ref) {
  return AvsActions(ref);
});

/// Levée par [AvsActions.creerRapport] quand l'envoi échoue faute de
/// connexion : le rapport est bien enregistré (localement), ce n'est donc
/// pas un échec à traiter comme les autres côté UI.
class RapportEnregistreLocalementException implements Exception {
  const RapportEnregistreLocalementException();
}
