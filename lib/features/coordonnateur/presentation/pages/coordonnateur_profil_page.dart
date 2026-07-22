import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Page de gestion du profil du coordonnateur : informations personnelles,
/// sécurité, préférences de notification, et déconnexion.
///
/// Header en mode "titre" (pas de "Bonjour, X" ici puisque c'est déjà la
/// page de profil) avec une action d'édition à droite.
class CoordonnateurProfilPage extends ConsumerStatefulWidget {
  const CoordonnateurProfilPage({super.key});

  @override
  ConsumerState<CoordonnateurProfilPage> createState() => _CoordonnateurProfilPageState();
}

class _CoordonnateurProfilPageState extends ConsumerState<CoordonnateurProfilPage> {
  bool _notificationsActives = true;

  @override
  Widget build(BuildContext context) {
    final personnel = ref.watch(authControllerProvider).value;

    return Column(
      children: [
        AppDashboardHeader.page(
          title: 'Mon profil',
          leadingIcon: Icons.person_outline,
          showBackButton: true,
          actions: [
            HeaderAction(
              icon: Icons.edit_outlined,
              tooltip: 'Modifier mes informations',
              onTap: () => context.showInfo('Édition du profil bientôt disponible.'),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        _initiales(personnel?.nomComplet ?? ''),
                        style: const TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(personnel?.nomComplet ?? '', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    const StatusChip(label: 'Coordonnateur', couleur: AppColors.roleCoordonnateur),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(titre: 'Informations personnelles'),
              _CarteInfo(
                enfants: [
                  _LigneProfil(icon: Icons.email_outlined, label: 'Email', valeur: personnel?.email ?? '—'),
                  _LigneProfil(icon: Icons.phone_outlined, label: 'Téléphone', valeur: '+237 6•• •• •• ••'),
                  _LigneProfil(icon: Icons.badge_outlined, label: 'Rôle', valeur: 'Coordonnateur'),
                ],
              ),
              SectionTitle(titre: 'Préférences'),
              _CarteInfo(
                enfants: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notifications'),
                    subtitle: const Text('Rapports en attente, nouvelles affectations…'),
                    value: _notificationsActives,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _notificationsActives = v),
                  ),
                ],
              ),
              SectionTitle(titre: 'Sécurité'),
              _CarteInfo(
                enfants: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    title: const Text('Changer le mot de passe'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.showInfo('Changement de mot de passe bientôt disponible.'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmerDeconnexion(context, ref),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'PRM — Personnel · v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initiales(String nomComplet) {
    final mots = nomComplet.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }

  void _confirmerDeconnexion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Se déconnecter ?'),
          content: const Text('Vous devrez vous reconnecter avec votre email pour accéder à nouveau à l\'app.'),
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

class _CarteInfo extends StatelessWidget {
  final List<Widget> enfants;

  const _CarteInfo({required this.enfants});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: enfants),
    );
  }
}

class _LigneProfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;

  const _LigneProfil({required this.icon, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(valeur, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
