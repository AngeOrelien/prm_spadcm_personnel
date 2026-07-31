import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../../coordonnateur/presentation/widgets/coordonnateur_widgets.dart';
import '../providers/administrateur_providers.dart';

/// Fil de discussion réel de l'administrateur, branché sur
/// `/api/conversations/:id/messages` — même pattern que
/// `AvsConversationPage`/`CoordonnateurConversationPage`. [conversationId]
/// est obtenu via `AdministrateurActions.ouvrirConversationAvec(...)` avant
/// la navigation (voir `administrateur_messagerie_page.dart`).
class AdministrateurConversationPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String interlocuteurNom;
  final String? interlocuteurSousTitre;

  const AdministrateurConversationPage({
    super.key,
    required this.conversationId,
    required this.interlocuteurNom,
    this.interlocuteurSousTitre,
  });

  @override
  ConsumerState<AdministrateurConversationPage> createState() => _AdministrateurConversationPageState();
}

class _AdministrateurConversationPageState extends ConsumerState<AdministrateurConversationPage> {
  final _saisieCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _envoiEnCours = false;
  Timer? _polling;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(administrateurActionsProvider).marquerConversationLue(widget.conversationId);
    });
    // Pas de websocket côté backend pour l'instant (voir BACKEND-TODO.md) :
    // rafraîchissement périodique en attendant du temps réel.
    _polling = Timer.periodic(const Duration(seconds: 12), (_) {
      ref.invalidate(administrateurMessagesProvider(widget.conversationId));
    });
  }

  @override
  void dispose() {
    _polling?.cancel();
    _saisieCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final texte = _saisieCtrl.text.trim();
    if (texte.isEmpty || _envoiEnCours) return;
    setState(() => _envoiEnCours = true);
    _saisieCtrl.clear();
    try {
      await ref.read(administrateurActionsProvider).envoyerMessage(widget.conversationId, texte);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
      _saisieCtrl.text = texte;
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(administrateurMessagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: Row(
          children: [
            InitialsAvatar(nomComplet: widget.interlocuteurNom, radius: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.interlocuteurNom, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
                  if (widget.interlocuteurSousTitre != null)
                    Text(
                      widget.interlocuteurSousTitre!,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => _ErreurMessages(onReessayer: () => ref.invalidate(administrateurMessagesProvider(widget.conversationId))),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Aucun message pour l\'instant. Dites bonjour !', style: Theme.of(context).textTheme.bodySmall),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(administrateurMessagesProvider(widget.conversationId)),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _BulleMessage(message: messages[index]),
                  ),
                );
              },
            ),
          ),
          _BarreSaisie(controller: _saisieCtrl, enCours: _envoiEnCours, onEnvoyer: _envoyer),
        ],
      ),
    );
  }
}

class _BulleMessage extends StatelessWidget {
  final MessageConversation message;

  const _BulleMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final estMoi = message.deMoi;
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: estMoi ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(estMoi ? AppRadius.md : 4),
            bottomRight: Radius.circular(estMoi ? 4 : AppRadius.md),
          ),
          border: estMoi ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.contenu,
              style: TextStyle(color: estMoi ? Colors.white : AppColors.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              _formaterHeure(message.creeLe),
              style: TextStyle(
                fontSize: 10,
                color: estMoi ? Colors.white.withOpacity(0.75) : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formaterHeure(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BarreSaisie extends StatelessWidget {
  final TextEditingController controller;
  final bool enCours;
  final VoidCallback onEnvoyer;

  const _BarreSaisie({required this.controller, required this.enCours, required this.onEnvoyer});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Écrire un message…',
                  isDense: true,
                  fillColor: AppColors.surfaceMuted,
                ),
                onSubmitted: (_) => onEnvoyer(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enCours ? null : onEnvoyer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: enCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErreurMessages extends StatelessWidget {
  final VoidCallback onReessayer;

  const _ErreurMessages({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            const Text('Impossible de charger les messages.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
