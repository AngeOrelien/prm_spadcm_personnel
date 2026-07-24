import 'package:flutter/material.dart';

/// Palette de couleurs unique de l'app Personnel (MySPAD Pro).
///
/// V2 — palette assombrie/désaturée légèrement pour un rendu plus "premium"
/// (moins flashy, meilleurs contrastes texte/fond) tout en conservant
/// l'identité teal/corail imposée par la marque.
class AppColors {
  AppColors._();

  // --- Marque : teal approfondi, plus "pro" que la V1 ---
  static const Color primary = Color(0xFF00838F);
  static const Color primaryDark = Color(0xFF00565E);
  static const Color primaryLight = Color(0xFF4FB3BF);
  static const Color primarySurface = Color(0xFFE1F2F3);

  static const Color secondary = Color(0xFFFF6B57); // corail, complémentaire
  static const Color secondaryDark = Color(0xFFD9482F);
  static const Color secondaryLight = Color(0xFFFFA98F);
  static const Color secondarySurface = Color(0xFFFFEAE4);

  // --- Neutres : légèrement plus froids/contrastés ---
  static const Color background = Color(0xFFF5F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFF3F3);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDEE5E5);

  static const Color textPrimary = Color(0xFF11201F);
  static const Color textSecondary = Color(0xFF5B6B6A);
  static const Color textDisabled = Color(0xFFA2AFAE);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Retours utilisateur ---
  static const Color success = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFC77700);
  static const Color error = Color(0xFFD03A2E);
  static const Color info = Color(0xFF1967D2);

  // --- Badges par rôle (utile pour l'app Personnel multi-rôles) ---
  static const Color roleAvs = Color(0xFF00838F);
  static const Color roleMedecin = Color(0xFF1967D2);
  static const Color roleCoordonnateur = Color(0xFFC77700);
  static const Color roleAdministrateur = Color(0xFF6B4EFF);

  /// Couleur d'accent associée au rôle connecté — utilisée pour teinter
  /// discrètement les headers/dashboards selon qui est connecté, sans avoir
  /// à dupliquer de logique dans chaque feature.
  static Color forRole(String role) {
    switch (role) {
      case 'avs':
        return roleAvs;
      case 'medecin':
        return roleMedecin;
      case 'coordonnateur':
        return roleCoordonnateur;
      case 'administrateur':
        return roleAdministrateur;
      default:
        return primary;
    }
  }

  // --- Bottom navigation (thème sombre, volontairement indépendant du
  // thème clair du reste de l'app : voir RoleDashboardShell). Assombrie et
  // désaturée pour un rendu plus sobre/pro. ---
  static const Color navBackground = Color(0xFF0B1615);
  static const Color navIndicator = Color(0xFF163E3F);
  static const Color navSelected = Color(0xFF4FD6D9);
  static const Color navUnselected = Color(0xFF748584);
}
