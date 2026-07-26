import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Échelle typographique unique de l'app.
///
/// La police elle-même vient de [AppFonts] (voir ce fichier pour la
/// changer partout d'un coup) : ces styles ne définissent que taille,
/// graisse, couleur et interlignage, jamais la famille de police.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => AppFonts.display(const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      ));

  static TextStyle get h2 => AppFonts.display(const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      ));

  static TextStyle get h3 => AppFonts.style(const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ));

  static TextStyle get bodyLarge => AppFonts.style(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      ));

  static TextStyle get bodyMedium => AppFonts.style(const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ));

  static TextStyle get caption => AppFonts.style(const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ));

  static TextStyle get button => AppFonts.style(const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get link => AppFonts.style(const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ));
}
