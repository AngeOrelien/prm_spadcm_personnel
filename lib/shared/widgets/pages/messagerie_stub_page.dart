import 'package:flutter/material.dart';
import 'package:prm_spadcm_personnel/core/theme/app_colors.dart';
import 'package:prm_spadcm_personnel/shared/widgets/misc/app_circle_icon_button.dart';

import '../../../core/theme/app_dimens.dart';

/// Un message dans un fil de conversation — pour l'instant purement local
/// (données statiques de démonstration + messages envoyés pendant la
/// session), en attendant le branchement réel sur `/api/conversations`
/// (déjà disponible côté backend — voir `INTEGRATION.md`, section
/// Messagerie).
class _MessageDemo {
  final String texte;
  final bool deMoi;
  final DateTime heure;

  const _MessageDemo({required this.texte, required this.deMoi, required this.heure});
}

/// Écran de messagerie — fil de discussion avec un interlocuteur (patient
/// / famille ou AVS). Alimenté par un scénario de démonstration statique
/// (varie légèrement selon l'interlocuteur pour paraître réaliste), avec un
/// champ de saisie fonctionnel en local : les messages envoyés apparaissent
/// dans le fil mais ne sont pas persistés côté serveur pour l'instant.
class MessagerieStubPage extends StatefulWidget {
  final String interlocuteurNom;
  final String? interlocuteurSousTitre;

  const MessagerieStubPage({
    super.key,
    required this.interlocuteurNom,
    this.interlocuteurSousTitre,
  });

  @override
  State<MessagerieStubPage> createState() => _MessagerieStubPageState();
}

class _MessagerieStubPageState extends State<MessagerieStubPage> {
  late final List<_MessageDemo> _messages = _genererScenario(widget.interlocuteurNom, widget.interlocuteurSousTitre);
  final _saisieCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _saisieCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Scénario de démo déterministe : varie selon que l'interlocuteur est un
  /// AVS/l'administration ou une famille/patient, pour rester crédible dans
  /// chaque contexte (README §7.2 — messagerie Équipe / Familles).
  List<_MessageDemo> _genererScenario(String nom, String? sousTitre) {
    final maintenant = DateTime.now();
    DateTime ilYA(int minutes) => maintenant.subtract(Duration(minutes: minutes));

    final estFamille = (sousTitre ?? '').toLowerCase().contains('famille') || (sousTitre ?? '').toLowerCase().contains('patient');
    final estAdministration = nom.toLowerCase().contains('administration');

    if (estAdministration) {
      return [
        _MessageDemo(texte: 'Bonjour, il ne reste plus de gants et de solution hydroalcoolique pour ma tournée de la semaine.', deMoi: true, heure: ilYA(180)),
        _MessageDemo(texte: 'Bonjour, merci du signalement. Un renouvellement de matériel est prévu vendredi.', deMoi: false, heure: ilYA(170)),
        _MessageDemo(texte: 'Peux-tu passer au dépôt avant ta tournée de demain matin ?', deMoi: false, heure: ilYA(169)),
        _MessageDemo(texte: 'Oui, je passerai vers 8h avant le premier patient.', deMoi: true, heure: ilYA(150)),
        _MessageDemo(texte: 'Parfait, un lot est mis de côté à ton nom à l\'accueil.', deMoi: false, heure: ilYA(30)),
      ];
    }

    if (estFamille) {
      return [
        _MessageDemo(texte: 'Bonjour, comment s\'est passée la visite de ce matin chez $nom ?', deMoi: true, heure: ilYA(240)),
        _MessageDemo(texte: 'Bonjour, tout s\'est bien passé. La prise des constantes est dans la norme et le moral est bon aujourd\'hui.', deMoi: false, heure: ilYA(230)),
        _MessageDemo(texte: 'Merci beaucoup pour le retour, ça nous rassure.', deMoi: true, heure: ilYA(225)),
        _MessageDemo(texte: 'Le rapport détaillé de la visite est disponible dans l\'appli si besoin.', deMoi: false, heure: ilYA(220)),
        _MessageDemo(texte: 'Une question : faut-il prévoir quelque chose de particulier avant la prochaine visite ?', deMoi: true, heure: ilYA(60)),
        _MessageDemo(texte: 'Pas de préparation spéciale, juste garder le pilulier à portée de main comme d\'habitude.', deMoi: false, heure: ilYA(45)),
      ];
    }

    // Fil AVS <-> Coordonnateur/Médecin par défaut.
    return [
      _MessageDemo(texte: 'Bonjour $nom, comment se passe la tournée aujourd\'hui ?', deMoi: true, heure: ilYA(200)),
      _MessageDemo(texte: 'Bonjour, ça se passe bien, je suis en avance sur le planning.', deMoi: false, heure: ilYA(190)),
      _MessageDemo(texte: 'Un patient a exprimé un peu de fatigue ce matin, rien d\'inquiétant mais je le note dans le rapport.', deMoi: false, heure: ilYA(188)),
      _MessageDemo(texte: 'Merci pour le suivi, tiens-moi au courant si ça évolue.', deMoi: true, heure: ilYA(180)),
      _MessageDemo(texte: 'Bien reçu, je fais un point ce soir après la dernière visite.', deMoi: false, heure: ilYA(20)),
    ];
  }

  void _envoyer() {
    final texte = _saisieCtrl.text.trim();
    if (texte.isEmpty) return;
    setState(() {
      _messages.add(_MessageDemo(texte: texte, deMoi: true, heure: DateTime.now()));
    });
    _saisieCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                _initiales(widget.interlocuteurNom),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
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
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _BulleMessage(message: _messages[index]),
            ),
          ),
          _BarreSaisie(controller: _saisieCtrl, onEnvoyer: _envoyer),
        ],
      ),
    );
  }

  String _initiales(String nom) {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }
}

class _BulleMessage extends StatelessWidget {
  final _MessageDemo message;

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
              message.texte,
              style: TextStyle(color: estMoi ? Colors.white : AppColors.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              _formaterHeure(message.heure),
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
  final VoidCallback onEnvoyer;

  const _BarreSaisie({required this.controller, required this.onEnvoyer});

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
                onTap: onEnvoyer,
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
