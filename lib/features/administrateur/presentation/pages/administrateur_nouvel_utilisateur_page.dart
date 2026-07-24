import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

/// Création d'un compte personnel (README §3.4) : l'admin choisit le rôle,
/// l'utilisateur reçoit ensuite un email pour sa première connexion OTP.
class AdministrateurNouvelUtilisateurPage extends ConsumerStatefulWidget {
  const AdministrateurNouvelUtilisateurPage({super.key});

  @override
  ConsumerState<AdministrateurNouvelUtilisateurPage> createState() => _AdministrateurNouvelUtilisateurPageState();
}

class _AdministrateurNouvelUtilisateurPageState extends ConsumerState<AdministrateurNouvelUtilisateurPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  RoleUtilisateur _role = RoleUtilisateur.avs;
  bool _envoi = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await ref.read(administrateurActionsProvider).creerUtilisateur({
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        if (_telephoneCtrl.text.trim().isNotEmpty) 'telephone': _telephoneCtrl.text.trim(),
        'role': _role.name,
      });
      if (mounted) {
        context.showInfo('Compte créé. Un email de première connexion a été envoyé.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('Échec de la création du compte.');
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
        title: const Text('Nouvel utilisateur'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Rôle', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final r in RoleUtilisateur.values.where((r) => r != RoleUtilisateur.patientFamille))
                  ChoiceChip(
                    label: Text(r.libelle),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _prenomCtrl,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _telephoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _envoi ? null : _creer,
              child: _envoi
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
