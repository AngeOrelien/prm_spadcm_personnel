import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/administrateur/presentation/pages/administrateur_nouvel_utilisateur_page.dart';
import '../features/auth/presentation/pages/login_email_page.dart';
import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/avs/presentation/pages/avs_conversation_page.dart';
import '../features/avs/presentation/pages/avs_patient_detail_page.dart';
import '../features/avs/presentation/pages/avs_profil_page.dart';
import '../features/avs/presentation/pages/avs_rapport_form_page.dart';
import '../features/avs/presentation/pages/avs_rapports_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_affectations_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_avs_detail_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_avs_form_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_checkin_detail_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_conversation_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patient_detail_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patient_form_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_profil_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_rapport_detail_page.dart';
import '../features/dashboard/presentation/pages/dashboard_tab_placeholder.dart';
import '../features/dashboard/presentation/pages/role_dashboard_shell.dart';
import '../features/medecin/presentation/pages/medecin_patient_detail_page.dart';
import '../features/medecin/presentation/pages/medecin_prescription_form_page.dart';
import '../screens/splash_screen.dart';
import '../shared/widgets/pages/messagerie_stub_page.dart';
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

      final surSplash = state.matchedLocation == AppRoutes.splash;
      final surLogin = state.matchedLocation == AppRoutes.login;
      final surOtp = state.matchedLocation == AppRoutes.otp;
      final surPagePublique = surLogin || surOtp;

      if (estEnChargement) return surSplash ? null : AppRoutes.splash;
      if (!estConnecte) return surPagePublique ? null : AppRoutes.login;

      // Connecté : chaque rôle a son propre dashboard, on ne le laisse pas
      // traîner sur splash/login/otp, ni accéder au dashboard d'un autre rôle.
      final config = roleDashboards[personnel.role]!;
      final accueilDuRole = config.tabs.first.path;

      if (surSplash || surPagePublique) return accueilDuRole;
      if (!state.matchedLocation.startsWith(config.basePath)) return accueilDuRole;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
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
      // --- AVS : fil de messagerie réel (patient, coordonnateurs, médecins,
      // administrateurs), branché sur `/api/conversations` — voir
      // `AvsMessagesPage`, qui appelle `ouvrirConversationAvec(...)` avant
      // de pousser cette route avec le vrai id de conversation en `extra`.
      // Remplace les anciens fils `MessagerieStubPage` (données locales
      // factices, jamais connectés au backend). ---
      GoRoute(
        path: AppRoutes.avsMessagerieConversationPattern,
        builder: (context, state) {
          return AvsConversationPage(
            conversationId: _conversationId(state),
            interlocuteurNom: _nomInterlocuteur(state, 'Conversation'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state),
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
      // --- Coordonnateur : fil de messagerie réel (AVS de l'équipe ou
      // patient/famille), branché sur `/api/conversations` — voir
      // `CoordonnateurMessageriePage`, `CoordonnateurAvsDetailPage` et
      // `CoordonnateurPatientDetailPage`, qui appellent
      // `ouvrirConversationAvec(...)` avant de pousser cette route avec le
      // vrai id de conversation en `extra`. ---
      GoRoute(
        path: AppRoutes.coordonnateurMessagerieConversationPattern,
        builder: (context, state) {
          return CoordonnateurConversationPage(
            conversationId: _conversationId(state),
            interlocuteurNom: _nomInterlocuteur(state, 'Conversation'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state),
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
      GoRoute(
        path: AppRoutes.medecinMessagerieConversationPattern,
        builder: (context, state) {
          return MessagerieStubPage(
            interlocuteurNom: _nomInterlocuteur(state, 'Patient'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state, 'Patient'),
          );
        },
      ),

      // --- Administrateur : création de compte personnel ---
      GoRoute(
        path: AppRoutes.administrateurNouvelUtilisateur,
        builder: (context, state) => const AdministrateurNouvelUtilisateurPage(),
      ),
      // --- Administrateur : fil de messagerie "Administration", même
      // correctif qu'AVS/Coordonnateur/Médecin — voir
      // `AdministrateurMessagerieConfigPage`. ---
      GoRoute(
        path: AppRoutes.administrateurMessagerieAdministrationPattern,
        builder: (context, state) {
          return MessagerieStubPage(
            interlocuteurNom: _nomInterlocuteur(state, 'Fils Administration'),
            interlocuteurSousTitre: _sousTitreInterlocuteur(state, 'Toutes équipes'),
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
