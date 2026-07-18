import 'package:flutter/material.dart';

/// Palette de couleurs unique de l'app Personnel.
///
/// Couleur principale imposée : 0xFF068574 (vert sarcelle médical).
/// Couleur secondaire choisie par complémentarité de teinte (roue chromatique) :
/// le teal ~172° a pour complémentaire ~352°, un corail/rose chaud qui
/// tranche agréablement avec le vert tout en restant cohérent avec l'univers
/// "santé / bienveillance" (cf. le petit cœur du mockup fourni).
class AppColors {
  AppColors._();

  // --- Marque ---
  static const Color primary = Color(0xFF00A7BB);
  static const Color primaryDark = Color(0xFF007583);
  static const Color primaryLight = Color(0xFF40C0CD);
  static const Color primarySurface = Color(0xFFE5F6F7);

  static const Color secondary = Color(0xFFFF6F61); // corail
  static const Color secondaryDark = Color(0xFFE0503F);
  static const Color secondaryLight = Color(0xFFFFA898);
  static const Color secondarySurface = Color(0xFFFFEDE9);

  // --- Neutres ---
  static const Color background = Color(0xFFF7F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F4);
  static const Color border = Color(0xFFE3E7E8);

  static const Color textPrimary = Color(0xFF1B1F1E);
  static const Color textSecondary = Color(0xFF6B7573);
  static const Color textDisabled = Color(0xFFAAB2B0);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Retours utilisateur ---
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD8453A);
  static const Color info = Color(0xFF1976D2);

  // --- Badges par rôle (utile pour l'app Personnel multi-rôles) ---
  static const Color roleAvs = Color(0xFF068574);
  static const Color roleMedecin = Color(0xFF1976D2);
  static const Color roleCoordonnateur = Color(0xFFF9A825);
  static const Color roleAdministrateur = Color(0xFF6B4EFF);
}
