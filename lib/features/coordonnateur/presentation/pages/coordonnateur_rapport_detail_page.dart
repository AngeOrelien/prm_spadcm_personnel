import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Fiche détail plein écran d'un rapport d'intervention AVS : compte-rendu
/// complet, AVS et patient concernés, et actions de validation/rejet quand
/// le rapport est encore en attente. Remplace l'ancien aperçu en bottom
/// sheet de `coordonnateur_rapports_page.dart` par une vraie page, pour
/// correspondre au même traitement que les fiches patient/AVS.
class CoordonnateurRapportDetailPage extends ConsumerStatefulWidget {
  final String rapportId;

  const CoordonnateurRapportDetailPage({super.key, required this.rapportId});

  @override
  ConsumerState<CoordonnateurRapportDetailPage> createState() => _CoordonnateurRapportDetailPageState();
}

class _CoordonnateurRapportDetailPageState extends ConsumerState<CoordonnateurRapportDetailPage> {
  bool _enCours = false;

  Future<void> _valider(RapportAvs rapport) async {
    setState(() => _enCours = true);
    try {
      await ref.read(coordonnateurActionsProvider).validerRapport(rapport.id);
      if (!mounted) return;
      context.showInfo('Rapport validé.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _rejeter(RapportAvs rapport) async {
    final motifCtrl = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rejeter ce rapport ?'),
        content: TextField(
          controller: motifCtrl,
          decoration: const InputDecoration(labelText: 'Motif du rejet (optionnel)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _enCours = true);
    try {
      await ref.read(coordonnateurActionsProvider).rejeterRapport(rapport.id, motif: motifCtrl.text.trim());
      if (!mounted) return;
      context.showInfo('Rapport rejeté.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rapportsAsync = ref.watch(rapportsListProvider);
    final avsAsync = ref.watch(avsListProvider);
    final patientsAsync = ref.watch(patientsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Rapport d\'intervention'),
      ),
      body: rapportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _Erreur(onReessayer: () => ref.invalidate(rapportsListProvider)),
        data: (rapports) {
          RapportAvs? rapport;
          for (final r in rapports) {
            if (r.id == widget.rapportId) {
              rapport = r;
              break;
            }
          }
          if (rapport == null) {
            return const Center(child: Text('Rapport introuvable.'));
          }

          final avsListe = avsAsync.whenOrNull(data: (v) => v) ?? const <Avs>[];
          final patients = patientsAsync.whenOrNull(data: (v) => v) ?? const <Patient>[];
          Avs? avs;
          for (final a in avsListe) {
            if (a.id == rapport.avsId) {
              avs = a;
              break;
            }
          }
          Patient? patient;
          for (final p in patients) {
            if (p.id == rapport.patientId) {
              patient = p;
              break;
            }
          }

          return _Contenu(
            rapport: rapport,
            avs: avs,
            patient: patient,
            enCours: _enCours,
            onValider: () => _valider(rapport!),
            onRejeter: () => _rejeter(rapport!),
          );
        },
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  final RapportAvs rapport;
  final Avs? avs;
  final Patient? patient;
  final bool enCours;
  final VoidCallback onValider;
  final VoidCallback onRejeter;

  const _Contenu({
    required this.rapport,
    required this.avs,
    required this.patient,
    required this.enCours,
    required this.onValider,
    required this.onRejeter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  InitialsAvatar(nomComplet: avs?.nomComplet ?? '?', couleur: AppColors.roleAvs, photoUrl: avs?.photoUrl, radius: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(avs?.nomComplet ?? 'AVS inconnu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
                        Text('Patient : ${patient?.nomComplet ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(_formaterDate(rapport.date), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Compte-rendu de la visite', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
              const SizedBox(height: AppSpacing.sm),
              Text(rapport.resume, style: Theme.of(context).textTheme.bodyLarge),
              if (rapport.statut == StatutRapport.rejete && rapport.motifRejet != null && rapport.motifRejet!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text('Motif du rejet : ${rapport.motifRejet}', style: const TextStyle(color: AppColors.error)),
                ),
              ],
              if (patient != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                SectionTitle(titre: 'Patient concerné'),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(nomComplet: patient!.nomComplet, photoUrl: patient!.photoUrl),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient!.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(patient!.pathologie, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (rapport.statut == StatutRapport.enAttente)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: enCours ? null : onRejeter,
                      icon: const Icon(Icons.close, color: AppColors.error),
                      label: const Text('Rejeter', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: enCours ? null : onValider,
                      icon: enCours
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formaterDate(DateTime date) {
    const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

class _Erreur extends StatelessWidget {
  final VoidCallback onReessayer;

  const _Erreur({required this.onReessayer});

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
            const Text('Impossible de charger ce rapport.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
