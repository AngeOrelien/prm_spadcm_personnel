import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
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

class MedecinActions {
  final Ref _ref;

  MedecinActions(this._ref);

  Future<void> prescrire(Map<String, dynamic> corps) async {
    await _ref.read(medecinRemoteDataSourceProvider).prescrire(corps);
    _ref.invalidate(traitementsProvider);
  }
}

final medecinActionsProvider = Provider<MedecinActions>((ref) {
  return MedecinActions(ref);
});
