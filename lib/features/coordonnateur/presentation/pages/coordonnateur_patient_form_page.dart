import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';

/// Page plein écran (ouverte depuis le menu d'actions rapides ou depuis la
/// page Patients) : formulaire de création d'un patient.
class CoordonnateurPatientFormPage extends ConsumerStatefulWidget {
  const CoordonnateurPatientFormPage({super.key});

  @override
  ConsumerState<CoordonnateurPatientFormPage> createState() => _CoordonnateurPatientFormPageState();
}

class _CoordonnateurPatientFormPageState extends ConsumerState<CoordonnateurPatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _age = TextEditingController();
  final _adresse = TextEditingController();
  final _pathologie = TextEditingController();

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _age.dispose();
    _adresse.dispose();
    _pathologie.dispose();
    super.dispose();
  }

  String? _requis(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(patientsListProvider.notifier).ajouter(
          Patient(
            id: 'pat_${DateTime.now().millisecondsSinceEpoch}',
            nom: _nom.text.trim(),
            prenom: _prenom.text.trim(),
            age: int.tryParse(_age.text.trim()) ?? 0,
            adresse: _adresse.text.trim(),
            pathologie: _pathologie.text.trim(),
          ),
        );

    context.showInfo('Patient ajouté avec succès.');
    Navigator.of(context).maybePop();
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
            AppTextField(
              controller: _age,
              label: 'Âge',
              keyboardType: TextInputType.number,
              validator: _requis,
              textInputAction: TextInputAction.next,
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
              controller: _pathologie,
              label: 'Pathologie / besoin principal',
              validator: _requis,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: 'Enregistrer le patient', onPressed: _enregistrer),
          ],
        ),
      ),
    );
  }
}
