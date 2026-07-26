import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../router/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Onglet "Messagerie" du coordonnateur : fils par AVS de l'équipe et par
/// patient/famille suivi. Le tap ouvre (ou crée) une vraie conversation via
/// `POST/GET /api/conversations`, puis navigue vers le fil de discussion
/// réel (`CoordonnateurConversationPage`) — plus de messagerie locale/stub.
class CoordonnateurMessageriePage extends ConsumerStatefulWidget {
  const CoordonnateurMessageriePage({super.key});

  @override
  ConsumerState<CoordonnateurMessageriePage> createState() => _CoordonnateurMessageriePageState();
}

class _CoordonnateurMessageriePageState extends ConsumerState<CoordonnateurMessageriePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  String? _idEnCoursDouverture;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final avsAsync = ref.watch(avsListProvider);
    final patientsAsync = ref.watch(patientsListProvider);
    final conversationsAsync = ref.watch(conversationsListProvider);
    final conversations = conversationsAsync.whenOrNull(data: (v) => v) ?? const <Conversation>[];

    Conversation? conversationAvec(String participantId) {
      for (final c in conversations) {
        if (c.interlocuteurId == participantId) return c;
      }
      return null;
    }

    return Column(
      children: [
        const AppDashboardHeader.page(title: 'Messagerie', subtitle: 'Équipe et familles', leadingIcon: Icons.forum_outlined),
        TabBar(controller: _tabController, tabs: const [Tab(text: 'Équipe AVS'), Tab(text: 'Familles')]),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              avsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(avsListProvider)),
                data: (liste) => liste.isEmpty
                    ? Center(child: Text('Aucun AVS dans l\'équipe.', style: Theme.of(context).textTheme.bodySmall))
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(avsListProvider);
                          ref.invalidate(conversationsListProvider);
                        },
                        child: ListView.builder(
                          itemCount: liste.length,
                          itemBuilder: (context, index) {
                            final avs = liste[index];
                            final conversation = conversationAvec(avs.id);
                            return ListTile(
                              leading: InitialsAvatar(nomComplet: avs.nomComplet, couleur: AppColors.roleAvs, photoUrl: avs.photoUrl),
                              title: Text(avs.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                conversation?.dernierMessage ?? avs.statut.libelle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: _idEnCoursDouverture == avs.id
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                              onTap: () => _ouvrirConversation(avs.id, avs.nomComplet, 'Agent AVS'),
                            );
                          },
                        ),
                      ),
              ),
              patientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(patientsListProvider)),
                data: (liste) => liste.isEmpty
                    ? Center(child: Text('Aucun patient suivi.', style: Theme.of(context).textTheme.bodySmall))
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(patientsListProvider);
                          ref.invalidate(conversationsListProvider);
                        },
                        child: ListView.builder(
                          itemCount: liste.length,
                          itemBuilder: (context, index) {
                            final patient = liste[index];
                            final conversation = conversationAvec(patient.id);
                            return ListTile(
                              leading: InitialsAvatar(nomComplet: patient.nomComplet, photoUrl: patient.photoUrl),
                              title: Text(patient.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                conversation?.dernierMessage ?? 'Patient / famille',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: _idEnCoursDouverture == patient.id
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                              onTap: () => _ouvrirConversation(patient.id, patient.nomComplet, 'Patient / famille', patientContexteId: patient.id),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
