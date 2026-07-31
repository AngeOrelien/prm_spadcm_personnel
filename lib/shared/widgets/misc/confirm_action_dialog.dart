import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Boîte de dialogue de confirmation générique, à utiliser pour TOUTE action
/// destructrice ou irréversible du système (suppression, désactivation de
/// compte, remboursement, annulation de souscription...), plutôt que de
/// laisser un `Switch`/bouton déclencher l'action directement.
///
/// Usage :
/// ```dart
/// final confirme = await ConfirmActionDialog.show(
///   context,
///   titre: 'Désactiver ce compte ?',
///   message: 'Fatou Ndiaye ne pourra plus se connecter à l\'application.',
///   libelleConfirmer: 'Désactiver',
///   destructif: true,
/// );
/// if (confirme == true) { ... }
/// ```
class ConfirmActionDialog extends StatelessWidget {
  final String titre;
  final String message;
  final String libelleConfirmer;
  final String libelleAnnuler;
  final bool destructif;
  final IconData? icone;

  const ConfirmActionDialog({
    super.key,
    required this.titre,
    required this.message,
    this.libelleConfirmer = 'Confirmer',
    this.libelleAnnuler = 'Annuler',
    this.destructif = true,
    this.icone,
  });

  /// Affiche le dialogue et retourne `true` si l'utilisateur a confirmé,
  /// `false`/`null` sinon (annulation, tap en dehors, retour arrière).
  static Future<bool?> show(
    BuildContext context, {
    required String titre,
    required String message,
    String libelleConfirmer = 'Confirmer',
    String libelleAnnuler = 'Annuler',
    bool destructif = true,
    IconData? icone,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmActionDialog(
        titre: titre,
        message: message,
        libelleConfirmer: libelleConfirmer,
        libelleAnnuler: libelleAnnuler,
        destructif: destructif,
        icone: icone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final couleurAccent = destructif ? AppColors.error : AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: couleurAccent.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icone ?? (destructif ? Icons.warning_amber_rounded : Icons.help_outline), color: couleurAccent),
      ),
      title: Text(titre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.35)),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(libelleAnnuler, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: couleurAccent),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(libelleConfirmer),
        ),
      ],
    );
  }
}
