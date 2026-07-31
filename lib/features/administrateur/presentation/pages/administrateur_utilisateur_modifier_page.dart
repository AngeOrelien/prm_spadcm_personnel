import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../../shared/widgets/misc/confirm_action_dialog.dart';
import '../../data/models/administrateur_models.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';
import '../widgets/administrateur_widgets.dart';

/// Édition d'un compte personnel existant (nom, prénom, email, téléphone) et
/// point d'entrée vers sa suppression définitive — le rôle et le mot de
/// passe ne sont volontairement pas modifiables ici, voir
/// `UtilisateurModel.toUpdateJson`.
class AdministrateurUtilisateurModifierPage extends ConsumerStatefulWidget {
  final Utilisateur utilisateur;

  const AdministrateurUtilisateurModifierPage({super.key, required this.utilisateur});

  @override
  ConsumerState<AdministrateurUtilisateurModifierPage> createState() => _AdministrateurUtilisateurModifierPageState();
}

class _AdministrateurUtilisateurModifierPageState extends ConsumerState<AdministrateurUtilisateurModifierPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nomCtrl = TextEditingController(text: widget.utilisateur.nom);
  late final _prenomCtrl = TextEditingController(text: widget.utilisateur.prenom);
  late final _emailCtrl = TextEditingController(text: widget.utilisateur.email);
  late final _telephoneCtrl = TextEditingController(text: widget.utilisateur.telephone ?? '');
  bool _envoi = false;
  bool _suppression = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await ref.read(administrateurActionsProvider).modifierUtilisateur(
            widget.utilisateur.id,
            UtilisateurModel.toUpdateJson(
              nom: _nomCtrl.text.trim(),
              prenom: _prenomCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              telephone: _telephoneCtrl.text.trim(),
            ),
          );
      if (mounted) {
        context.showInfo('Compte mis à jour.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('Échec de la mise à jour du compte.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _supprimer() async {
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: 'Supprimer ce compte ?',
      message:
          '${widget.utilisateur.nomComplet} sera définitivement supprimé(e) et ne pourra plus se connecter. '
          'Cette action est irréversible.',
      libelleConfirmer: 'Supprimer',
      destructif: true,
      icone: Icons.delete_outline,
    );
    if (confirme != true) return;

    setState(() => _suppression = true);
    try {
      await ref.read(administrateurActionsProvider).supprimerUtilisateur(widget.utilisateur.id);
      if (mounted) {
        context.showInfo('Compte supprimé.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('Impossible de supprimer ce compte.');
    } finally {
      if (mounted) setState(() => _suppression = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.utilisateur;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Modifier le compte'),
        actions: [
          IconButton(
            icon: _suppression
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline),
            tooltip: 'Supprimer ce compte',
            onPressed: _suppression ? null : _supprimer,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                StatusChip(label: u.role.libelle, couleur: u.role.couleur),
                const SizedBox(width: AppSpacing.sm),
                StatusChip(
                  label: u.actif ? 'Actif' : 'Désactivé',
                  couleur: u.actif ? Colors.green : Colors.grey,
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
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _envoi ? null : _enregistrer,
              child: _envoi
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }
}
