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
import '../../domain/entities/medecin_entities.dart';
import '../providers/medecin_providers.dart';

/// Onglet "Messagerie" du médecin : fil épinglé avec l'assistant IA de SPAD,
/// filtres par catégorie, puis les conversations groupées par type
/// d'interlocuteur — patients suivis, équipe AVS, coordonnateurs, autres
/// médecins et administrateurs.
///
/// Le médecin peut, comme l'administrateur et le coordonnateur, communiquer
/// avec TOUT LE MONDE dans l'application, sauf lui-même (voir
/// `utilisateurController.listerUtilisateursParRole`, qui s'auto-exclut
/// désormais de sa propre liste). Même pattern de sections groupées +
/// filtres que les autres rôles (voir
/// `shared/widgets/messagerie/messagerie_section_widgets.dart`), pour que
/// les 4 onglets Messagerie restent cohérents entre eux.
class MedecinMessageriePage extends ConsumerStatefulWidget {
  const MedecinMessageriePage({super.key});

  @override
  ConsumerState<MedecinMessageriePage> createState() => _MedecinMessageriePageState();
}

class _MedecinMessageriePageState extends ConsumerState<MedecinMessageriePage> {
  String? _idEnCoursDouverture;
  String? _filtreSelectionne;

  Future<void> _ouvrirConversation(String participantId, String nom, String sousTitre, {String? patientContexteId}) async {
    if (_idEnCoursDouverture != null) return;
    setState(() => _idEnCoursDouverture = participantId);
    try {
      final conversation = await ref.read(medecinActionsProvider).ouvrirConversationAvec(
            participantId,
            patientContexteId: patientContexteId,
          );
      if (!mounted) return;
      context.push(
        AppRoutes.medecinMessagerieConversation(conversation.id),
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
    ref.invalidate(mesPatientsMedecinProvider);
    ref.invalidate(personnelAnnuaireMedecinProvider('avs'));
    ref.invalidate(personnelAnnuaireMedecinProvider('coordonnateur'));
    ref.invalidate(personnelAnnuaireMedecinProvider('medecin'));
    ref.invalidate(personnelAnnuaireMedecinProvider('administrateur'));
    ref.invalidate(medecinConversationsProvider);
  }

  static const _filtres = [
    FiltreMessagerie('patient', 'Patient'),
    FiltreMessagerie('avs', 'AVS'),
    FiltreMessagerie('coordonnateur', 'Coordonnateur'),
    FiltreMessagerie('medecin', 'Médecin'),
    FiltreMessagerie('administrateur', 'Administrateur'),
  ];

  bool _visible(String cle) => _filtreSelectionne == null || _filtreSelectionne == cle;

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(mesPatientsMedecinProvider);
    final avsAsync = ref.watch(personnelAnnuaireMedecinProvider('avs'));
    final coordonnateursAsync = ref.watch(personnelAnnuaireMedecinProvider('coordonnateur'));
    final medecinsAsync = ref.watch(personnelAnnuaireMedecinProvider('medecin'));
    final administrateursAsync = ref.watch(personnelAnnuaireMedecinProvider('administrateur'));
    final conversationsAsync = ref.watch(medecinConversationsProvider);
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
          subtitle: 'Patients, équipe et collègues',
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
                      onTap: () => context.push(AppRoutes.medecinMessagerieIa),
                    ),
                    const Divider(height: AppSpacing.lg),
                  ],
                  if (_visible('patient'))
                    SectionMessagerie<DossierMedicalPatient>(
                      titre: 'Mes patients',
                      async: patientsAsync,
                      messageVide: 'Aucun patient suivi pour le moment.',
                      tuileBuilder: (patient) {
                        final compteId = patient.compteUtilisateurId;
                        return TuileContactMessagerie(
                          nom: patient.nomComplet,
                          sousTitre: compteId == null ? 'Pas de compte de connexion' : (dernierMessageAvec(compteId) ?? 'Patient'),
                          couleur: AppColors.primary,
                          chargement: _idEnCoursDouverture == compteId,
                          onTap: compteId == null
                              ? null
                              : () => _ouvrirConversation(compteId, patient.nomComplet, 'Patient', patientContexteId: patient.id),
                        );
                      },
                    ),
                  if (_visible('avs'))
                    SectionMessagerie<PersonnelAnnuaire>(
                      titre: 'Équipe AVS',
                      async: avsAsync,
                      tuileBuilder: (p) => tuilePersonnel(p, 'Agent AVS', AppColors.roleAvs),
                    ),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
