import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../router/role_dashboards.dart';

/// Petit menu d'actions rapides sur le bord gauche de l'écran : un bouton
/// principal qui, une fois tapé, déplie verticalement jusqu'à 3 boutons
/// (un peu comme le bouton "+" de WhatsApp), chacun menant vers une page
/// précise. Un tap en dehors, ou sur le bouton principal à nouveau, referme
/// le menu.
///
/// N'apparaît que si le rôle courant a des [QuickAction] définies dans sa
/// [RoleDashboardConfig] (voir `router/role_dashboards.dart`).
class SideQuickActionsMenu extends StatefulWidget {
  final List<QuickAction> actions;

  const SideQuickActionsMenu({super.key, required this.actions});

  @override
  State<SideQuickActionsMenu> createState() => _SideQuickActionsMenuState();
}

class _SideQuickActionsMenuState extends State<SideQuickActionsMenu> with SingleTickerProviderStateMixin {
  bool _ouvert = false;

  void _toggle() => setState(() => _ouvert = !_ouvert);

  void _fermer() {
    if (_ouvert) setState(() => _ouvert = false);
  }

  void _onActionTap(QuickAction action) {
    _fermer();
    context.push(action.route);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // Scrim : capte les taps en dehors du menu pour le refermer.
        if (_ouvert)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _fermer,
              child: Container(color: Colors.black.withOpacity(0.18)),
            ),
          ),
        Positioned(
          left: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = widget.actions.length - 1; i >= 0; i--)
                _AnimatedActionItem(
                  ouvert: _ouvert,
                  delayIndex: widget.actions.length - 1 - i,
                  action: widget.actions[i],
                  onTap: () => _onActionTap(widget.actions[i]),
                ),
              _MainToggleButton(ouvert: _ouvert, onTap: _toggle),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedActionItem extends StatelessWidget {
  final bool ouvert;
  final int delayIndex;
  final QuickAction action;
  final VoidCallback onTap;

  const _AnimatedActionItem({
    required this.ouvert,
    required this.delayIndex,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: ouvert ? Offset.zero : const Offset(0, 0.3),
      duration: Duration(milliseconds: 180 + delayIndex * 40),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: ouvert ? 1 : 0,
        duration: Duration(milliseconds: 150 + delayIndex * 40),
        child: IgnorePointer(
          ignoring: !ouvert,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.navBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.icon, size: 18, color: AppColors.navSelected),
                      const SizedBox(width: 8),
                      Text(
                        action.label,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainToggleButton extends StatelessWidget {
  final bool ouvert;
  final VoidCallback onTap;

  const _MainToggleButton({required this.ouvert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AnimatedRotation(
            turns: ouvert ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
