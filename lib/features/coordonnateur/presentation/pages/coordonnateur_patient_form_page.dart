import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../providers/coordonnateur_providers.dart';

/// Page plein écran (ouverte depuis le menu d'actions rapides ou depuis la
/// page Patients) : formulaire de création d'un patient, branché sur
/// `POST /api/patients`.
class CoordonnateurPatientFormPage extends ConsumerStatefulWidget {
  const CoordonnateurPatientFormPage({super.key});

  @override
  ConsumerState<CoordonnateurPatientFormPage> createState() => _CoordonnateurPatientFormPageState();
}

class _CoordonnateurPatientFormPageState extends ConsumerState<CoordonnateurPatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _adresse = TextEditingController();
  final _pathologie = TextEditingController();
  final _telephone = TextEditingController();
  final _antecedentCtrl = TextEditingController();
  final _allergieCtrl = TextEditingController();
  final _mobiliteCtrl = TextEditingController();

  DateTime? _dateNaissance;
  final List<String> _antecedents = [];
  final List<String> _allergies = [];
  final List<String> _difficultesMobilite = [];
  bool _enregistrement = false;

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _adresse.dispose();
    _pathologie.dispose();
    _telephone.dispose();
    _antecedentCtrl.dispose();
    _allergieCtrl.dispose();
    _mobiliteCtrl.dispose();
    super.dispose();
  }

  String? _requis(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  Future<void> _choisirDateNaissance() async {
    final aujourdHui = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(aujourdHui.year - 70),
      firstDate: DateTime(1900),
      lastDate: aujourdHui,
      helpText: 'Date de naissance',
    );
    if (date != null) setState(() => _dateNaissance = date);
  }

  void _ajouterAntecedent() {
    final valeur = _antecedentCtrl.text.trim();
    if (valeur.isEmpty) return;
    setState(() {
      _antecedents.add(valeur);
      _antecedentCtrl.clear();
    });
  }

  void _ajouterAllergie() {
    final valeur = _allergieCtrl.text.trim();
    if (valeur.isEmpty) return;
    setState(() {
      _allergies.add(valeur);
      _allergieCtrl.clear();
    });
  }

  void _ajouterDifficulteMobilite() {
    final valeur = _mobiliteCtrl.text.trim();
    if (valeur.isEmpty) return;
    setState(() {
      _difficultesMobilite.add(valeur);
      _mobiliteCtrl.clear();
    });
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enregistrement = true);
    try {
      await ref.read(coordonnateurActionsProvider).ajouterPatient(
            nom: _nom.text.trim(),
            prenom: _prenom.text.trim(),
            dateNaissance: _dateNaissance,
            adresse: _adresse.text.trim(),
            pathologie: _pathologie.text.trim(),
            antecedents: _antecedents,
            allergies: _allergies,
            difficultesMobilite: _difficultesMobilite,
            telephone: _telephone.text.trim().isEmpty ? null : _telephone.text.trim(),
          );
      if (!mounted) return;
      context.showInfo('Patient ajouté avec succès.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Ajouter un patient'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(controller: _prenom, label: 'Prénom', validator: _requis, textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _nom, label: 'Nom', validator: _requis, textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _choisirDateNaissance,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date de naissance'),
                child: Text(
                  _dateNaissance == null ? 'Sélectionner une date' : _formaterDate(_dateNaissance!),
                  style: TextStyle(color: _dateNaissance == null ? AppColors.textDisabled : AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _adresse,
              label: 'Adresse',
              validator: _requis,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _telephone,
              label: 'Téléphone (optionnel)',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _pathologie,
              label: 'Pathologie / besoin principal',
              validator: _requis,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Antécédents médicaux', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.sm),
            _ChampAjoutTag(
              controller: _antecedentCtrl,
              hint: 'Ex : Diabète type 2',
              items: _antecedents,
              onAjouter: _ajouterAntecedent,
              onSupprimer: (i) => setState(() => _antecedents.removeAt(i)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Allergies', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.sm),
            _ChampAjoutTag(
              controller: _allergieCtrl,
              hint: 'Ex : Pénicilline',
              items: _allergies,
              onAjouter: _ajouterAllergie,
              onSupprimer: (i) => setState(() => _allergies.removeAt(i)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Difficultés de mobilité', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.sm),
            _ChampAjoutTag(
              controller: _mobiliteCtrl,
              hint: 'Ex : Fauteuil roulant',
              items: _difficultesMobilite,
              onAjouter: _ajouterDifficulteMobilite,
              onSupprimer: (i) => setState(() => _difficultesMobilite.removeAt(i)),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: _enregistrement ? 'Enregistrement…' : 'Enregistrer le patient',
              isLoading: _enregistrement,
              onPressed: _enregistrer,
            ),
          ],
        ),
      ),
    );
  }

  String _formaterDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ChampAjoutTag extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> items;
  final VoidCallback onAjouter;
  final ValueChanged<int> onSupprimer;

  const _ChampAjoutTag({
    required this.controller,
    required this.hint,
    required this.items,
    required this.onAjouter,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: hint),
                onSubmitted: (_) => onAjouter(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: onAjouter,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < items.length; i++)
                Chip(
                  label: Text(items[i]),
                  onDeleted: () => onSupprimer(i),
                  backgroundColor: AppColors.surfaceMuted,
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
