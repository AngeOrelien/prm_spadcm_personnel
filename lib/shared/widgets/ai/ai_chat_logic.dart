/// Message d'accueil affiché en tête de conversation avec l'assistant IA
/// de SPAD — partagé entre le bouton flottant global (`ai_chat_sheet.dart`)
/// et le fil épinglé de l'onglet Messagerie (`ia_conversation_page.dart`).
///
/// Les réponses elles-mêmes ne sont PLUS simulées ici : elles viennent
/// désormais du vrai backend (`POST /api/assistant/chat`, relayé au service
/// IA séparé `prm-spadcm-ia`) via `ChatIaController`, voir
/// `features/ia/presentation/providers/ia_providers.dart`. Les entités de
/// message (`MessageChatIa`, `RoleMessageChat`) vivent désormais dans
/// `features/ia/domain/entities/ia_entities.dart`.
library;

String messageAccueilIa(String nomAssistant) =>
    'Bonjour ! Je suis $nomAssistant, l\'assistant de SPAD. '
    'Pose-moi une question sur ton planning, un rapport, ou le fonctionnement de l\'appli.';
