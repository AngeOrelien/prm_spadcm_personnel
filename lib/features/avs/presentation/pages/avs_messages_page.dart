import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/ai/ai_chat_sheet.dart';
import '../../../../shared/widgets/misc/scroll_refresh_listener.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/avs_entities.dart';
import '../providers/avs_providers.dart';

/// Onglet "Messages" de l'AVS : fil épinglé avec l'assistant IA de SPAD,
/// puis conversations avec son patient, les coordonnateurs, les médecins et
/// les administrateurs. Même branchement réel que la messagerie
/// coordonnateur (`POST/GET /api/conversations`) — voir
/// `CoordonnateurMessageriePage`, dont ce fichier reprend le pattern.
///
/// ⚠️ Les sections Coordonnateurs/Médecins/Administrateurs utilisent
/// `GET /utilisateurs/role/:role`, réservé côté backend actuel à
/// coordonnateur/administrateur (403 pour un AVS) — voir `BACKEND-TODO.md`.
/// En attendant l'ouverture de cette route, ces sections s'affichent vides
/// plutôt que casser l'écran.
class AvsMessagesPage extends ConsumerStatefulWidget {
  const AvsMessagesPage({super.key});

  @override
  ConsumerState<AvsMessagesPage> createState() => _AvsMessagesPageState();
}

class _AvsMessagesPageState extends ConsumerState<AvsMessagesPage> {
  String? _idEnCoursDouverture;

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

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(mesPatientsProvider);
    final coordonnateursAsync = ref.watch(personnelAnnuaireProvider('coordonnateur'));
    final medecinsAsync = ref.watch(personnelAnnuaireProvider('medecin'));
    final adminsAsync = ref.watch(personnelAnnuaireProvider('administrateur'));
    final conversationsAsync = ref.watch(avsConversationsProvider);
    final conversations = conversationsAsync.whenOrNull(data: (v) => v) ?? const <Conversation>[];

    String? dernierMessageAvec(String participantId) {
      for (final c in conversations) {
        if (c.interlocuteurId == participantId) return c.dernierMessage;
      }
      return null;
    }

    return Column(
      children: [
        const AppDashboardHeader.page(title: 'Messages', subtitle: 'Patient, équipe et assistant IA', leadingIcon: Icons.forum_outlined),
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
                  _TuileIaEpinglee(onTap: () => ouvrirChatIa(context)),
                  const Divider(height: AppSpacing.lg),
                  _SectionMessagerie(
                    titre: patientsAsync.whenOrNull(data: (v) => v.length) == 1 ? 'Mon patient' : 'Mes patients',
                    async: patientsAsync,
                    messageVide: 'Aucun patient assigné pour le moment.',
                    itemBuilder: (patient) => _TuileContact(
                      nom: patient.nomComplet,
                      sousTitre: dernierMessageAvec(patient.id) ?? 'Patient',
                      photoUrl: patient.photoUrl,
                      couleur: AppColors.primary,
                      chargement: _idEnCoursDouverture == patient.id,
                      onTap: () => _ouvrirConversation(patient.id, patient.nomComplet, 'Patient', patientContexteId: patient.id),
                    ),
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
                    titre: 'Médecins',
                    async: medecinsAsync,
                    couleur: AppColors.roleMedecin,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id, p.nomComplet, 'Médecin'),
                  ),
                  _SectionAnnuaire(
                    titre: 'Administrateurs',
                    async: adminsAsync,
                    couleur: AppColors.roleAdministrateur,
                    dernierMessageAvec: dernierMessageAvec,
                    idEnCoursDouverture: _idEnCoursDouverture,
                    onOuvrir: (p) => _ouvrirConversation(p.id, p.nomComplet, 'Administrateur'),
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

class _SectionMessagerie extends StatelessWidget {
  final String titre;
  final AsyncValue<List<Patient>> async;
  final String messageVide;
  final Widget Function(Patient) itemBuilder;

  const _SectionMessagerie({required this.titre, required this.async, required this.messageVide, required this.itemBuilder});

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
            child: Text('Impossible de charger cette section.', style: Theme.of(context).textTheme.bodySmall),
          ),
          data: (liste) => liste.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(messageVide, style: Theme.of(context).textTheme.bodySmall),
                )
              : Column(children: [for (final p in liste) itemBuilder(p)]),
        ),
      ],
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
          // Repli silencieux : la route annuaire n'est pas encore ouverte à
          // l'AVS côté backend (403) — voir `BACKEND-TODO.md`. On affiche un
          // message neutre plutôt qu'une grosse erreur réseau.
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
                        sousTitre: dernierMessageAvec(p.id) ?? titre.substring(0, titre.length - 1),
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
