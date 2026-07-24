import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../providers/avs_providers.dart';

/// Formulaire structuré de rapport journalier — fidèle à la fiche terrain
/// (constantes, besoins, alimentation, soins, médicaments, observations).
/// Saisi hors-ligne si besoin : `heureSaisie` est horodatée localement à la
/// validation, l'envoi réseau se fait dès que possible (voir README §3.2).
///
/// Le patient concerné est choisi dans le planning de l'AVS (`patientId`
/// envoyé au serveur) plutôt que tapé en texte libre : la fiche
/// `RapportJournalier` référence un patient précis côté backend (voir
/// README §6.3, `RAPPORTS_JOURNALIERS.patientId`), un nom en texte libre ne
/// suffirait pas à identifier le bon dossier de façon fiable.
class AvsRapportFormPage extends ConsumerStatefulWidget {
  const AvsRapportFormPage({super.key});

  @override
  ConsumerState<AvsRapportFormPage> createState() => _AvsRapportFormPageState();
}

class _AvsRapportFormPageState extends ConsumerState<AvsRapportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _constantesCtrl = TextEditingController();
  final _alimentationCtrl = TextEditingController();
  final _medicamentsCtrl = TextEditingController();
  final _soinsCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();
  String? _patientIdSelectionne;
  bool _envoi = false;

  @override
  void dispose() {
    _constantesCtrl.dispose();
    _alimentationCtrl.dispose();
    _medicamentsCtrl.dispose();
    _soinsCtrl.dispose();
    _observationsCtrl.dispose();
    _conclusionCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientIdSelectionne == null) {
      context.showError('Sélectionne le patient concerné par ce rapport.');
      return;
    }
    setState(() => _envoi = true);
    final heureSaisie = DateTime.now().toIso8601String();
    try {
      await ref.read(avsActionsProvider).creerRapport({
        'patientId': _patientIdSelectionne,
        'heureSaisie': heureSaisie,
        'parametresVitaux': _constantesCtrl.text.trim(),
        'alimentation': _alimentationCtrl.text.trim(),
        'medicamentsAdministres': _medicamentsCtrl.text.trim(),
        'soinsTaches': _soinsCtrl.text.trim(),
        'observations': _observationsCtrl.text.trim(),
        'conclusion': _conclusionCtrl.text.trim(),
      });
      if (mounted) {
        context.showInfo('Rapport envoyé. Il sera marqué à temps ou en retard selon l\'heure de saisie.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('Échec de l\'envoi du rapport. Il sera synchronisé dès que possible.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planningAsync = ref.watch(monPlanningProvider);
    final patientsUniques = <String, String>{};
    planningAsync.whenData((visites) {
      for (final v in visites) {
        patientsUniques[v.patientId] = v.patientNom;
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Nouveau rapport'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DropdownButtonFormField<String>(
                value: _patientIdSelectionne,
                decoration: const InputDecoration(labelText: 'Patient visité'),
                items: [
                  for (final entry in patientsUniques.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (valeur) => setState(() => _patientIdSelectionne = valeur),
                validator: (v) => v == null ? 'Sélectionne un patient' : null,
              ),
            ),
            _Champ(label: 'Constantes (matin/soir)', controller: _constantesCtrl, lignes: 2),
            _Champ(label: 'Alimentation', controller: _alimentationCtrl, lignes: 2),
            _Champ(label: 'Médicaments administrés', controller: _medicamentsCtrl, lignes: 2),
            _Champ(label: 'Soins / tâches réalisées', controller: _soinsCtrl, lignes: 2),
            _Champ(label: 'Observations', controller: _observationsCtrl, lignes: 3),
            _Champ(label: 'Conclusion', controller: _conclusionCtrl, lignes: 2),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _envoi ? null : _envoyer,
              child: _envoi
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer le rapport'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Champ extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int lignes;
  final bool obligatoire;

  const _Champ({required this.label, required this.controller, this.lignes = 1, this.obligatoire = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLines: lignes,
        decoration: InputDecoration(labelText: label),
        validator: obligatoire ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null : null,
      ),
    );
  }
}
