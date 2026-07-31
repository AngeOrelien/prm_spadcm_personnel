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
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Onglet "Messagerie" du coordonnateur : fil épinglé avec l'assistant IA de
/// SPAD, filtres par catégorie, puis les conversations groupées par type
/// d'interlocuteur — équipe AVS, médecins, autres coordonnateurs,
/// administrateurs, et patients/familles.
///
/// Le coordonnateur peut, comme l'administrateur et le médecin, communiquer
/// avec TOUT LE MONDE dans l'application, sauf lui-même (voir
/// `utilisateurController.listerUtilisateursParRole`, qui s'auto-exclut
/// désormais de sa propre liste). Même pattern de sections groupées + filtres
/// que les autres rôles (voir
/// `shared/widgets/messagerie/messagerie_section_widgets.dart`), pour que
/// les 4 onglets Messagerie restent cohérents entre eux.
///
/// Le tap ouvre (ou crée) une vraie conversation via
/// `POST/GET /api/conversations`, puis navigue vers le fil de discussion
/// réel (page de conversation partagée, voir
/// `shared/widgets/messagerie/messagerie_conversation_page.dart`).
class CoordonnateurMessageriePage extends ConsumerStatefulWidget {
  const CoordonnateurMessageriePage({super.key});

  @override
  ConsumerState<CoordonnateurMessageriePage> createState() => _CoordonnateurMessageriePageState();
}

class _CoordonnateurMessageriePageState extends ConsumerState<CoordonnateurMessageriePage> {
  String? _idEnCoursDouverture;
  String? _filtreSelectionne;

  Future<void> _ouvrirConversation(String participantId, String nom, String sousTitre, {String? patientContexteId}) async {
    if (_idEnCoursDouverture != null) return;
    setState(() => _idEnCoursDouverture = participantId);
    try {
      final conversation = await ref.read(coordonnateurActionsProvider).ouvrirConversationAvec(
            participantId,
            patientContexteId: patientContexteId,
          );
      if (!mounted) return;
      context.push(
        AppRoutes.coordonnateurMessagerieConversation(conversation.id),
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
    ref.invalidate(avsListProvider);
    ref.invalidate(patientsListProvider);
    ref.invalidate(personnelAnnuaireProvider('medecin'));
    ref.invalidate(personnelAnnuaireProvider('coordonnateur'));
    ref.invalidate(personnelAnnuaireProvider('administrateur'));
    ref.invalidate(conversationsListProvider);
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
    final avsAsync = ref.watch(avsListProvider);
    final patientsAsync = ref.watch(patientsListProvider);
    final medecinsAsync = ref.watch(personnelAnnuaireProvider('medecin'));
    final coordonnateursAsync = ref.watch(personnelAnnuaireProvider('coordonnateur'));
    final administrateursAsync = ref.watch(personnelAnnuaireProvider('administrateur'));
    final conversationsAsync = ref.watch(conversationsListProvider);
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
          subtitle: 'Équipe, collègues et familles',
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
                      onTap: () => context.push(AppRoutes.coordonnateurMessagerieIa),
                    ),
                    const Divider(height: AppSpacing.lg),
                  ],
                  if (_visible('avs'))
                    SectionMessagerie<Avs>(
                      titre: 'Équipe AVS',
                      async: avsAsync,
                      messageVide: 'Aucun AVS dans l\'équipe.',
                      tuileBuilder: (avs) => TuileContactMessagerie(
                        nom: avs.nomComplet,
                        sousTitre: dernierMessageAvec(avs.id) ?? avs.statut.libelle,
                        photoUrl: avs.photoUrl,
                        couleur: AppColors.roleAvs,
                        chargement: _idEnCoursDouverture == avs.id,
                        onTap: () => _ouvrirConversation(avs.id, avs.nomComplet, 'Agent AVS'),
                      ),
                    ),
                  if (_visible('medecin'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Médecins',
                      async: medecinsAsync,
                      tuileBuilder: (p) => TuileContactMessagerie(
                        nom: p.nomComplet,
                        sousTitre: dernierMessageAvec(p.id) ?? 'Médecin',
                        photoUrl: p.photoUrl,
                        couleur: AppColors.roleMedecin,
                        chargement: _idEnCoursDouverture == p.id,
                        onTap: () => _ouvrirConversation(p.id, p.nomComplet, 'Médecin'),
                      ),
                    ),
                  if (_visible('coordonnateur'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Coordonnateurs',
                      async: coordonnateursAsync,
                      tuileBuilder: (p) => TuileContactMessagerie(
                        nom: p.nomComplet,
                        sousTitre: dernierMessageAvec(p.id) ?? 'Coordonnateur',
                        photoUrl: p.photoUrl,
                        couleur: AppColors.roleCoordonnateur,
                        chargement: _idEnCoursDouverture == p.id,
                        onTap: () => _ouvrirConversation(p.id, p.nomComplet, 'Coordonnateur'),
                      ),
                    ),
                  if (_visible('administrateur'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Administrateurs',
                      async: administrateursAsync,
                      tuileBuilder: (p) => TuileContactMessagerie(
                        nom: p.nomComplet,
                        sousTitre: dernierMessageAvec(p.id) ?? 'Administrateur',
                        photoUrl: p.photoUrl,
                        couleur: AppColors.roleAdministrateur,
                        chargement: _idEnCoursDouverture == p.id,
                        onTap: () => _ouvrirConversation(p.id, p.nomComplet, 'Administrateur'),
                      ),
                    ),
                  if (_visible('patient'))
                    SectionMessagerie<Patient>(
                      titre: 'Patients / Familles',
                      async: patientsAsync,
                      messageVide: 'Aucun patient suivi.',
                      tuileBuilder: (patient) {
                        final compteId = patient.compteUtilisateurId;
                        return TuileContactMessagerie(
                          nom: patient.nomComplet,
                          sousTitre: compteId == null ? 'Pas de compte de connexion' : (dernierMessageAvec(compteId) ?? 'Patient / famille'),
                          photoUrl: patient.photoUrl,
                          couleur: AppColors.primary,
                          chargement: _idEnCoursDouverture == compteId,
                          onTap: compteId == null
                              ? null
                              : () => _ouvrirConversation(compteId, patient.nomComplet, 'Patient / famille', patientContexteId: patient.id),
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
