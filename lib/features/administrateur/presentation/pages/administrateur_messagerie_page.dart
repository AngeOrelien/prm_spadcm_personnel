import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/messagerie/messagerie_section_widgets.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../avs/domain/entities/avs_entities.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/administrateur_providers.dart';

/// Onglet "Messagerie" de l'administrateur : fil épinglé avec l'assistant IA
/// de SPAD, filtres par catégorie, puis les conversations groupées par type
/// d'interlocuteur — AVS, médecins, coordonnateurs, autres administrateurs
/// et patients/familles.
///
/// Widgets de présentation (tuile de contact, section groupée, filtres, fil
/// épinglé IA) mutualisés avec les autres rôles dans
/// `shared/widgets/messagerie/messagerie_section_widgets.dart`, pour que les
/// 4 onglets Messagerie (Administrateur, Coordonnateur, Médecin, AVS) restent
/// visuellement cohérents.
///
/// L'administrateur peut communiquer avec TOUT LE MONDE dans l'application,
/// sauf lui-même — `GET /utilisateurs/role/:role` lui est ouvert côté
/// backend pour chacun de ces rôles et s'auto-exclut désormais de sa propre
/// liste (voir `AdministrateurRemoteDataSource.listerPersonnelParRole` et
/// `utilisateurController.listerUtilisateursParRole`).
class AdministrateurMessageriePage extends ConsumerStatefulWidget {
  const AdministrateurMessageriePage({super.key});

  @override
  ConsumerState<AdministrateurMessageriePage> createState() => _AdministrateurMessageriePageState();
}

class _AdministrateurMessageriePageState extends ConsumerState<AdministrateurMessageriePage> {
  String? _idEnCoursDouverture;
  String? _filtreSelectionne;

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
    ref.invalidate(personnelAnnuaireProvider('administrateur'));
    ref.invalidate(personnelAnnuaireProvider('patient'));
    ref.invalidate(administrateurConversationsProvider);
  }

  static const _filtres = [
    FiltreMessagerie('avs', 'AVS'),
    FiltreMessagerie('medecin', 'Médecin'),
    FiltreMessagerie('coordonnateur', 'Coordonnateur'),
    FiltreMessagerie('administrateur', 'Administrateur'),
    FiltreMessagerie('patient', 'Patient / famille'),
  ];

  bool _visible(String cle) => _filtreSelectionne == null || _filtreSelectionne == cle;

  @override
  Widget build(BuildContext context) {
    final avsAsync = ref.watch(personnelAnnuaireProvider('avs'));
    final medecinsAsync = ref.watch(personnelAnnuaireProvider('medecin'));
    final coordonnateursAsync = ref.watch(personnelAnnuaireProvider('coordonnateur'));
    final administrateursAsync = ref.watch(personnelAnnuaireProvider('administrateur'));
    final patientsAsync = ref.watch(personnelAnnuaireProvider('patient'));
    final conversationsAsync = ref.watch(administrateurConversationsProvider);
    final conversations = conversationsAsync.whenOrNull(data: (v) => v) ?? const <Conversation>[];

    String? dernierMessageAvec(String participantId) {
      for (final c in conversations) {
        if (c.interlocuteurId == participantId) return c.dernierMessage;
      }
      return null;
    }

    Widget tuile(PersonnelAnnuaire p, String couleurTitre, Color couleur) => TuileContactMessagerie(
          nom: p.nomComplet,
          sousTitre: dernierMessageAvec(p.id) ?? couleurTitre,
          photoUrl: p.photoUrl,
          couleur: couleur,
          chargement: _idEnCoursDouverture == p.id,
          onTap: () => _ouvrirConversation(p.id, p.nomComplet, couleurTitre),
        );

    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Messagerie',
          subtitle: 'Toute l\'équipe et les familles',
          leadingIcon: Icons.forum_outlined,
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: FiltresRoleMessagerie(
            filtres: _filtres,
            selectionne: _filtreSelectionne,
            onChanged: (cle) => setState(() => _filtreSelectionne = cle),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _rafraichirTout(),
            child: ScrollRefreshListener(
              onAtteintLeBas: _rafraichirTout,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  if (_filtreSelectionne == null) ...[
                    TuileIaEpingleeMessagerie(
                      nomAssistant: EnvConfig.aiAssistantName,
                      onTap: () => context.push(AppRoutes.administrateurMessagerieIa),
                    ),
                    const Divider(height: AppSpacing.lg),
                  ],
                  if (_visible('avs'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'AVS',
                      async: avsAsync,
                      tuileBuilder: (p) => tuile(p, 'Agent AVS', AppColors.roleAvs),
                    ),
                  if (_visible('medecin'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Médecins',
                      async: medecinsAsync,
                      tuileBuilder: (p) => tuile(p, 'Médecin', AppColors.roleMedecin),
                    ),
                  if (_visible('coordonnateur'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Coordonnateurs',
                      async: coordonnateursAsync,
                      tuileBuilder: (p) => tuile(p, 'Coordonnateur', AppColors.roleCoordonnateur),
                    ),
                  if (_visible('administrateur'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Administrateurs',
                      async: administrateursAsync,
                      tuileBuilder: (p) => tuile(p, 'Administrateur', AppColors.roleAdministrateur),
                    ),
                  if (_visible('patient'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Patients / Familles',
                      async: patientsAsync,
                      tuileBuilder: (p) => tuile(p, 'Patient / famille', AppColors.primary),
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
