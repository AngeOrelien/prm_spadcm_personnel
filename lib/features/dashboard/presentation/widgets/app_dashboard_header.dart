import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// En-tête commun à tous les dashboards (quel que soit le rôle) :
///   - à gauche : avatar (initiales) + nom + rôle -> tape pour aller au profil
///   - à droite : 2 options -> Notifications et Paramètres (ce dernier ouvre
///     aussi la déconnexion, voir [RoleDashboardShell])
///
/// Volontairement "bête" (StatelessWidget, pas de logique métier) pour rester
/// réutilisable : toute la logique (aller au profil, ouvrir un menu...) est
/// injectée via les callbacks par l'écran parent.
class AppDashboardHeader extends StatelessWidget {
  final String nomComplet;
  final String libelleRole;
  final bool notificationsNonLues;
  final VoidCallback? onTapProfil;
  final VoidCallback? onTapNotifications;
  final VoidCallback? onTapParametres;

  const AppDashboardHeader({
    super.key,
    required this.nomComplet,
    required this.libelleRole,
    this.notificationsNonLues = false,
    this.onTapProfil,
    this.onTapNotifications,
    this.onTapParametres,
  });

  String get _initiales {
    final mots = nomComplet.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTapProfil,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      _initiales,
                      style: textTheme.titleLarge?.copyWith(color: AppColors.primary, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bonjour, $nomComplet',
                          style: textTheme.titleLarge?.copyWith(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(libelleRole, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            avecPastille: notificationsNonLues,
            tooltip: 'Notifications',
            onTap: onTapNotifications,
          ),
          const SizedBox(width: AppSpacing.xs),
          _HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Paramètres',
            onTap: onTapParametres,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool avecPastille;
  final VoidCallback? onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.avecPastille = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              if (avecPastille)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
