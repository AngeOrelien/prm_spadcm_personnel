import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'ai_chat_sheet.dart';

/// Bouton flottant présent sur toutes les pages du dashboard (voir
/// `RoleDashboardShell`), qui ouvre le chat avec l'assistant IA de SPAD.
/// Positionné au-dessus de la bottom navigation, à droite pour ne pas
/// entrer en collision avec le [SideQuickActionsMenu] (bord gauche).
class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Material(
        color: AppColors.accent,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => ouvrirChatIa(context),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
