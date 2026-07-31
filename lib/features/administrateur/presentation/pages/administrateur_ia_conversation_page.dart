import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/ai/ai_chat_logic.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';

/// Fil de discussion avec l'assistant IA de SPAD, en page complète — comme
/// une conversation avec un membre de l'équipe (voir
/// `AdministrateurConversationPage`, dont ce fichier reprend la structure :
/// AppBar avec avatar + nom, bulles de message, barre de saisie).
///
/// Ouvert depuis le fil épinglé de l'onglet Messagerie
/// (`administrateur_messagerie_page.dart`) ET depuis le menu d'actions
/// rapides (bouton flottant du dashboard, voir `role_dashboards.dart`) —
/// même logique de réponse simulée que côté AVS (`ai_chat_logic.dart`).
///
/// ⚠️ Pas encore de backend IA (voir `BACKEND-TODO.md`) : réponses simulées
/// en attendant un vrai endpoint de chat. Le jour où il existera, seul
/// `_envoyer()` ci-dessous devra changer.
class AdministrateurIaConversationPage extends StatefulWidget {
  const AdministrateurIaConversationPage({super.key});

  @override
  State<AdministrateurIaConversationPage> createState() => _AdministrateurIaConversationPageState();
}

class _AdministrateurIaConversationPageState extends State<AdministrateurIaConversationPage> {
  final _saisieCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<MessageIa> _messages = [];
  bool _enTrainDecrire = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      MessageIa(texte: messageAccueilIa(EnvConfig.aiAssistantName), deMoi: false, heure: DateTime.now()),
    );
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
    if (texte.isEmpty || _enTrainDecrire) return;
    setState(() {
      _messages.add(MessageIa(texte: texte, deMoi: true, heure: DateTime.now()));
      _enTrainDecrire = true;
    });
    _saisieCtrl.clear();
    _scrollerEnBas();

    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(500)));
    if (!mounted) return;
    setState(() {
      _messages.add(MessageIa(texte: reponseSimulee(texte), deMoi: false, heure: DateTime.now()));
      _enTrainDecrire = false;
    });
    _scrollerEnBas();
  }

  @override
  Widget build(BuildContext context) {
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
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentSurface,
              child: Icon(Icons.smart_toy_outlined, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(EnvConfig.aiAssistantName, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
                  Text('Assistant IA · SPAD (Administration)', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
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
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              itemCount: _messages.length + (_enTrainDecrire ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return const _BulleEnCoursDeSaisie();
                }
                return _BulleMessageIa(message: _messages[index]);
              },
            ),
          ),
          _BarreSaisieIa(controller: _saisieCtrl, enCours: _enTrainDecrire, onEnvoyer: _envoyer),
        ],
      ),
    );
  }
}

class _BulleMessageIa extends StatelessWidget {
  final MessageIa message;

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
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.texte, style: TextStyle(color: estMoi ? Colors.white : AppColors.textPrimary, height: 1.3)),
            const SizedBox(height: 4),
            Text(
              _formaterHeure(message.heure),
              style: TextStyle(fontSize: 10, color: estMoi ? Colors.white.withOpacity(0.75) : AppColors.textDisabled),
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
        child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
      ),
    );
  }
}
