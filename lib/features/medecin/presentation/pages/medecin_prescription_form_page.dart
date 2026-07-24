import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../providers/medecin_providers.dart';

class MedecinPrescriptionFormPage extends ConsumerStatefulWidget {
  const MedecinPrescriptionFormPage({super.key});

  @override
  ConsumerState<MedecinPrescriptionFormPage> createState() => _MedecinPrescriptionFormPageState();
}

class _MedecinPrescriptionFormPageState extends ConsumerState<MedecinPrescriptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientCtrl = TextEditingController();
  final _medicamentCtrl = TextEditingController();
  final _posologieCtrl = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _patientCtrl.dispose();
    _medicamentCtrl.dispose();
    _posologieCtrl.dispose();
    super.dispose();
  }

  Future<void> _prescrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await ref.read(medecinActionsProvider).prescrire({
        'patientNom': _patientCtrl.text.trim(),
        'medicament': _medicamentCtrl.text.trim(),
        'posologie': _posologieCtrl.text.trim(),
      });
      if (mounted) {
        context.showInfo('Prescription enregistrée.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('Échec de l\'enregistrement.');
    } finally {
      if (mounted) setState(() => _envoi = false);
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
        title: const Text('Nouvelle prescription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _patientCtrl,
              decoration: const InputDecoration(labelText: 'Patient'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _medicamentCtrl,
              decoration: const InputDecoration(labelText: 'Médicament'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _posologieCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Posologie'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _envoi ? null : _prescrire,
              child: _envoi
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
