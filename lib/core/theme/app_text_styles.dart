import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Hiérarchie typographique centrale de l'application.
///
/// Les styles sont intentionnellement SANS couleur codée pour rester
/// flexibles : la couleur est déterminée par le contexte d'affichage
/// (thème, composant). La graisse/size donnent la hiérarchie.
abstract final class AppTextStyles {
  /// Grand écran d'introduction, chiffres-clés.
  static const TextStyle display = TextStyle(
    fontFamily: 'Geist',
    fontSize: 40,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Titres de section principaux (Plus Jakarta Sans equivalent).
  static const TextStyle headline = TextStyle(
    fontFamily: 'Geist',
    fontSize: 28,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  /// Titres intermédiaires.
  static const TextStyle title = TextStyle(
    fontFamily: 'Geist',
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  /// Texte courant.
  static const TextStyle body = TextStyle(
    fontFamily: 'Geist',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Libellés de champs, boutons, éléments d'interface.
  static const TextStyle label = TextStyle(
    fontFamily: 'Geist',
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Informations secondaires, timestamps.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Geist',
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// Style des textes longs / multi-lignes (sans coupure, lisible).
  static const TextStyle bodyLong = TextStyle(
    fontFamily: 'Geist',
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
  );

  /// Titre accentué, plus gros (Pour les welcome card par exemple).
  static const TextStyle displayBold = TextStyle(
    fontFamily: 'Geist',
    fontSize: 26,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
}
