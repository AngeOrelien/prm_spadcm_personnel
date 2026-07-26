import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

extension _StatutPresenceX on StatutPresenceCoordonnateur {
  String get libelle => switch (this) {
    StatutPresenceCoordonnateur.present => 'Présent',
    StatutPresenceCoordonnateur.retard => 'En retard',
    StatutPresenceCoordonnateur.absent => 'Absent',
  };

  Color get couleur => switch (this) {
    StatutPresenceCoordonnateur.present => AppColors.success,
    StatutPresenceCoordonnateur.retard => AppColors.warning,
    StatutPresenceCoordonnateur.absent => AppColors.error,
  };
}

/// Historique de présence/check-in d'un AVS précis : statut du jour
/// (présent / en retard / absent) puis l'historique des derniers jours,
/// avec heures de check-in/check-out. Alimenté par `GET /api/presences`
/// filtré par `avsId` (voir `presenceController.js`).
class CoordonnateurCheckinDetailPage extends ConsumerWidget {
  final String avsId;

  const CoordonnateurCheckinDetailPage({super.key, required this.avsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avsListeAsync = ref.watch(avsListProvider);
    final presencesAsync = ref.watch(presencesDeLavsProvider(avsId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: Text(
          avsListeAsync.whenOrNull(
                data: (liste) {
                  for (final a in liste) {
                    if (a.id == avsId) return a.nomComplet;
                  }
                  return null;
                },
              ) ??
              'Historique de présence',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(presencesDeLavsProvider(avsId)),
        child: presencesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Impossible de charger l\'historique.', textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(onPressed: () => ref.invalidate(presencesDeLavsProvider(avsId)), child: const Text('Réessayer')),
                ],
              ),
            ),
          ),
          data: (presences) {
            if (presences.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text('Aucun historique de présence pour le moment.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ],
              );
            }
            final trie = [...presences]..sort((a, b) => b.date.compareTo(a.date));
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: trie.length,
              itemBuilder: (context, index) => _PresenceLigne(presence: trie[index]),
            );
          },
        ),
      ),
    );
  }
}

class _PresenceLigne extends StatelessWidget {
  final PresenceAvs presence;

  const _PresenceLigne({required this.presence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: presence.statut.couleur.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.location_on_outlined, color: presence.statut.couleur, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formaterDate(presence.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (presence.heureCheckIn != null) 'Entrée ${_formaterHeure(presence.heureCheckIn!)}',
                    if (presence.heureCheckOut != null) 'Sortie ${_formaterHeure(presence.heureCheckOut!)}',
                  ].isEmpty
                      ? 'Aucun check-in enregistré'
                      : [
                          if (presence.heureCheckIn != null) 'Entrée ${_formaterHeure(presence.heureCheckIn!)}',
                          if (presence.heureCheckOut != null) 'Sortie ${_formaterHeure(presence.heureCheckOut!)}',
                        ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusChip(label: presence.statut.libelle, couleur: presence.statut.couleur),
        ],
      ),
    );
  }

  String _formaterDate(DateTime date) {
    const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _formaterHeure(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
