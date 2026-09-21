import 'package:flutter/material.dart';

/// Palette centrale de l'application DakarTech.
///
/// Les couleurs ne doivent JAMAIS être écrites en dur dans les widgets.
/// Utiliser exclusivement cette classe ou le thème (voir [AppTheme]).
abstract final class AppColors {
  /// Couleur principale (brand) — bleu DakarTech.
  static const Color primary = Color(0xFF00395F);

  /// Variante plus claire du primary (containers, badges).
  static const Color primaryContainer = Color(0xFF18507D);

  /// Couleur d'accentuation — rouge DakarTech.
  static const Color accent = Color(0xFFB90F08);

  /// Fond général des écrans (gris très clair, teinte WhatsApp).
  static const Color background = Color(0xFFF8F9FB);

  /// Surfaces claires (cartes, champs).
  static const Color white = Color(0xFFFFFFFF);

  /// Texte principal, très foncé.
  static const Color dark = Color(0xFF151C27);

  /// Texte secondaire / gris.
  static const Color gray = Color(0xFF42474F);

  /// Gris plus léger pour captions.
  static const Color grayLight = Color(0xFF727780);

  /// Bordures, séparateurs.
  static const Color border = Color(0xFFE5E7EB);

  /// Bordure légère (outline-variant).
  static const Color borderLight = Color(0xFFC2C7D0);

  /// Statut succès.
  static const Color success = Color(0xFF16A34A);

  /// Statut avertissement.
  static const Color warning = Color(0xFFF59E0B);

  /// Statut erreur.
  static const Color error = Color(0xFFDC2626);

  // ------------------------------------------------------------------------
  // Variantes adoucies (pour fonds de badges, containers, états).
  // ------------------------------------------------------------------------

  static const Color primarySoft = Color(0xFFF5F7FA);
  static const Color primarySoftDark = Color(0xFF9BCBFF);
  static const Color accentSoft = Color(0xFFFFDAD6);
  static const Color successSoft = Color(0xFFE8F6ED);
  static const Color warningSoft = Color(0xFFFFF3E0);
  static const Color errorSoft = Color(0xFFFCE9E9);
  static const Color graySoft = Color(0xFFF0F3FF);
  static const Color graySoftDark = Color(0xFFE7EEFE);

  // ------------------------------------------------------------------------
  // Teintes légères pour les cartes de cours (accents visuels).
  // ------------------------------------------------------------------------

  static const Color blueLight = Color(0xFFEBF5FF);
  static const Color greenLight = Color(0xFFECFDF5);
  static const Color orangeLight = Color(0xFFFFF8ED);
  static const Color redLight = Color(0xFFFFF5F5);

  // ------------------------------------------------------------------------
  // Teintes par matière (variantes douces + fortes, distinctes entre elles).
  // ------------------------------------------------------------------------

  static const Color courseBlue = Color(0xFF2F6FED);
  static const Color courseBlueSoft = Color(0xFFE8F0FE);
  static const Color courseTeal = Color(0xFF0F9D8E);
  static const Color courseTealSoft = Color(0xFFE6F7F5);
  static const Color courseViolet = Color(0xFF7C5CFC);
  static const Color courseVioletSoft = Color(0xFFF1EDFF);
  static const Color courseOrange = Color(0xFFF97316);
  static const Color courseOrangeSoft = Color(0xFFFFF2E5);
  static const Color courseRose = Color(0xFFF43F5E);
  static const Color courseRoseSoft = Color(0xFFFFEDF0);
}
