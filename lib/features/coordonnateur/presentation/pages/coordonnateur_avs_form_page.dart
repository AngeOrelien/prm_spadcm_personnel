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
/// page Équipe) : formulaire de création d'un agent AVS.
class CoordonnateurAvsFormPage extends ConsumerStatefulWidget {
  const CoordonnateurAvsFormPage({super.key});

  @override
  ConsumerState<CoordonnateurAvsFormPage> createState() => _CoordonnateurAvsFormPageState();
}

class _CoordonnateurAvsFormPageState extends ConsumerState<CoordonnateurAvsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _telephone = TextEditingController();

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _telephone.dispose();
    super.dispose();
  }

  String? _requis(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  void _enregistrer() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(avsListProvider.notifier).ajouter(
          Avs(
            id: 'avs_${DateTime.now().millisecondsSinceEpoch}',
            nom: _nom.text.trim(),
            prenom: _prenom.text.trim(),
            telephone: _telephone.text.trim(),
            statut: StatutAvs.disponible,
            patientsAssignes: 0,
          ),
        );

    context.showInfo('Agent AVS ajouté avec succès.');
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
        title: const Text('Ajouter un AVS'),
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
              controller: _telephone,
              label: 'Téléphone',
              keyboardType: TextInputType.phone,
              validator: _requis,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(label: 'Enregistrer l\'agent AVS', onPressed: _enregistrer),
          ],
        ),
      ),
    );
  }
}
