import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/administrateur_providers.dart';

/// Onglet "Messagerie" de l'administrateur : fil épinglé avec l'assistant IA
/// de SPAD (même présentation que côté AVS, voir `AvsMessagesPage`), puis
/// les conversations avec les AVS, les médecins, les coordonnateurs et les
/// patients/familles.
///
/// Contrairement aux autres rôles, l'administrateur peut communiquer avec
/// TOUT LE MONDE dans l'application — `GET /utilisateurs/role/:role` lui est
/// ouvert côté backend pour chacun de ces rôles (voir
/// `AdministrateurRemoteDataSource.listerPersonnelParRole`).
class AdministrateurMessageriePage extends ConsumerStatefulWidget {
  const AdministrateurMessageriePage({super.key});

  @override
  ConsumerState<AdministrateurMessageriePage> createState() => _AdministrateurMessageriePageState();
}

class _AdministrateurMessageriePageState extends ConsumerState<AdministrateurMessageriePage> {
  String? _idEnCoursDouverture;

  Future<void> _ouvrirConversation(String participantId, String nom, String sousTitre) async {
    if (_idEnCoursDouverture != null) return;
    setState(() => _idEnCoursDouverture = participantId);
    try {
      final conversation = await ref.read(administrateurActionsProvider).ouvrirConversationAvec(participantId);
      if (!mounted) return;
      context.push(
        AppRoutes.administrateurMessagerieConversation(conversation.id),
        extra: {'conversationId': conversation.id, 'nom': nom, 'sousTitre': sousTitre},
      );
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _idEnCoursDouverture = null);
    }
  }

  void _rafraichirTout() {
    ref.invalidate(personnelAnnuaireProvider('avs'));
    ref.invalidate(personnelAnnuaireProvider('medecin'));
    ref.invalidate(personnelAnnuaireProvider('coordonnateur'));
    ref.invalidate(personnelAnnuaireProvider('patient'));
    ref.invalidate(administrateurConversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final avsAsync = ref.watch(personnelAnnuaireProvider('avs'));
    final medecinsAsync = ref.watch(personnelAnnuaireProvider('medecin'));
    final coordonnateursAsync = ref.watch(personnelAnnuaireProvider('coordonnateur'));
    final patientsAsync = ref.watch(personnelAnnuaireProvider('patient'));
    final conversationsAsync = ref.watch(administrateurConversationsProvider);
    final conversations = conversationsAsync.whenOrNull(data: (v) => v) ?? const <Conversation>[];

    String? dernierMessageAvec(String participantId) {
      for (final c in conversations) {
        if (c.interlocuteurId == participantId) return c.dernierMessage;
      }
      return null;
    }

    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Messagerie',
          subtitle: 'Toute l\'équipe et les familles',
          leadingIcon: Icons.forum_outlined,
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _rafraichirTout(),
            child: ScrollRefreshListener(
              onAtteintLeBas: _rafraichirTout,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _TuileIaEpinglee(onTap: () => context.push(AppRoutes.administrateurMessagerieIa)),
                  const Divider(height: AppSpacing.lg),
                  _SectionAnnuaire(
                    titre: 'AVS',
                    async: avsAsync,
                    couleur: AppColors.roleAvs,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id, p.nomComplet, 'Agent AVS'),
                  ),
                  _SectionAnnuaire(
                    titre: 'Médecins',
                    async: medecinsAsync,
                    couleur: AppColors.roleMedecin,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id, p.nomComplet, 'Médecin'),
                  ),
                  _SectionAnnuaire(
                    titre: 'Coordonnateurs',
                    async: coordonnateursAsync,
                    couleur: AppColors.roleCoordonnateur,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id, p.nomComplet, 'Coordonnateur'),
                  ),
                  _SectionAnnuaire(
                    titre: 'Patients / Familles',
                    async: patientsAsync,
                    couleur: AppColors.primary,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id, p.nomComplet, 'Patient / famille'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TuileIaEpinglee extends StatelessWidget {
  final VoidCallback onTap;

  const _TuileIaEpinglee({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.smart_toy_outlined, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(EnvConfig.aiAssistantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          const SizedBox(width: 6),
                          const Icon(Icons.push_pin, size: 12, color: AppColors.accent),
                        ],
                      ),
                      const Text('Assistant IA · toujours disponible', maxLines: 1, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionAnnuaire extends StatelessWidget {
  final String titre;
  final AsyncValue<List<PersonnelAnnuaire>> async;
  final Color couleur;
  final String? Function(String) dernierMessageAvec;
  final String? idEnCoursDouverture;
  final void Function(PersonnelAnnuaire) onOuvrir;

  const _SectionAnnuaire({
    required this.titre,
    required this.async,
    required this.couleur,
    required this.dernierMessageAvec,
    required this.idEnCoursDouverture,
    required this.onOuvrir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(titre: titre),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Non disponible pour le moment.', style: Theme.of(context).textTheme.bodySmall),
          ),
          data: (liste) => liste.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Aucun contact dans cette catégorie.', style: Theme.of(context).textTheme.bodySmall),
                )
              : Column(
                  children: [
                    for (final p in liste)
                      _TuileContact(
                        nom: p.nomComplet,
                        sousTitre: dernierMessageAvec(p.id) ?? titre,
                        photoUrl: p.photoUrl,
                        couleur: couleur,
                        chargement: idEnCoursDouverture == p.id,
                        onTap: () => onOuvrir(p),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TuileContact extends StatelessWidget {
  final String nom;
  final String sousTitre;
  final String? photoUrl;
  final Color couleur;
  final bool chargement;
  final VoidCallback onTap;

  const _TuileContact({
    required this.nom,
    required this.sousTitre,
    required this.photoUrl,
    required this.couleur,
    required this.chargement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: InitialsAvatar(nomComplet: nom, couleur: couleur, photoUrl: photoUrl),
      title: Text(nom, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sousTitre, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: chargement
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
