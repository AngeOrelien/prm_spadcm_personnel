import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/administrateur/presentation/pages/administrateur_nouvel_utilisateur_page.dart';
import '../features/administrateur/presentation/pages/administrateur_soin_form_page.dart';
import '../features/administrateur/presentation/pages/administrateur_souscription_detail_page.dart';
import '../features/administrateur/presentation/pages/administrateur_utilisateur_modifier_page.dart';
import '../features/administrateur/presentation/providers/administrateur_providers.dart';
import '../features/administrateur/domain/entities/administrateur_entities.dart';
import '../features/auth/presentation/pages/login_email_page.dart';
import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/avs/presentation/pages/avs_patient_detail_page.dart';
import '../features/avs/presentation/pages/avs_profil_page.dart';
import '../features/avs/presentation/pages/avs_rapport_form_page.dart';
import '../features/avs/presentation/pages/avs_rapports_page.dart';
import '../features/avs/presentation/providers/avs_providers.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_affectations_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_avs_detail_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_avs_form_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_checkin_detail_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patient_detail_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patient_form_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_profil_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_rapport_detail_page.dart';
import '../features/coordonnateur/presentation/providers/coordonnateur_providers.dart';
import '../features/dashboard/presentation/pages/dashboard_tab_placeholder.dart';
import '../features/dashboard/presentation/pages/role_dashboard_shell.dart';
import '../features/medecin/presentation/pages/medecin_patient_detail_page.dart';
import '../features/medecin/presentation/pages/medecin_prescription_form_page.dart';
import '../features/medecin/presentation/providers/medecin_providers.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../screens/splash_screen.dart';
import '../shared/providers/onboarding_providers.dart';
import '../shared/widgets/ai/ia_conversation_page.dart';
import '../shared/widgets/messagerie/messagerie_conversation_page.dart';
import 'app_routes.dart';
import 'role_dashboards.dart';

/// Lit le nom/sous-titre de l'interlocuteur passés en `extra` lors d'un
/// `context.push` vers un fil de messagerie (voir pages "Messagerie" de
/// chaque rôle). Centralisé ici pour éviter de dupliquer le cast dans
/// chaque `builder` ci-dessous.
String _nomInterlocuteur(GoRouterState state, String parDefaut) {
  final extra = state.extra;
  if (extra is Map) return extra['nom']?.toString() ?? parDefaut;
  return parDefaut;
}

String? _sousTitreInterlocuteur(GoRouterState state, [String? parDefaut]) {
  final extra = state.extra;
  if (extra is Map) return extra['sousTitre']?.toString() ?? parDefaut;
  return parDefaut;
}

/// Id réel de conversation (`/api/conversations/:id`), passé en `extra` par
/// `CoordonnateurActions.ouvrirConversationAvec(...)` avant la navigation —
/// voir `coordonnateur_messagerie_page.dart`, `coordonnateur_avs_detail_page.dart`
/// et `coordonnateur_patient_detail_page.dart`.
String _conversationId(GoRouterState state) {
  final extra = state.extra;
  if (extra is Map && extra['conversationId'] != null) return extra['conversationId'].toString();
  // Repli sur le paramètre d'URL si jamais appelé sans `extra` (ne devrait
  // pas arriver côté coordonnateur, mais évite un crash).
  return state.pathParameters['id'] ?? '';
}

/// Pont entre le AsyncNotifierProvider de Riverpod et `refreshListenable` de
/// go_router, pour que le router recalcule ses redirections à chaque
/// changement d'état d'authentification.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
    });
    ref.listen(onboardingVuProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Construit, pour un rôle donné, la [StatefulShellRoute] de son dashboard
/// (bottom navigation) à partir de sa [RoleDashboardConfig]. Ajouter un
/// nouvel onglet à un rôle ne nécessite donc aucune modification ici : tout
/// se passe dans `role_dashboards.dart`.
StatefulShellRoute _buildDashboardRoute(RoleDashboardConfig config) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => RoleDashboardShell(
      config: config,
      navigationShell: navigationShell,
    ),
    branches: [
      for (final tab in config.tabs)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: tab.path,
              builder: (context, state) =>
                  tab.pageBuilder?.call(context) ?? DashboardTabPlaceholder(label: tab.label),
            ),
          ],
        ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final estEnChargement = authState.isLoading;
      final personnel = authState.value;
      final estConnecte = personnel != null;

      final onboardingState = ref.read(onboardingVuProvider);
      // Tant qu'on ne sait pas encore si l'onboarding a déjà été vu (lecture
      // du stockage local en cours), on reste sur splash plutôt que de
      // risquer d'afficher login puis onboarding en un clignement.
      final onboardingEnChargement = onboardingState.isLoading;
      final onboardingDejaVu = onboardingState.value ?? false;

      final surSplash = state.matchedLocation == AppRoutes.splash;
      final surOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final surLogin = state.matchedLocation == AppRoutes.login;
      final surOtp = state.matchedLocation == AppRoutes.otp;
      final surPagePublique = surLogin || surOtp;

      if (estEnChargement || onboardingEnChargement) {
        return surSplash ? null : AppRoutes.splash;
      }

      // Premier lancement (jamais vu l'onboarding) et pas encore connecté :
      // on affiche les 3 pages d'accueil avant même l'écran de connexion.
      if (!estConnecte && !onboardingDejaVu) {
        return surOnboarding ? null : AppRoutes.onboarding;
      }

      if (!estConnecte) {
        if (surOnboarding) return AppRoutes.login;
        return surPagePublique ? null : AppRoutes.login;
      }

      // Connecté : chaque rôle a son propre dashboard, on ne le laisse pas
      // traîner sur splash/onboarding/login/otp, ni accéder au dashboard d'un autre rôle.
      final config = roleDashboards[personnel.role]!;
      final accueilDuRole = config.tabs.first.path;

      if (surSplash || surOnboarding || surPagePublique) return accueilDuRole;
      if (!state.matchedLocation.startsWith(config.basePath)) return accueilDuRole;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingPage()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginEmailPage()),
      GoRoute(path: AppRoutes.otp, builder: (context, state) => const OtpVerificationPage()),
      for (final config in roleDashboards.values) _buildDashboardRoute(config),

      // --- AVS : pages plein écran atteintes via context.push depuis un
      // onglet, donc sans bottom navigation. ---
      GoRoute(
        path: AppRoutes.avsNouveauRapport,
        builder: (context, state) {
          // `extra` = patientId présélectionné, passé depuis l'onglet "Mon
          // patient" (bouton "Nouveau rapport pour ce patient") — voir
          // `avs_patient_page.dart`. Peut être `null` (accès depuis
          // l'historique des rapports, sans patient présélectionné).
          final extra = state.extra;
          return AvsRapportFormPage(patientIdPreselectionne: extra is String ? extra : null);
        },
      ),
      // Historique complet des rapports : n'est plus un onglet (remplacé
      // par "Mon patient", qui montre l'historique du patient assigné),
      // reste accessible en page poussée depuis l'accueil et "Mon patient".
      GoRoute(
        path: AppRoutes.avsRapports,
        builder: (context, state) => const AvsRapportsPage(),
      ),
      // Fiche détail d'un patient précis — utilisée seulement quand l'AVS a
      // plusieurs patients actifs (cas le plus fréquent : patient unique,
      // affiché directement dans l'onglet "Mon patient").
      GoRoute(
        path: AppRoutes.avsPatientDetailPattern,
        builder: (context, state) => AvsPatientDetailPage(patientId: state.pathParameters['id']!),
      ),
      // --- AVS : fil de discussion avec l'assistant IA en page complète —
      // ouvert depuis le fil épinglé de "Messages" (pas le bouton flottant,
      // qui garde sa feuille modale). Enregistré AVANT le pattern `:id`
      // dynamique ci-dessous pour que ce chemin statique soit bien
      // prioritaire. ---
      GoRoute(
        path: AppRoutes.avsMessagerieIa,
        builder: (context, state) => const IaConversationPage(),
      ),
      // --- AVS : fil de messagerie réel (patient, coordonnateurs, médecins,
      // administrateurs), branché sur `/api/conversations` — voir
      // `AvsMessagesPage`, qui appelle `ouvrirConversationAvec(...)` avant
      // de pousser cette route avec le vrai id de conversation en `extra`.
      // Remplace les anciens fils `MessagerieStubPage` (données locales
      // factices, jamais connectés au backend). ---
      GoRoute(
        path: AppRoutes.avsMessagerieConversationPattern,
        builder: (context, state) {
          return MessagerieConversationPage(
            conversationId: _conversationId(state),
            interlocuteurNom: _nomInterlocuteur(state, 'Conversation'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state),
            messagesProvider: avsMessagesProvider,
            envoyerMessage: (ref, id, texte) => ref.read(avsActionsProvider).envoyerMessage(id, texte),
            marquerLu: (ref, id) => ref.read(avsActionsProvider).marquerConversationLue(id),
          );
        },
      ),

      // --- Coordonnateur : pages plein écran (ouvertes via context.push,
      // donc sans bottom navigation), atteintes depuis le menu d'actions
      // rapides ou depuis un bouton "+" au sein d'un onglet. ---
      GoRoute(
        path: AppRoutes.coordonnateurAffectations,
        builder: (context, state) {
          final extra = state.extra;
          String? patientId;
          String? avsId;
          if (extra is Map) {
            patientId = extra['patientId']?.toString();
            avsId = extra['avsId']?.toString();
          }
          return CoordonnateurAffectationsPage(patientIdPreselectionne: patientId, avsIdPreselectionne: avsId);
        },
      ),
      GoRoute(
        path: AppRoutes.coordonnateurNouveauPatient,
        builder: (context, state) => const CoordonnateurPatientFormPage(),
      ),
      GoRoute(
        path: AppRoutes.coordonnateurNouvelAvs,
        builder: (context, state) => const CoordonnateurAvsFormPage(),
      ),
      GoRoute(
        path: AppRoutes.coordonnateurPatientDetailPattern,
        builder: (context, state) => CoordonnateurPatientDetailPage(patientId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.coordonnateurAvsDetailPattern,
        builder: (context, state) => CoordonnateurAvsDetailPage(avsId: state.pathParameters['id']!),
      ),
      // --- Coordonnateur : fil épinglé assistant IA (chemin statique, DOIT
      // être enregistré avant le pattern `:id` dynamique juste après) —
      // voir `CoordonnateurMessageriePage`. ---
      GoRoute(
        path: AppRoutes.coordonnateurMessagerieIa,
        builder: (context, state) => const IaConversationPage(),
      ),
      // --- Coordonnateur : fil de messagerie réel (AVS de l'équipe ou
      // patient/famille), branché sur `/api/conversations` — voir
      // `CoordonnateurMessageriePage`, `CoordonnateurAvsDetailPage` et
      // `CoordonnateurPatientDetailPage`, qui appellent
      // `ouvrirConversationAvec(...)` avant de pousser cette route avec le
      // vrai id de conversation en `extra`. ---
      GoRoute(
        path: AppRoutes.coordonnateurMessagerieConversationPattern,
        builder: (context, state) {
          return MessagerieConversationPage(
            conversationId: _conversationId(state),
            interlocuteurNom: _nomInterlocuteur(state, 'Conversation'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state),
            messagesProvider: messagesProvider,
            envoyerMessage: (ref, id, texte) => ref.read(coordonnateurActionsProvider).envoyerMessage(id, texte),
            marquerLu: (ref, id) => ref.read(coordonnateurActionsProvider).marquerConversationLue(id),
          );
        },
      ),
      // --- Coordonnateur : détail plein écran d'un rapport AVS (au lieu du
      // bottom sheet précédent) — voir `CoordonnateurRapportsPage`. ---
      GoRoute(
        path: AppRoutes.coordonnateurRapportDetailPattern,
        builder: (context, state) => CoordonnateurRapportDetailPage(rapportId: state.pathParameters['id']!),
      ),
      // --- Coordonnateur : détail plein écran d'une présence/check-in d'un
      // AVS — voir `CoordonnateurCheckinsPage`. ---
      GoRoute(
        path: AppRoutes.coordonnateurCheckinDetailPattern,
        builder: (context, state) => CoordonnateurCheckinDetailPage(avsId: state.pathParameters['id']!),
      ),

      // --- Médecin : fiche patient (dossier médical) ---
      GoRoute(
        path: AppRoutes.medecinPatientDetailPattern,
        builder: (context, state) => MedecinPatientDetailPage(patientId: state.pathParameters['id']!),
      ),
      // --- Médecin : nouvelle prescription + fil de messagerie par
      // patient, même correctif qu'AVS/Coordonnateur — voir
      // `MedecinPrescriptionsPage` et `MedecinMessageriePage`. ---
      GoRoute(
        path: AppRoutes.medecinNouvellePrescription,
        builder: (context, state) => const MedecinPrescriptionFormPage(),
      ),
      // --- Médecin : fil épinglé assistant IA (chemin statique, DOIT être
      // enregistré avant le pattern `:id` dynamique juste après) — voir
      // `MedecinMessageriePage`. ---
      GoRoute(
        path: AppRoutes.medecinMessagerieIa,
        builder: (context, state) => const IaConversationPage(),
      ),
      GoRoute(
        path: AppRoutes.medecinMessagerieConversationPattern,
        builder: (context, state) {
          return MessagerieConversationPage(
            conversationId: _conversationId(state),
            interlocuteurNom: _nomInterlocuteur(state, 'Conversation'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state),
            messagesProvider: medecinMessagesProvider,
            envoyerMessage: (ref, id, texte) => ref.read(medecinActionsProvider).envoyerMessage(id, texte),
            marquerLu: (ref, id) => ref.read(medecinActionsProvider).marquerConversationLue(id),
          );
        },
      ),

      // --- Administrateur : création de compte personnel ---
      GoRoute(
        path: AppRoutes.administrateurNouvelUtilisateur,
        builder: (context, state) => const AdministrateurNouvelUtilisateurPage(),
      ),
      // --- Administrateur : édition d'un compte existant — l'entité est
      // passée en `extra` par l'onglet "Ressources" (voir
      // `_OngletUtilisateurs`), pas de re-fetch réseau nécessaire. ---
      GoRoute(
        path: AppRoutes.administrateurUtilisateurModifierPattern,
        builder: (context, state) => AdministrateurUtilisateurModifierPage(
          utilisateur: state.extra as Utilisateur,
        ),
      ),
      // --- Administrateur : catalogue de soins (onglet "Ressources") ---
      GoRoute(
        path: AppRoutes.administrateurNouveauSoin,
        builder: (context, state) => const AdministrateurSoinFormPage(),
      ),
      GoRoute(
        path: AppRoutes.administrateurSoinModifierPattern,
        builder: (context, state) => AdministrateurSoinFormPage(
          soinExistant: state.extra as Soin,
        ),
      ),
      // --- Administrateur : détail/édition d'une souscription (onglet
      // "Ressources") ---
      GoRoute(
        path: AppRoutes.administrateurSouscriptionDetailPattern,
        builder: (context, state) => AdministrateurSouscriptionDetailPage(
          souscription: state.extra as Souscription,
        ),
      ),
      // --- Administrateur : fil de discussion avec l'assistant IA en page
      // complète — même pattern qu'AVS, enregistré AVANT le pattern `:id`
      // dynamique ci-dessous pour que ce chemin statique soit prioritaire. ---
      GoRoute(
        path: AppRoutes.administrateurMessagerieIa,
        builder: (context, state) => const IaConversationPage(),
      ),
      // --- Administrateur : fil de messagerie réel (AVS, médecins,
      // coordonnateurs, patients/familles), branché sur `/api/conversations`
      // — voir `AdministrateurMessageriePage`, qui appelle
      // `ouvrirConversationAvec(...)` avant de pousser cette route avec le
      // vrai id de conversation en `extra`. ---
      GoRoute(
        path: AppRoutes.administrateurMessagerieConversationPattern,
        builder: (context, state) {
          return MessagerieConversationPage(
            conversationId: _conversationId(state),
            interlocuteurNom: _nomInterlocuteur(state, 'Conversation'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state),
            messagesProvider: administrateurMessagesProvider,
            envoyerMessage: (ref, id, texte) => ref.read(administrateurActionsProvider).envoyerMessage(id, texte),
            marquerLu: (ref, id) => ref.read(administrateurActionsProvider).marquerConversationLue(id),
          );
        },
      ),

      // --- Profil : sorti de la bottom navigation pour TOUS les rôles,
      // atteint désormais via le menu "⋮" du header (voir
      // `AppDashboardHeader`). Coordonnateur et AVS ont une vraie page ;
      // médecin et administrateur (rôles plus légers) retombent pour
      // l'instant sur un placeholder. ---
      GoRoute(
        path: AppRoutes.coordonnateurProfil,
        builder: (context, state) => const CoordonnateurProfilPage(),
      ),
      GoRoute(
        path: AppRoutes.avsProfil,
        builder: (context, state) => const AvsProfilPage(),
      ),
      GoRoute(
        path: AppRoutes.medecinProfil,
        builder: (context, state) => const DashboardTabPlaceholder(label: 'Profil', showBackButton: true),
      ),
      GoRoute(
        path: AppRoutes.administrateurProfil,
        builder: (context, state) => const DashboardTabPlaceholder(label: 'Profil', showBackButton: true),
      ),
    ],
  );
});
