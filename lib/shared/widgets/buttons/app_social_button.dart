import 'package:flutter/material.dart';

/// Bouton générique de connexion via un fournisseur tiers (aujourd'hui
/// Google uniquement, mais réutilisable si un autre fournisseur est ajouté
/// plus tard) : logo + libellé, style outline pour se distinguer du bouton
/// principal.
class AppSocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
