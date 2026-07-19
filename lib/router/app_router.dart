import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_email_page.dart';
import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_affectations_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_avs_form_page.dart';
import '../features/coordonnateur/presentation/pages/coordonnateur_patient_form_page.dart';
import '../features/dashboard/presentation/pages/dashboard_tab_placeholder.dart';
import '../features/dashboard/presentation/pages/role_dashboard_shell.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';
import 'role_dashboards.dart';

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

      // --- Coordonnateur : pages plein écran (ouvertes via context.push,
      // donc sans bottom navigation), atteintes depuis le menu d'actions
      // rapides ou depuis un bouton "+" au sein d'un onglet. ---
      GoRoute(
        path: AppRoutes.coordonnateurAffectations,
        builder: (context, state) => const CoordonnateurAffectationsPage(),
      ),
      GoRoute(
        path: AppRoutes.coordonnateurNouveauPatient,
        builder: (context, state) => const CoordonnateurPatientFormPage(),
      ),
      GoRoute(
        path: AppRoutes.coordonnateurNouvelAvs,
        builder: (context, state) => const CoordonnateurAvsFormPage(),
      ),
    ],
  );
});
