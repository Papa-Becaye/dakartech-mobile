import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/models/course_detail.dart';

/// Carte d'une séance passée (historique) : bloc de date, chapitre,
/// créneau horaire/durée et badge de présence réellement émargé.
///
/// Le bloc de gauche présente le jour et le mois abrégé, teinté selon la
/// présence (vert / rouge / neutre si jamais émargée) — lecture
/// « journal de bord » cohérente avec le reste de l'app.
class CourseSessionCard extends StatelessWidget {
  const CourseSessionCard({
    super.key,
    required this.number,
    required this.seance,
  });

  /// Numéro chronologique de la séance (1 = plus ancienne).
  final int number;

  final CourseSeance seance;

  @override
  Widget build(BuildContext context) {
    final CoursePresence? presence = seance.presence;

    final DateTime end = seance.duree > 0
        ? seance.date.add(Duration(hours: seance.duree))
        : seance.date;
    final String creneau =
        '${formatFrenchHour(seance.date)} – '
        '${formatFrenchHour(end)}';

    final List<String> meta = <String>[
      'Séance $number',
      creneau,
      if (seance.duree > 0) '${seance.duree} h',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: _cardDecoration(),
      child: Row(
        children: <Widget>[
          _DateBlock(date: seance.date, present: presence?.present),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  seance.chapitre.isNotEmpty
                      ? seance.chapitre
                      : 'Séance $number',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meta.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          if (presence != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _PresenceBadge(present: presence.present),
          ],
        ],
      ),
    );
  }
}

/// Bloc calendrier : jour (grand) au-dessus du mois abrégé, fond teinté
/// selon la présence réellement émargée.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.present});

  final DateTime date;
  final bool? present;

  @override
  Widget build(BuildContext context) {
    final Color color = present == null
        ? AppColors.gray
        : (present! ? AppColors.success : AppColors.error);
    final Color soft = present == null
        ? AppColors.graySoft
        : (present! ? AppColors.successSoft : AppColors.errorSoft);

    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '${date.day}',
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatFrenchMonthShort(date),
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge « Présent » / « Absent » (vert / rouge), affiché uniquement
/// lorsqu'une présence a réellement été émargée.
class _PresenceBadge extends StatelessWidget {
  const _PresenceBadge({required this.present});

  final bool present;

  @override
  Widget build(BuildContext context) {
    final Color color = present ? AppColors.success : AppColors.error;
    final Color soft = present ? AppColors.successSoft : AppColors.errorSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            present ? 'Présent' : 'Absent',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Décoration commune des cartes du détail (blanc, aucun bord ni ombre
/// — cohérente avec le retrait des ombres demandé, seule la bannière
/// bleue en conserve une).
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.card,
  );
}
