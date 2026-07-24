import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

/// Onglet "Paiements" : suivi des souscriptions et transactions (README §3.4).
class AdministrateurPaiementsPage extends ConsumerWidget {
  const AdministrateurPaiementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paiementsAsync = ref.watch(paiementsListProvider);

    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Paiements',
          subtitle: 'Souscriptions et transactions',
          leadingIcon: Icons.payments_outlined,
        ),
        const Divider(height: 1),
        Expanded(
          child: paiementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(paiementsListProvider)),
            data: (paiements) {
              if (paiements.isEmpty) {
                return const Center(
                  child: EmptyStateCard(
                    icon: Icons.payments_outlined,
                    titre: 'Aucun paiement',
                    message: 'Les paiements confirmés par les familles apparaîtront ici.',
                  ),
                );
              }
              final total = paiements.fold<double>(0, (s, p) => s + p.montant);
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(paiementsListProvider),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${paiements.length} transaction(s)', style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            '${total.toStringAsFixed(0)} FCFA',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    for (final p in paiements)
                      ListTile(
                        leading: Icon(Icons.receipt_long_outlined, color: p.statut.couleur),
                        title: Text(p.patientNom, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${p.soinLibelle} · ${p.date.day.toString().padLeft(2, '0')}/${p.date.month.toString().padLeft(2, '0')}/${p.date.year}'),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${p.montant.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            StatusChip(label: p.statut.libelle, couleur: p.statut.couleur),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
