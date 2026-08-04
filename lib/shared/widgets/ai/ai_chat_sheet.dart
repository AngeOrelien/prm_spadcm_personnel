import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../features/ia/domain/entities/ia_entities.dart';
import '../../../features/ia/presentation/providers/ia_providers.dart';
import '../misc/app_circle_icon_button.dart';
import 'ai_chat_logic.dart';

/// Ouvre le chat de l'assistant IA de SPAD dans une feuille modale
/// plein-écran-ish (façon fil de messagerie). Point d'entrée du BOUTON
/// FLOTTANT global uniquement — le fil épinglé de l'onglet Messages ouvre
/// une page complète (`ia_conversation_page.dart`), pas cette feuille
/// modale ; les deux partagent le même [chatIaControllerProvider], donc la
/// même conversation et le même historique.
Future<void> ouvrirChatIa(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AiChatSheet(),
  );
}

/// Chat avec l'assistant IA de SPAD, branché sur `POST /api/assistant/chat`
/// via [ChatIaController] (voir `features/ia/presentation/providers/ia_providers.dart`).
/// En cas d'indisponibilité du service IA (503/502), l'erreur s'affiche
/// comme un message de l'assistant plutôt que de bloquer l'UI.
class _AiChatSheet extends ConsumerStatefulWidget {
  const _AiChatSheet();

  @override
  ConsumerState<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<_AiChatSheet> {
  final _saisieCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatIaControllerProvider.notifier).demarrerAvecMessageAccueil(messageAccueilIa(EnvConfig.aiAssistantName));
    });
  }

  @override
  void dispose() {
    _saisieCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollerEnBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _envoyer() async {
    final texte = _saisieCtrl.text.trim();
    if (texte.isEmpty || ref.read(chatIaControllerProvider).enTrainDecrire) return;
    _saisieCtrl.clear();
    _scrollerEnBas();
    await ref.read(chatIaControllerProvider.notifier).envoyer(texte);
    _scrollerEnBas();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(chatIaControllerProvider);
    final hauteur = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        child: Container(
          height: hauteur,
          color: AppColors.background,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _EnTeteIa(onFermer: () => Navigator.of(context).maybePop()),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                    itemCount: etat.messages.length + (etat.enTrainDecrire ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= etat.messages.length) {
                        return const _BulleEnCoursDeSaisie();
                      }
                      return _BulleMessageIa(message: etat.messages[index]);
                    },
                  ),
                ),
                _BarreSaisieIa(controller: _saisieCtrl, enCours: etat.enTrainDecrire, onEnvoyer: _envoyer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnTeteIa extends StatelessWidget {
  final VoidCallback onFermer;

  const _EnTeteIa({required this.onFermer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.accentSurface, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(EnvConfig.aiAssistantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Assistant IA · SPAD', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          AppCircleIconButton(icon: Icons.close, onPressed: onFermer),
        ],
      ),
    );
  }
}

class _BulleMessageIa extends StatelessWidget {
  final MessageChatIa message;

  const _BulleMessageIa({required this.message});

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
        ),
        child: Text(
          message.contenu,
          style: TextStyle(color: estMoi ? Colors.white : AppColors.textPrimary, height: 1.3),
        ),
      ),
    );
  }
}

class _BulleEnCoursDeSaisie extends StatelessWidget {
  const _BulleEnCoursDeSaisie();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _BarreSaisieIa extends StatelessWidget {
  final TextEditingController controller;
  final bool enCours;
  final VoidCallback onEnvoyer;

  const _BarreSaisieIa({required this.controller, required this.enCours, required this.onEnvoyer});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              decoration: InputDecoration(
                hintText: 'Écrire à ${EnvConfig.aiAssistantName}…',
                isDense: true,
                fillColor: AppColors.surfaceMuted,
              ),
              onSubmitted: (_) => onEnvoyer(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enCours ? null : onEnvoyer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
