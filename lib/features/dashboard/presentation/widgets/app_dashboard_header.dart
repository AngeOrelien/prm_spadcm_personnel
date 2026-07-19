import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';

/// Une icône d'action à droite du header (notifications, paramètres,
/// recherche, filtre, ajout...). Chaque page choisit ses propres actions :
/// c'est ce qui rend le header "personnel" d'une page à l'autre plutôt que
/// strictement identique partout.
class HeaderAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool badge;

  const HeaderAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badge = false,
  });
}

/// En-tête réutilisable, mais personnalisable page par page.
///
/// Deux modes :
///  - [showGreeting] = true  -> mode "accueil" : avatar (initiales) + "Bonjour,
///    Nom" + rôle, comme avant. Tape sur l'avatar -> profil.
///  - [showGreeting] = false -> mode "page" : simple titre (+ sous-titre
///    optionnel), ex. "Patients" / "24 patients suivis".
///
/// Dans les deux cas, la liste [actions] à droite est libre : une page de
/// liste peut afficher une loupe + un "+", une page de rapports un filtre,
/// une page de profil une icône d'édition, etc.
class AppDashboardHeader extends StatelessWidget {
  final bool showGreeting;
  final String? nomComplet;
  final String? libelleRole;
  final VoidCallback? onTapProfil;

  final String? title;
  final String? subtitle;
  final IconData? leadingIcon;

  final List<HeaderAction> actions;

  const AppDashboardHeader.greeting({
    super.key,
    required this.nomComplet,
    required this.libelleRole,
    this.onTapProfil,
    this.actions = const [],
  })  : showGreeting = true,
        title = null,
        subtitle = null,
        leadingIcon = null;

  const AppDashboardHeader.page({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.actions = const [],
  })  : showGreeting = false,
        nomComplet = null,
        libelleRole = null,
        onTapProfil = null;

  String get _initiales {
    final nom = nomComplet ?? '';
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
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
            child: showGreeting ? _buildGreeting(textTheme) : _buildTitle(textTheme),
          ),
          for (final action in actions) ...[
            const SizedBox(width: AppSpacing.xs),
            _HeaderIconButton(
              icon: action.icon,
              tooltip: action.tooltip,
              avecPastille: action.badge,
              onTap: action.onTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGreeting(TextTheme textTheme) {
    return InkWell(
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
                  'Bonjour, ${nomComplet ?? ''}',
                  style: textTheme.titleLarge?.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(libelleRole ?? '', style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? '',
                style: textTheme.titleLarge?.copyWith(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(subtitle!, style: textTheme.bodySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
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
