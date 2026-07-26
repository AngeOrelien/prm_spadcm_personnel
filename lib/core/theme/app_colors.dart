import 'package:flutter/material.dart';

/// Palette de couleurs unique de l'app Personnel (MySPAD Pro).
///
/// V3 — repensée à partir du logo SPAD (silhouette bleu/vert + main de soin
/// bleue) pour que `primary` (bleu confiance) et `secondary` (vert
/// soin/santé) se distinguent clairement au premier coup d'œil, y compris en
/// petites icônes translucides. Les couleurs de rôle et de statut ont aussi
/// été espacées en teinte (bleu / vert / orangé / violet) pour rester
/// lisibles côte à côte dans les dashboards.
class AppColors {
  AppColors._();

  // --- Marque : bleu "confiance" (main de soin du logo) ---
  static const Color primary = Color(0xFF008FA1);
  static const Color primaryDark = Color(0xFF005F6B);
  static const Color primaryLight = Color(0xFF25A8B4);
  static const Color primarySurface = Color(0xFFD6EFF1);

  // --- Marque : vert "santé/soin" (silhouette du logo), bien distinct du bleu ---
  static const Color secondary = Color(0xFF1C9165);
  static const Color secondaryDark = Color(0xFF0F6E48);
  static const Color secondaryLight = Color(0xFF63C99A);
  static const Color secondarySurface = Color(0xFFE1F6EB);

  // --- Accent tertiaire : le turquoise du cercle du logo, pour surligner
  // sans se confondre avec primary (bleu) ni secondary (vert) ---
  static const Color accent = Color(0xFF19B3B3);
  static const Color accentSurface = Color(0xFFE0F7F5);

  // --- Neutres : légèrement plus froids/contrastés ---
  static const Color background = Color(0xFFF4F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF2F5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDFE6EA);

  static const Color textPrimary = Color(0xFF16232B);
  static const Color textSecondary = Color(0xFF5C6C76);
  static const Color textDisabled = Color(0xFFA2AFB6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Retours utilisateur ---
  static const Color success = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFC77700);
  static const Color error = Color(0xFFD03A2E);
  static const Color info = Color(0xFF1967D2);

  // --- Badges par rôle (utile pour l'app Personnel multi-rôles) : teintes
  // espacées sur le cercle chromatique pour rester distinctes même en
  // versions translucides (12%) sur fond clair. ---
  static const Color roleAvs = Color(0xFF1C9165); // vert
  static const Color roleMedecin = Color(0xFF1868A8); // bleu
  static const Color roleCoordonnateur = Color(0xFFC77700); // orangé
  static const Color roleAdministrateur = Color(0xFF7A4FE0); // violet

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

  // --- Bottom navigation (thème sombre "flottant", volontairement
  // indépendant du thème clair du reste de l'app : voir RoleDashboardShell).
  // Le sélectionné reprend l'accent turquoise du logo pour rester cohérent
  // avec le header/primary tout en restant lisible sur fond noir. ---
  static const Color navBackground = Color(0xFF10181D);
  static const Color navIndicator = Color(0xFF1B3A3C);
  static const Color navSelected = Color(0xFF3FD6C8);
  static const Color navUnselected = Color(0xFF7C8992);
}
