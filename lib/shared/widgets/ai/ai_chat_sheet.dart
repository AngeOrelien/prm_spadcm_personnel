import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../misc/app_circle_icon_button.dart';

/// Ouvre le chat de l'assistant IA de SPAD dans une feuille modale
/// plein-écran-ish (façon fil de messagerie). Un seul point d'entrée pour
/// que le bouton flottant global et le fil épinglé de l'onglet Messages
/// ouvrent exactement la même expérience.
Future<void> ouvrirChatIa(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AiChatSheet(),
  );
}

class _MessageIa {
  final String texte;
  final bool deMoi;
  final DateTime heure;

  const _MessageIa({required this.texte, required this.deMoi, required this.heure});
}

/// Chat avec l'assistant IA de SPAD.
///
/// ⚠️ Pas encore de backend IA (voir `BACKEND-TODO.md`) : les réponses sont
/// simulées côté app (délai + réponse générique/à mots-clés) pour que
/// l'expérience soit déjà utilisable et testable. Le jour où un vrai
/// endpoint existe, seul `_repondre()` ci-dessous aura besoin de changer
/// (appel réseau au lieu du générateur local).
class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet();

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final _saisieCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_MessageIa> _messages = [];
  bool _enTrainDecrire = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _MessageIa(
        texte:
            'Bonjour ! Je suis ${EnvConfig.aiAssistantName}, l\'assistant de SPAD. '
            'Pose-moi une question sur ton planning, un rapport, ou le fonctionnement de l\'appli.',
        deMoi: false,
        heure: DateTime.now(),
      ),
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
      _messages.add(_MessageIa(texte: texte, deMoi: true, heure: DateTime.now()));
      _enTrainDecrire = true;
    });
    _saisieCtrl.clear();
    _scrollerEnBas();

    // Simulation : petit délai + réponse générée localement, en attendant un
    // vrai endpoint IA côté backend.
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(500)));
    if (!mounted) return;
    setState(() {
      _messages.add(_MessageIa(texte: _reponseSimulee(texte), deMoi: false, heure: DateTime.now()));
      _enTrainDecrire = false;
    });
    _scrollerEnBas();
  }

  String _reponseSimulee(String question) {
    final q = question.toLowerCase();
    if (q.contains('check-in') || q.contains('checkin') || q.contains('présence')) {
      return 'Le check-in se fait une seule fois par jour, dès ton arrivée, depuis l\'onglet "Check-in". '
          'Une fois fait, le bouton se désactive et tu peux voir l\'heure enregistrée dans le récapitulatif du jour.';
    }
    if (q.contains('rapport')) {
      return 'Tu peux rédiger un rapport journalier depuis l\'onglet "Mon patient" (bouton "Nouveau rapport"). '
          'Le check-in du jour doit être fait avant, sinon le serveur refuse l\'envoi.';
    }
    if (q.contains('patient')) {
      return 'Les informations de ton patient (coordonnées, pathologie, antécédents, contact d\'urgence) sont dans l\'onglet "Mon patient".';
    }
    if (q.contains('message') || q.contains('contact') || q.contains('coordonnateur') || q.contains('médecin') || q.contains('medecin')) {
      return 'Depuis l\'onglet "Messages", tu peux écrire à ton patient, à l\'équipe des coordonnateurs, aux médecins ou aux administrateurs.';
    }
    return 'Je note ta question — mes réponses sont simulées pour le moment, un vrai assistant IA sera branché prochainement. '
        'En attendant, n\'hésite pas à contacter ton coordonnateur depuis l\'onglet Messages pour tout besoin urgent.';
  }

  @override
  Widget build(BuildContext context) {
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
  final _MessageIa message;

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
          message.texte,
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
