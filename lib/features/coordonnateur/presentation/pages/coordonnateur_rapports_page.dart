import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Validation des rapports d'intervention rédigés par les AVS : le
/// coordonnateur peut filtrer par statut puis valider ou rejeter chaque
/// rapport en attente.
class CoordonnateurRapportsPage extends ConsumerStatefulWidget {
  const CoordonnateurRapportsPage({super.key});

  @override
  ConsumerState<CoordonnateurRapportsPage> createState() => _CoordonnateurRapportsPageState();
}

class _CoordonnateurRapportsPageState extends ConsumerState<CoordonnateurRapportsPage> {
  StatutRapport? _filtre; // null = tous

  @override
  Widget build(BuildContext context) {
    final rapports = ref.watch(rapportsListProvider);
    final avsListe = ref.watch(avsListProvider);
    final patients = ref.watch(patientsListProvider);
    final enAttente = ref.watch(rapportsEnAttenteProvider);

    final filtres = _filtre == null ? rapports : rapports.where((r) => r.statut == _filtre).toList();

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Rapports',
          subtitle: '$enAttente rapport(s) en attente de validation',
          leadingIcon: Icons.fact_check_outlined,
          actions: [
            HeaderAction(
              icon: Icons.filter_list,
              tooltip: 'Filtrer',
              onTap: () => _ouvrirFiltre(context),
            ),
          ],
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FiltreChip(label: 'Tous', selectionne: _filtre == null, onTap: () => setState(() => _filtre = null)),
                const SizedBox(width: 8),
                for (final statut in StatutRapport.values) ...[
                  _FiltreChip(
                    label: statut.libelle,
                    selectionne: _filtre == statut,
                    onTap: () => setState(() => _filtre = statut),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: filtres.isEmpty
              ? Center(child: Text('Aucun rapport', style: Theme.of(context).textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: filtres.length,
                  itemBuilder: (context, index) {
                    final rapport = filtres[index];
                    final avs = _trouverAvs(avsListe, rapport.avsId);
                    final patient = _trouverPatient(patients, rapport.patientId);
                    return _RapportCard(rapport: rapport, avs: avs, patient: patient);
                  },
                ),
        ),
      ],
    );
  }

  void _ouvrirFiltre(BuildContext context) {
    context.showInfo('Utilisez les filtres sous le titre pour trier les rapports.');
  }

  Avs? _trouverAvs(List<Avs> liste, String id) {
    for (final a in liste) {
      if (a.id == id) return a;
    }
    return null;
  }

  Patient? _trouverPatient(List<Patient> liste, String id) {
    for (final p in liste) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool selectionne;
  final VoidCallback onTap;

  const _FiltreChip({required this.label, required this.selectionne, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectionne,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primarySurface,
      labelStyle: TextStyle(
        color: selectionne ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selectionne ? FontWeight.w600 : FontWeight.w400,
      ),
      backgroundColor: AppColors.surfaceMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill), side: BorderSide.none),
    );
  }
}

class _RapportCard extends ConsumerWidget {
  final RapportAvs rapport;
  final Avs? avs;
  final Patient? patient;

  const _RapportCard({required this.rapport, required this.avs, required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(nomComplet: avs?.nomComplet ?? '?'),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(avs?.nomComplet ?? 'AVS inconnu', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Patient : ${patient?.nomComplet ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(rapport.resume),
          const SizedBox(height: 4),
          Text(
            _formaterDate(rapport.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (rapport.statut == StatutRapport.enAttente) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(rapportsListProvider.notifier).mettreAJourStatut(rapport.id, StatutRapport.rejete);
                      context.showInfo('Rapport rejeté.');
                    },
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Rejeter', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(rapportsListProvider.notifier).mettreAJourStatut(rapport.id, StatutRapport.valide);
                      context.showInfo('Rapport validé.');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formaterDate(DateTime date) {
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}
