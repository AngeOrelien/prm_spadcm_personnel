import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../data/datasources/medecin_remote_datasource.dart';
import '../../domain/entities/medecin_entities.dart';

final medecinRemoteDataSourceProvider = Provider<MedecinRemoteDataSource>((ref) {
  return MedecinRemoteDataSource(ref.watch(apiClientProvider));
});

final mesPatientsMedecinProvider = FutureProvider.autoDispose<List<DossierMedicalPatient>>((ref) {
  return ref.watch(medecinRemoteDataSourceProvider).listerMesPatients();
});

final traitementsProvider = FutureProvider.autoDispose<List<Traitement>>((ref) {
  return ref.watch(medecinRemoteDataSourceProvider).listerTraitements();
});

/// Id du médecin connecté — nécessaire pour la messagerie, qui ne s'auto-
/// filtre pas côté serveur (même remarque que les autres rôles).
String _monId(Ref ref) => ref.watch(authControllerProvider).value?.id ?? '';

/// Conversations du médecin connecté (onglet Messagerie).
final medecinConversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  final id = _monId(ref);
  return ref.watch(medecinRemoteDataSourceProvider).listerConversations(id);
});

/// Messages d'une conversation précise (fil de discussion ouvert).
final medecinMessagesProvider = FutureProvider.autoDispose.family<List<MessageConversation>, String>((ref, conversationId) {
  final id = _monId(ref);
  return ref.watch(medecinRemoteDataSourceProvider).listerMessages(conversationId, id);
});

/// Annuaire par rôle (AVS / médecins / coordonnateurs / administrateurs),
/// pour la messagerie médecin — le médecin peut contacter tout le monde,
/// comme l'administrateur et le coordonnateur.
final personnelAnnuaireMedecinProvider = FutureProvider.autoDispose.family<List<PersonnelAnnuaire>, String>((ref, role) {
  return ref.watch(medecinRemoteDataSourceProvider).listerPersonnelParRole(role);
});

class MedecinActions {
  final Ref _ref;

  MedecinActions(this._ref);

  MedecinRemoteDataSource get _ds => _ref.read(medecinRemoteDataSourceProvider);
  String get _monIdActuel => _ref.read(authControllerProvider).value?.id ?? '';

  Future<void> prescrire(Map<String, dynamic> corps) async {
    await _ds.prescrire(corps);
    _ref.invalidate(traitementsProvider);
  }

  /// Ouvre (ou crée) le fil de discussion privé avec [participantId].
  Future<Conversation> ouvrirConversationAvec(String participantId, {String? patientContexteId}) {
    return _ds.creerOuObtenirConversation(participantId, _monIdActuel, patientContexteId: patientContexteId);
  }

  Future<void> envoyerMessage(String conversationId, String contenu) async {
    await _ds.envoyerMessage(conversationId, contenu, _monIdActuel);
    _ref.invalidate(medecinMessagesProvider(conversationId));
    _ref.invalidate(medecinConversationsProvider);
  }

  Future<void> marquerConversationLue(String conversationId) async {
    await _ds.marquerConversationLue(conversationId);
    _ref.invalidate(medecinConversationsProvider);
  }
}

final medecinActionsProvider = Provider<MedecinActions>((ref) {
  return MedecinActions(ref);
});
