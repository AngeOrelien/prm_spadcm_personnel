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
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/avs_entities.dart';
import '../providers/avs_providers.dart';

/// Onglet "Messagerie" de l'AVS : fil épinglé avec l'assistant IA de SPAD,
/// puis conversations groupées par type d'interlocuteur — administration
/// (coordonnateurs, médecins, administrateurs) et le(s) patient(s) qui lui
/// sont assignés.
///
/// Règle métier : comme les 3 autres rôles, l'AVS peut contacter tout le
/// monde... sauf que pour lui, "tout le monde" se limite à
/// coordonnateur/médecin/administrateur (jamais un autre AVS) — plus
/// son/ses patient(s) affecté(s), pas le roster patients complet. Même
/// restriction appliquée côté backend (`GET /utilisateurs/role/:role`,
/// voir `utilisateurController.listerUtilisateursParRole`) et à la création
/// de la conversation elle-même (`messagerieController.creerConversation`),
/// en plus du filtrage ici côté UI.
///
/// Widgets de présentation (tuile de contact, section groupée, filtres,
/// fil épinglé IA) mutualisés avec les autres rôles dans
/// `shared/widgets/messagerie/messagerie_section_widgets.dart`, pour que les
/// 4 onglets Messagerie (Administrateur, Coordonnateur, Médecin, AVS)
/// restent visuellement cohérents.
class AvsMessagesPage extends ConsumerStatefulWidget {
  const AvsMessagesPage({super.key});

  @override
  ConsumerState<AvsMessagesPage> createState() => _AvsMessagesPageState();
}

class _AvsMessagesPageState extends ConsumerState<AvsMessagesPage> {
  String? _idEnCoursDouverture;
  String? _filtreSelectionne;

  Future<void> _ouvrirConversation(String participantId, String nom, String sousTitre, {String? patientContexteId}) async {
    if (_idEnCoursDouverture != null) return;
    setState(() => _idEnCoursDouverture = participantId);
    try {
      final conversation = await ref.read(avsActionsProvider).ouvrirConversationAvec(
            participantId,
            patientContexteId: patientContexteId,
          );
      if (!mounted) return;
      context.push(
        AppRoutes.avsMessagerieConversation(conversation.id),
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
    ref.invalidate(mesPatientsProvider);
    ref.invalidate(personnelAnnuaireProvider('coordonnateur'));
    ref.invalidate(personnelAnnuaireProvider('medecin'));
    ref.invalidate(personnelAnnuaireProvider('administrateur'));
    ref.invalidate(avsConversationsProvider);
  }

  static const _filtres = [
    FiltreMessagerie('coordonnateur', 'Coordonnateur'),
    FiltreMessagerie('medecin', 'Médecin'),
    FiltreMessagerie('administrateur', 'Administrateur'),
    FiltreMessagerie('patient', 'Patient'),
  ];

  bool _visible(String cle) => _filtreSelectionne == null || _filtreSelectionne == cle;

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(mesPatientsProvider);
    final coordonnateursAsync = ref.watch(personnelAnnuaireProvider('coordonnateur'));
    final medecinsAsync = ref.watch(personnelAnnuaireProvider('medecin'));
    final administrateursAsync = ref.watch(personnelAnnuaireProvider('administrateur'));
    final conversationsAsync = ref.watch(avsConversationsProvider);
    final conversations = conversationsAsync.whenOrNull(data: (v) => v) ?? const <Conversation>[];

    String? dernierMessageAvec(String participantId) {
      for (final c in conversations) {
        if (c.interlocuteurId == participantId) return c.dernierMessage;
      }
      return null;
    }

    Widget tuilePersonnel(PersonnelAnnuaire p, String sousTitreParDefaut, Color couleur) => TuileContactMessagerie(
          nom: p.nomComplet,
          sousTitre: dernierMessageAvec(p.id) ?? sousTitreParDefaut,
          photoUrl: p.photoUrl,
          couleur: couleur,
          chargement: _idEnCoursDouverture == p.id,
          onTap: () => _ouvrirConversation(p.id, p.nomComplet, sousTitreParDefaut),
        );

    return Column(
      children: [
        const AppDashboardHeader.page(
          title: 'Messagerie',
          subtitle: 'Administration et mon patient',
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
                      onTap: () => context.push(AppRoutes.avsMessagerieIa),
                    ),
                    const Divider(height: AppSpacing.lg),
                  ],
                  if (_visible('coordonnateur'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Coordonnateurs',
                      async: coordonnateursAsync,
                      tuileBuilder: (p) => tuilePersonnel(p, 'Coordonnateur', AppColors.roleCoordonnateur),
                    ),
                  if (_visible('medecin'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Médecins',
                      async: medecinsAsync,
                      tuileBuilder: (p) => tuilePersonnel(p, 'Médecin', AppColors.roleMedecin),
                    ),
                  if (_visible('administrateur'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Administrateurs',
                      async: administrateursAsync,
                      tuileBuilder: (p) => tuilePersonnel(p, 'Administrateur', AppColors.roleAdministrateur),
                    ),
                  if (_visible('patient'))
                    SectionMessagerie<Patient>(
                      titre: patientsAsync.whenOrNull(data: (v) => v.length) == 1 ? 'Mon patient' : 'Mes patients',
                      async: patientsAsync,
                      messageVide: 'Aucun patient assigné pour le moment.',
                      tuileBuilder: (patient) {
                        // La messagerie relie des comptes `Utilisateur`, pas
                        // des fiches `Patient` : `compteUtilisateurId` est
                        // l'id à utiliser (voir `Patient.compteUtilisateurId`).
                        // `null` si la fiche n'a pas (encore) de compte de
                        // connexion associé — dans ce cas, pas de conversation
                        // possible avec ce patient.
                        final compteId = patient.compteUtilisateurId;
                        return TuileContactMessagerie(
                          nom: patient.nomComplet,
                          sousTitre: compteId == null ? 'Pas de compte de connexion' : (dernierMessageAvec(compteId) ?? 'Patient'),
                          photoUrl: patient.photoUrl,
                          couleur: AppColors.primary,
                          chargement: _idEnCoursDouverture == compteId,
                          onTap: compteId == null
                              ? null
                              : () => _ouvrirConversation(compteId, patient.nomComplet, 'Patient', patientContexteId: patient.id),
                        );
                      },
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
