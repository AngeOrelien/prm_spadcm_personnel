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
    final rapportsAsync = ref.watch(rapportsListProvider);
    final avsAsync = ref.watch(avsListProvider);
    final patientsAsync = ref.watch(patientsListProvider);
    final enAttente = ref.watch(rapportsEnAttenteProvider);

    final avsListe = avsAsync.whenOrNull(data: (v) => v) ?? const <Avs>[];
    final patients = patientsAsync.whenOrNull(data: (v) => v) ?? const <Patient>[];

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Rapports',
          subtitle: '$enAttente rapport(s) en attente de validation',
          leadingIcon: Icons.fact_check_outlined,
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
          child: rapportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(rapportsListProvider)),
            data: (rapports) {
              final filtres = _filtre == null ? rapports : rapports.where((r) => r.statut == _filtre).toList();
              if (filtres.isEmpty) {
                return Center(child: Text('Aucun rapport', style: Theme.of(context).textTheme.bodyMedium));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                itemCount: filtres.length,
                itemBuilder: (context, index) {
                  final rapport = filtres[index];
                  final avs = _trouverAvs(avsListe, rapport.avsId);
                  final patient = _trouverPatient(patients, rapport.patientId);
                  return _RapportCard(rapport: rapport, avs: avs, patient: patient);
                },
              );
            },
          ),
        ),
      ],
    );
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

class _RapportCard extends ConsumerStatefulWidget {
  final RapportAvs rapport;
  final Avs? avs;
  final Patient? patient;

  const _RapportCard({required this.rapport, required this.avs, required this.patient});

  @override
  ConsumerState<_RapportCard> createState() => _RapportCardState();
}

class _RapportCardState extends ConsumerState<_RapportCard> {
  bool _enCours = false;

  Future<void> _valider() async {
    setState(() => _enCours = true);
    try {
      await ref.read(coordonnateurActionsProvider).validerRapport(widget.rapport.id);
      if (!mounted) return;
      context.showInfo('Rapport validé.');
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _rejeter() async {
    setState(() => _enCours = true);
    try {
      await ref.read(coordonnateurActionsProvider).rejeterRapport(widget.rapport.id);
      if (!mounted) return;
      context.showInfo('Rapport rejeté.');
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rapport = widget.rapport;
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
              InitialsAvatar(nomComplet: widget.avs?.nomComplet ?? '?'),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.avs?.nomComplet ?? 'AVS inconnu', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Patient : ${widget.patient?.nomComplet ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(rapport.resume),
          const SizedBox(height: 4),
          Text(_formaterDate(rapport.date), style: Theme.of(context).textTheme.bodySmall),
          if (rapport.statut == StatutRapport.enAttente) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _enCours ? null : _rejeter,
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Rejeter', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _enCours ? null : _valider,
                    icon: _enCours
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
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

class _ErreurChargement extends StatelessWidget {
  final VoidCallback onReessayer;

  const _ErreurChargement({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            const Text('Impossible de charger les rapports.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
