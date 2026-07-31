import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../../shared/widgets/misc/confirm_action_dialog.dart';
import '../../data/models/administrateur_models.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

String _fmtDate(DateTime? d) => d == null ? '—' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Détail + édition back-office d'une souscription : dates, reconduction
/// automatique, statut, et actions de cycle de vie (annuler / terminer /
/// supprimer) — toutes irréversibles, donc toujours confirmées.
class AdministrateurSouscriptionDetailPage extends ConsumerStatefulWidget {
  final Souscription souscription;

  const AdministrateurSouscriptionDetailPage({super.key, required this.souscription});

  @override
  ConsumerState<AdministrateurSouscriptionDetailPage> createState() => _AdministrateurSouscriptionDetailPageState();
}

class _AdministrateurSouscriptionDetailPageState extends ConsumerState<AdministrateurSouscriptionDetailPage> {
  late Souscription _souscription = widget.souscription;
  late DateTime? _dateDebut = widget.souscription.dateDebut;
  late DateTime? _dateFin = widget.souscription.dateFin;
  late bool _renouvellementAuto = widget.souscription.renouvellementAuto;
  bool _envoi = false;

  Future<void> _choisirDate({required bool debut}) async {
    final initiale = (debut ? _dateDebut : _dateFin) ?? DateTime.now();
    final choisie = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (choisie == null) return;
    setState(() {
      if (debut) {
        _dateDebut = choisie;
      } else {
        _dateFin = choisie;
      }
    });
  }

  Future<void> _enregistrer() async {
    setState(() => _envoi = true);
    try {
      await ref.read(administrateurActionsProvider).modifierSouscription(
            _souscription.id,
            SouscriptionModel.toUpdateJson(
              dateDebut: _dateDebut,
              dateFin: _dateFin,
              renouvellementAuto: _renouvellementAuto,
            ),
          );
      if (mounted) context.showInfo('Souscription mise à jour.');
    } catch (e) {
      if (mounted) context.showError('Échec de la mise à jour.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _annuler() async {
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: 'Annuler cette souscription ?',
      message: 'La souscription de ${_souscription.patientNom} au soin "${_souscription.soinNom}" sera annulée. Cette action est irréversible.',
      libelleConfirmer: 'Annuler la souscription',
      destructif: true,
    );
    if (confirme != true) return;
    await _executerAction(() => ref.read(administrateurActionsProvider).annulerSouscription(_souscription.id), 'Souscription annulée.');
  }

  Future<void> _terminer() async {
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: 'Marquer comme terminée ?',
      message: 'La souscription de ${_souscription.patientNom} sera marquée comme résiliée/terminée. Cette action est irréversible.',
      libelleConfirmer: 'Terminer',
      destructif: true,
    );
    if (confirme != true) return;
    await _executerAction(() => ref.read(administrateurActionsProvider).terminerSouscription(_souscription.id), 'Souscription terminée.');
  }

  Future<void> _supprimer() async {
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: 'Supprimer définitivement ?',
      message:
          'Cette souscription sera définitivement supprimée de la base (housekeeping). Le paiement associé, lui, est conservé comme trace comptable. Cette action est irréversible.',
      libelleConfirmer: 'Supprimer',
      destructif: true,
      icone: Icons.delete_forever_outlined,
    );
    if (confirme != true) return;
    setState(() => _envoi = true);
    try {
      await ref.read(administrateurActionsProvider).supprimerSouscription(_souscription.id);
      if (mounted) {
        context.showInfo('Souscription supprimée.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('Échec de la suppression.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _executerAction(Future<void> Function() action, String messageSucces) async {
    setState(() => _envoi = true);
    try {
      await action();
      if (mounted) context.showInfo(messageSucces);
    } catch (e) {
      if (mounted) context.showError('Échec de l\'action.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _souscription;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Souscription'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Supprimer', onPressed: _envoi ? null : _supprimer),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(s.patientNom, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(s.soinNom, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusChip(label: s.statut.libelle, couleur: s.statut.couleur),
              if (s.montant != null) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusChip(label: '${s.montant!.toStringAsFixed(0)} XAF', couleur: AppColors.primary),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Souscripteur : ${s.souscripteurNom}', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          const Text('Édition back-office', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _choisirDate(debut: true),
                  child: Text('Début : ${_fmtDate(_dateDebut)}'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _choisirDate(debut: false),
                  child: Text('Fin : ${_fmtDate(_dateFin)}'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reconduction automatique'),
            value: _renouvellementAuto,
            onChanged: (v) => setState(() => _renouvellementAuto = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _envoi ? null : _enregistrer,
            child: const Text('Enregistrer les modifications'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          const Text('Actions de cycle de vie', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _envoi ? null : _annuler,
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Annuler'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              ),
              OutlinedButton.icon(
                onPressed: _envoi ? null : _terminer,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Terminer'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
