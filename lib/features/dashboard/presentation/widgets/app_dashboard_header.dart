import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/domain/entities/personnel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../router/app_routes.dart';

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

/// Chemin de la page profil pour un rôle donné. Centralisé ici pour que le
/// menu à trois points (voir plus bas) fonctionne pour TOUS les rôles sans
/// que chaque page ait à s'en soucier.
String _profilRoutePour(RolePersonnel role) {
  switch (role) {
    case RolePersonnel.avs:
      return AppRoutes.avsProfil;
    case RolePersonnel.medecin:
      return AppRoutes.medecinProfil;
    case RolePersonnel.coordonnateur:
      return AppRoutes.coordonnateurProfil;
    case RolePersonnel.administrateur:
      return AppRoutes.administrateurProfil;
  }
}

/// En-tête réutilisable, générique à TOUS les rôles (AVS, Médecin,
/// Coordonnateur, Administrateur) et personnalisable page par page.
///
/// Style imposé, identique partout : fond dans une variante de la couleur
/// primaire de l'app, texte et icônes en clair (blanc) pour contraster —
/// voir [AppColors.primary] / [AppColors.primaryDark].
///
/// Deux modes :
///  - [showGreeting] = true  -> mode "accueil" : avatar (initiales) + "Bonjour,
///    Nom" + rôle, comme avant. Tape sur l'avatar -> profil.
///  - [showGreeting] = false -> mode "page" : simple titre (+ sous-titre
///    optionnel), ex. "Patients" / "24 patients suivis".
///
/// Dans les deux cas, la liste [actions] à droite est libre, et un bouton
/// "⋮" (trois points, façon WhatsApp) est TOUJOURS affiché en dernier :
/// il ouvre un menu générique (Mon profil / Déconnexion), ce qui permet de
/// sortir des fonctionnalités secondaires de la bottom navigation sans que
/// chaque page ait à le redéclarer.
class AppDashboardHeader extends ConsumerWidget {
  final bool showGreeting;
  final String? nomComplet;
  final String? libelleRole;
  final VoidCallback? onTapProfil;

  final String? title;
  final String? subtitle;
  final IconData? leadingIcon;

  final List<HeaderAction> actions;
  final bool showBackButton;

  const AppDashboardHeader.greeting({
    super.key,
    required this.nomComplet,
    required this.libelleRole,
    this.onTapProfil,
    this.actions = const [],
    this.showBackButton = false,
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
    this.showBackButton = false,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final personnel = ref.watch(authControllerProvider).value;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Row(
            children: [
              if (showBackButton) ...[
                _HeaderIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Retour',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
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
              const SizedBox(width: AppSpacing.xs),
              _OverflowMenuButton(personnel: personnel),
            ],
          ),
        ),
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
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              _initiales,
              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 16),
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
                  style: textTheme.titleLarge?.copyWith(fontSize: 16, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(libelleRole ?? '', style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85))),
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, size: 20, color: Colors.white),
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
                style: textTheme.titleLarge?.copyWith(fontSize: 20, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85)),
                  overflow: TextOverflow.ellipsis,
                ),
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
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22, color: Colors.white),
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

/// Bouton "⋮" façon WhatsApp : ouvre un menu générique valable pour tous les
/// rôles (Mon profil / Déconnexion). C'est ce qui permet de retirer "Profil"
/// de la bottom navigation sans perdre l'accès à la page.
class _OverflowMenuButton extends ConsumerWidget {
  final Personnel? personnel;

  const _OverflowMenuButton({required this.personnel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        tooltip: 'Plus d\'options',
        icon: const Icon(Icons.more_vert, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        onSelected: (valeur) => _onSelected(context, ref, valeur),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'profil',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline, color: AppColors.textPrimary),
              title: Text('Mon profil'),
            ),
          ),
          const PopupMenuItem(
            value: 'deconnexion',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Déconnexion', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, WidgetRef ref, String valeur) {
    if (personnel == null) return;
    switch (valeur) {
      case 'profil':
        context.push(_profilRoutePour(personnel!.role));
        break;
      case 'deconnexion':
        _confirmerDeconnexion(context, ref);
        break;
    }
  }

  void _confirmerDeconnexion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Se déconnecter ?'),
          content: const Text('Vous devrez vous reconnecter pour accéder à nouveau à l\'app.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authControllerProvider.notifier).deconnecter();
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }
}
