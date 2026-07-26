import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Police unique de l'app Personnel — branchée via `google_fonts`.
///
/// ┌──────────────────────────────────────────────────────────────────────┐
/// │  UN SEUL ENDROIT À MODIFIER POUR CHANGER LA POLICE DE TOUTE L'APP.   │
/// │  Remplace `GoogleFonts.montserrat` par ex. par `GoogleFonts.poppins` │
/// │  dans les deux méthodes ci-dessous, et relance l'app : tous les      │
/// │  écrans (textTheme, AppTextStyles, boutons, champs...) suivent.      │
/// └──────────────────────────────────────────────────────────────────────┘
///
/// Nécessite d'ajouter `google_fonts` dans `pubspec.yaml` :
///   dependencies:
///     google_fonts: ^6.2.1
class AppFonts {
  AppFonts._();

  /// Applique la police à un [TextStyle] donné (garde taille/poids/couleur).
  /// Utilisé par [AppTextStyles] pour que chaque style de texte de l'app
  /// passe par la même police sans avoir à la répéter partout.
  static TextStyle style(TextStyle base) => GoogleFonts.ubuntuSans(textStyle: base);

  /// Variante « display » — mêmes réglages, permet de garder une police
  /// différente pour les gros titres si un jour on veut les distinguer,
  /// sans dupliquer la logique de swap ailleurs.
  static TextStyle display(TextStyle base) => GoogleFonts.ubuntuSans(textStyle: base);

  /// Génère un [TextTheme] entier dans la police de l'app, à partir d'un
  /// thème Material de base (fallback pour tout ce qui n'est pas couvert
  /// explicitement par [AppTextStyles]).
  static TextTheme textTheme(TextTheme base) => GoogleFonts.ubuntuSansTextTheme(base);
}
