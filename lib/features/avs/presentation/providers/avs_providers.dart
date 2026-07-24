import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../data/datasources/avs_remote_datasource.dart';
import '../../domain/entities/avs_entities.dart';

final avsRemoteDataSourceProvider = Provider<AvsRemoteDataSource>((ref) {
  return AvsRemoteDataSource(ref.watch(apiClientProvider));
});

/// Id du personnel AVS connecté. Conservé pour compatibilité des signatures,
/// mais sans effet sur les appels réels au backend : celui-ci identifie
/// toujours l'AVS via le JWT envoyé dans l'en-tête `Authorization`, jamais
/// via ce paramètre.
String _monIdAvs(Ref ref) => ref.watch(authControllerProvider).value?.id ?? 'avs-01';

/// Planning des visites (jour/semaine) de l'AVS connecté.
final monPlanningProvider = FutureProvider.autoDispose<List<VisitePlanifiee>>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).obtenirMonPlanning(avsId: _monIdAvs(ref));
});

/// Historique de mes rapports journaliers.
final mesRapportsProvider = FutureProvider.autoDispose<List<RapportAvs>>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).obtenirMesRapports(avsId: _monIdAvs(ref));
});

/// Présence (check-in/out) du jour.
final presenceDuJourProvider = FutureProvider.autoDispose<Presence?>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).presenceDuJour(avsId: _monIdAvs(ref));
});

/// Statistiques personnelles de ponctualité, affichées sur l'accueil/planning.
final mesStatistiquesProvider = FutureProvider.autoDispose<StatistiquesPonctualiteAvs>((ref) {
  return ref.watch(avsRemoteDataSourceProvider).mesStatistiques(avsId: _monIdAvs(ref));
});

class AvsActions {
  final Ref _ref;

  AvsActions(this._ref);

  AvsRemoteDataSource get _ds => _ref.read(avsRemoteDataSourceProvider);
  String get _avsId => _ref.read(authControllerProvider).value?.id ?? 'avs-01';

  Future<void> creerRapport(Map<String, dynamic> corps) async {
    await _ds.creerRapport(corps, avsId: _avsId);
    _ref.invalidate(mesRapportsProvider);
    _ref.invalidate(mesStatistiquesProvider);
  }

  Future<void> checkIn({required double latitude, required double longitude}) async {
    await _ds.checkIn(latitude: latitude, longitude: longitude, avsId: _avsId);
    _ref.invalidate(presenceDuJourProvider);
    _ref.invalidate(mesStatistiquesProvider);
  }

  Future<void> checkOut() async {
    await _ds.checkOut(avsId: _avsId);
    _ref.invalidate(presenceDuJourProvider);
    _ref.invalidate(mesStatistiquesProvider);
  }
}

final avsActionsProvider = Provider<AvsActions>((ref) {
  return AvsActions(ref);
});
