/// Modèle de message + logique de réponse partagés entre les deux points
/// d'entrée du chat IA de SPAD :
///  - le bouton flottant global (`ai_floating_button.dart` -> `ouvrirChatIa`,
///    feuille modale) ;
///  - le fil épinglé de l'onglet Messagerie, commun aux 4 rôles de l'app
///    Personnel, qui s'ouvre en page complète façon conversation (voir
///    `shared/widgets/ai/ia_conversation_page.dart`) plutôt qu'en feuille
///    modale, pour une expérience alignée sur les autres fils de discussion.
///
/// ⚠️ Un vrai backend IA existe désormais (`POST /api/assistant/chat`, voir
/// `assistantController.js`), mais l'app continue pour l'instant à simuler
/// les réponses ici (délai + réponse générique/à mots-clés) : le jour où on
/// la branche dessus, seul [reponseSimulee] (et le petit délai autour de son
/// appel) aura besoin d'être remplacé par un appel réseau — le reste de
/// l'UI (bulles, saisie, défilement) ne change pas.
library;

class MessageIa {
  final String texte;
  final bool deMoi;
  final DateTime heure;

  const MessageIa({required this.texte, required this.deMoi, required this.heure});
}

String messageAccueilIa(String nomAssistant) =>
    'Bonjour ! Je suis $nomAssistant, l\'assistant de SPAD. '
    'Pose-moi une question sur ton planning, un rapport, ou le fonctionnement de l\'appli.';

String reponseSimulee(String question) {
  final q = question.toLowerCase();
  if (q.contains('check-in') || q.contains('checkin') || q.contains('présence')) {
    return 'Le check-in se fait une seule fois par jour, dès ton arrivée, depuis l\'onglet "Check-in". '
        'Une fois fait, le bouton se désactive et tu peux voir l\'heure enregistrée dans le récapitulatif du jour.';
  }
  if (q.contains('rapport')) {
    return 'Tu peux rédiger un rapport journalier depuis l\'onglet "Mon patient" (bouton "Nouveau rapport"). '
        'Le check-in du jour doit être fait avant, sinon le serveur refuse l\'envoi. '
        'Si tu n\'as pas de connexion au moment de l\'envoi, ton rapport reste visible dans "Mes rapports" '
        'avec un bouton "Réessayer".';
  }
  if (q.contains('patient')) {
    return 'Les informations de ton patient (coordonnées, pathologie, antécédents, contact d\'urgence) sont dans l\'onglet "Mon patient".';
  }
  if (q.contains('message') || q.contains('contact') || q.contains('coordonnateur') || q.contains('médecin') || q.contains('medecin')) {
    return 'Depuis l\'onglet "Messages", tu peux écrire à ton patient. L\'accès aux coordonnateurs, médecins et '
        'administrateurs arrive bientôt — en attendant, contacte ton coordonnateur habituel par un autre moyen si besoin.';
  }
  return 'Je note ta question — mes réponses sont simulées pour le moment, un vrai assistant IA sera branché prochainement. '
      'En attendant, n\'hésite pas à contacter ton coordonnateur depuis l\'onglet Messages pour tout besoin urgent.';
}
