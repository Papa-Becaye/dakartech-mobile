import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../data/models/course_detail.dart';

/// Carte d'un document pédagogique : icône PDF, nom, type et date de
/// dépôt. Le bouton de téléchargement est confié à l'écran (aucun
/// stockage de fichiers côté backend pour le moment).
class CourseDocumentCard extends StatelessWidget {
  const CourseDocumentCard({
    super.key,
    required this.document,
    this.onDownload,
  });

  final CourseDocument document;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final List<String> meta = <String>[
      if (document.type.trim().isNotEmpty) document.type.trim(),
      if (document.createdAt != null) formatFrenchDate(document.createdAt!),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const AppIcon(
              AppIcons.document,
              color: AppColors.error,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  document.nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meta.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDownload != null)
            AppIconButton(
              icon: AppIcons.download,
              iconColor: AppColors.primary,
              backgroundColor: AppColors.graySoft,
              tooltip: 'Télécharger',
              onPressed: onDownload,
            ),
        ],
      ),
    );
  }
}
