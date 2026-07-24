import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
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

class AdministrateurActions {
  final Ref _ref;

  AdministrateurActions(this._ref);

  AdministrateurRemoteDataSource get _ds => _ref.read(administrateurRemoteDataSourceProvider);

  Future<void> creerUtilisateur(Map<String, dynamic> corps) async {
    await _ds.creerUtilisateur(corps);
    _ref.invalidate(utilisateursListProvider);
  }

  Future<void> basculerActivation(String id, bool actif) async {
    await _ds.basculerActivation(id, actif);
    _ref.invalidate(utilisateursListProvider);
  }

  Future<String> exporterStatistiquesPdf() => _ds.exporterStatistiquesPdf();
}

final administrateurActionsProvider = Provider<AdministrateurActions>((ref) {
  return AdministrateurActions(ref);
});
