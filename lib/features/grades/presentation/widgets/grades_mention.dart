import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Couple (couleur forte, fond doux) représentant une bande de mention.
///
/// Même convention que les badges « Notée » : un fond adouci
/// (`AppColors.*Soft`) et une couleur forte lisible pour le texte et la
/// barre de progression.
(Color, Color) mentionBand(String? mention) {
  return switch (mention) {
    'Très bien' => (AppColors.success, AppColors.successSoft),
    'Bien' => (AppColors.courseTeal, AppColors.courseTealSoft),
    'Assez bien' => (AppColors.primary, AppColors.primarySoft),
    'Passable' => (AppColors.warning, AppColors.warningSoft),
    'Insuffisant' => (AppColors.error, AppColors.errorSoft),
    _ => (AppColors.gray, AppColors.graySoft),
  };
}

/// Mention dérivée d'une moyenne sur 20 (même barème que le backend :
/// ≥ 16 Très bien, ≥ 14 Bien, ≥ 12 Assez bien, ≥ 10 Passable, sinon
/// Insuffisant).
///
/// La mention de la MOYENNE GÉNÉRALE vient directement du backend ; ce
/// calcul local sert uniquement à afficher la bande d'une matière dans
/// la fiche détaillée (moyenne fournie par le backend, pas recalculée).
String localMentionForMoyenne(double moyenne) {
  if (moyenne >= 16) return 'Très bien';
  if (moyenne >= 14) return 'Bien';
  if (moyenne >= 12) return 'Assez bien';
  if (moyenne >= 10) return 'Passable';
  return 'Insuffisant';
}
