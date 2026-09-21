import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tonalité d'une matière : une teinte claire pour les fonds (cartes) et
/// une teinte forte pour les accents (pastille, barre latérale, horaire).
class CourseTone {
  const CourseTone({required this.soft, required this.strong});

  final Color soft;
  final Color strong;
}

/// Palette de tonalités distinctes, une par matière.
///
/// Le choix est déterministe : une même matière conserve toujours sa
/// couleur d'un écran à l'autre (index calculé sur l'identifiant réel de
/// la matière, sinon sur son nom). Aucune donnée inventée : on ne fait
/// que dériver un repère visuel stable des données backend disponibles.
abstract final class CourseTones {
  static const List<CourseTone> palette = [
    CourseTone(soft: AppColors.primarySoft, strong: AppColors.primary),
    CourseTone(soft: AppColors.accentSoft, strong: AppColors.accent),
    CourseTone(soft: AppColors.courseBlueSoft, strong: AppColors.courseBlue),
    CourseTone(soft: AppColors.courseTealSoft, strong: AppColors.courseTeal),
    CourseTone(
      soft: AppColors.courseVioletSoft,
      strong: AppColors.courseViolet,
    ),
    CourseTone(
      soft: AppColors.courseOrangeSoft,
      strong: AppColors.courseOrange,
    ),
    CourseTone(soft: AppColors.successSoft, strong: AppColors.success),
    CourseTone(soft: AppColors.courseRoseSoft, strong: AppColors.courseRose),
  ];

  /// Tonalité d'un cours : stable pour une même matière.
  static CourseTone toneFor({required int? matiereId, required String? name}) {
    final int hash = (matiereId ?? name?.hashCode ?? 0).abs();
    return palette[hash % palette.length];
  }
}
