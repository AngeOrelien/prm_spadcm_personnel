import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/ia_remote_datasource.dart';
import '../../domain/entities/ia_entities.dart';

final iaRemoteDataSourceProvider = Provider<IaRemoteDataSource>((ref) {
  return IaRemoteDataSource(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Chat — remplace la simulation locale de `shared/widgets/ai/ai_chat_logic.dart`
// (mots-clés + délai artificiel) par un vrai appel à `POST /api/assistant/chat`.
// Un seul contrôleur, partagé par le bouton flottant (feuille modale) et le
// fil épinglé (page complète) puisque les deux sont la même conversation
// logique côté utilisateur.
// ---------------------------------------------------------------------------

class ChatIaState {
  final List<MessageChatIa> messages;
  final bool enTrainDecrire;
  final String? erreur;

  const ChatIaState({this.messages = const [], this.enTrainDecrire = false, this.erreur});

  ChatIaState copyWith({List<MessageChatIa>? messages, bool? enTrainDecrire, String? erreur, bool clearErreur = false}) {
    return ChatIaState(
      messages: messages ?? this.messages,
      enTrainDecrire: enTrainDecrire ?? this.enTrainDecrire,
      erreur: clearErreur ? null : (erreur ?? this.erreur),
    );
  }
}

/// Borne le nombre d'échanges renvoyés au service IA à chaque appel (même
/// borne que `HISTORIQUE_MAX_MESSAGES` côté `assistantController.js`) :
/// au-delà, ça n'apporte plus de contexte utile et ça alourdit chaque appel.
const _historiqueMaxMessages = 20;

class ChatIaController extends StateNotifier<ChatIaState> {
  final IaRemoteDataSource _dataSource;
  final String? Function() _patientIdCourant;

  ChatIaController(this._dataSource, {String? Function()? patientIdCourant})
      : _patientIdCourant = patientIdCourant ?? (() => null),
        super(const ChatIaState());

  void demarrerAvecMessageAccueil(String texte) {
    if (state.messages.isNotEmpty) return;
    state = state.copyWith(messages: [
      MessageChatIa(contenu: texte, role: RoleMessageChat.assistant, heure: DateTime.now()),
    ]);
  }

  Future<void> envoyer(String texte) async {
    final contenu = texte.trim();
    if (contenu.isEmpty || state.enTrainDecrire) return;

    final historiqueAvantEnvoi = state.messages;
    state = state.copyWith(
      messages: [...historiqueAvantEnvoi, MessageChatIa(contenu: contenu, role: RoleMessageChat.utilisateur, heure: DateTime.now())],
      enTrainDecrire: true,
      clearErreur: true,
    );

    try {
      final historiquePourAppel = historiqueAvantEnvoi.length > _historiqueMaxMessages
          ? historiqueAvantEnvoi.sublist(historiqueAvantEnvoi.length - _historiqueMaxMessages)
          : historiqueAvantEnvoi;

      final reponse = await _dataSource.envoyerMessage(
        message: contenu,
        historique: historiquePourAppel,
        patientId: _patientIdCourant(),
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          MessageChatIa(contenu: reponse.reponse, role: RoleMessageChat.assistant, heure: DateTime.now()),
        ],
        enTrainDecrire: false,
      );
    } on AppException catch (e) {
      // Dégradation gracieuse : le message d'erreur reste visible dans le
      // fil (comme un message de l'assistant) plutôt que de bloquer l'UI,
      // avec le vrai motif (ex. "Assistant IA non configuré côté serveur"
      // si IA_SERVICE_URL manque encore en environnement de dev).
      state = state.copyWith(
        messages: [
          ...state.messages,
          MessageChatIa(
            contenu: "Je n'ai pas pu répondre : ${e.message}",
            role: RoleMessageChat.assistant,
            heure: DateTime.now(),
          ),
        ],
        enTrainDecrire: false,
        erreur: e.message,
      );
    }
  }
}

/// `.autoDispose` volontairement PAS utilisé ici : on veut que la
/// conversation survive à la fermeture/réouverture de la feuille modale ou
/// à la navigation entre la page complète et le bouton flottant (même
/// historique des deux côtés, voir `ai_chat_logic.dart`).
final chatIaControllerProvider = StateNotifierProvider<ChatIaController, ChatIaState>((ref) {
  return ChatIaController(ref.watch(iaRemoteDataSourceProvider));
});

// ---------------------------------------------------------------------------
// Résumé, évolution santé, alertes intelligentes — tous paramétrés par un
// patientId (onglet "Mon patient" côté AVS, dossier patient côté
// coordonnateur/médecin/administrateur).
// ---------------------------------------------------------------------------

final resumeRapportsProvider =
    FutureProvider.autoDispose.family<ResumeRapports, String>((ref, patientId) {
  return ref.watch(iaRemoteDataSourceProvider).resumeRapports(patientId: patientId);
});

final evolutionSanteProvider =
    FutureProvider.autoDispose.family<EvolutionSante, ({String patientId, int jours})>((ref, params) {
  return ref.watch(iaRemoteDataSourceProvider).evolutionSante(patientId: params.patientId, jours: params.jours);
});

final alertesIntelligentesProvider =
    FutureProvider.autoDispose.family<AlertesIntelligentes, String>((ref, patientId) {
  return ref.watch(iaRemoteDataSourceProvider).alertesIntelligentes(patientId: patientId);
});

// ---------------------------------------------------------------------------
// Performance AVS — classement global (coordonnateur/administrateur) ou
// score personnel (avsId ignoré côté serveur pour un compte AVS, voir
// `iaController.js`).
// ---------------------------------------------------------------------------

final performanceAvsProvider =
    FutureProvider.autoDispose.family<PerformanceAvs, ({String? avsId, int jours})>((ref, params) {
  return ref.watch(iaRemoteDataSourceProvider).performanceAvs(avsId: params.avsId, jours: params.jours);
});

// ---------------------------------------------------------------------------
// Recherche sémantique — état géré manuellement (pas un simple
// FutureProvider) car déclenché par une saisie utilisateur avec un
// paramètre supplémentaire (patientId optionnel), pas juste rejoué
// automatiquement au changement de family key.
// ---------------------------------------------------------------------------

class RechercheSemantiqueState {
  final List<ResultatRechercheSemantique> resultats;
  final bool enCours;
  final String? erreur;
  final bool aDejaRecherche;

  const RechercheSemantiqueState({
    this.resultats = const [],
    this.enCours = false,
    this.erreur,
    this.aDejaRecherche = false,
  });

  RechercheSemantiqueState copyWith({
    List<ResultatRechercheSemantique>? resultats,
    bool? enCours,
    String? erreur,
    bool clearErreur = false,
    bool? aDejaRecherche,
  }) {
    return RechercheSemantiqueState(
      resultats: resultats ?? this.resultats,
      enCours: enCours ?? this.enCours,
      erreur: clearErreur ? null : (erreur ?? this.erreur),
      aDejaRecherche: aDejaRecherche ?? this.aDejaRecherche,
    );
  }
}

class RechercheSemantiqueController extends StateNotifier<RechercheSemantiqueState> {
  final IaRemoteDataSource _dataSource;

  RechercheSemantiqueController(this._dataSource) : super(const RechercheSemantiqueState());

  Future<void> rechercher(String requete, {String? patientId}) async {
    if (requete.trim().length < 2) return;
    state = state.copyWith(enCours: true, clearErreur: true);
    try {
      final resultats = await _dataSource.rechercheSemantique(requete: requete, patientId: patientId);
      state = state.copyWith(resultats: resultats, enCours: false, aDejaRecherche: true);
    } on AppException catch (e) {
      state = state.copyWith(enCours: false, erreur: e.message, aDejaRecherche: true);
    }
  }
}

final rechercheSemantiqueControllerProvider =
    StateNotifierProvider.autoDispose<RechercheSemantiqueController, RechercheSemantiqueState>((ref) {
  return RechercheSemantiqueController(ref.watch(iaRemoteDataSourceProvider));
});
