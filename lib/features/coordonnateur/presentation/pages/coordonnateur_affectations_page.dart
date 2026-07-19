import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Page plein écran (ouverte via le menu d'actions rapides ou depuis une
/// fiche patient/AVS) : créer une nouvelle affectation AVS ↔ patient, et
/// consulter les affectations déjà en place.
class CoordonnateurAffectationsPage extends ConsumerStatefulWidget {
  const CoordonnateurAffectationsPage({super.key});

  @override
  ConsumerState<CoordonnateurAffectationsPage> createState() => _CoordonnateurAffectationsPageState();
}

class _CoordonnateurAffectationsPageState extends ConsumerState<CoordonnateurAffectationsPage> {
  String? _patientId;
  String? _avsId;
  final _frequenceCtrl = TextEditingController(text: '3x / semaine');

  @override
  void dispose() {
    _frequenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientsListProvider);
    final avsListe = ref.watch(avsListProvider);
    final affectations = ref.watch(affectationsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Affectations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Nouvelle affectation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _patientId,
            decoration: const InputDecoration(labelText: 'Patient'),
            items: [
              for (final p in patients) DropdownMenuItem(value: p.id, child: Text(p.nomComplet)),
            ],
            onChanged: (v) => setState(() => _patientId = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _avsId,
            decoration: const InputDecoration(labelText: 'AVS'),
            items: [
              for (final a in avsListe)
                DropdownMenuItem(value: a.id, child: Text('${a.nomComplet} (${a.statut.libelle})')),
            ],
            onChanged: (v) => setState(() => _avsId = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _frequenceCtrl,
            decoration: const InputDecoration(labelText: 'Fréquence des visites'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_patientId == null || _avsId == null) ? null : _creerAffectation,
              icon: const Icon(Icons.check),
              label: const Text('Créer l\'affectation'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text('Affectations en cours', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          for (final affectation in affectations)
            _AffectationTile(
              affectation: affectation,
              patient: _trouverPatient(patients, affectation.patientId),
              avs: _trouverAvs(avsListe, affectation.avsId),
            ),
        ],
      ),
    );
  }

  void _creerAffectation() {
    final patientId = _patientId!;
    final avsId = _avsId!;

    ref.read(affectationsListProvider.notifier).ajouter(
          Affectation(
            id: 'aff_${DateTime.now().millisecondsSinceEpoch}',
            patientId: patientId,
            avsId: avsId,
            frequence: _frequenceCtrl.text.trim().isEmpty ? 'À définir' : _frequenceCtrl.text.trim(),
            depuisLe: DateTime.now(),
          ),
        );
    ref.read(patientsListProvider.notifier).assignerAvs(patientId, avsId);

    context.showInfo('Affectation créée avec succès.');
    setState(() {
      _patientId = null;
      _avsId = null;
    });
  }

  Patient? _trouverPatient(List<Patient> liste, String id) {
    for (final p in liste) {
      if (p.id == id) return p;
    }
    return null;
  }

  Avs? _trouverAvs(List<Avs> liste, String id) {
    for (final a in liste) {
      if (a.id == id) return a;
    }
    return null;
  }
}

class _AffectationTile extends StatelessWidget {
  final Affectation affectation;
  final Patient? patient;
  final Avs? avs;

  const _AffectationTile({required this.affectation, required this.patient, required this.avs});

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
          Icon(Icons.sync_alt, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patient?.nomComplet ?? '—'}  ↔  ${avs?.nomComplet ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(affectation.frequence, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
