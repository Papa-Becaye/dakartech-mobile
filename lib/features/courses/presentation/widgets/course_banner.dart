import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_avatar.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../data/models/course_detail.dart';
import '../../data/models/course_model.dart';

/// Bannière du détail de cours (dégradé Stitch) : badge code, titre,
/// rattachement académique (classe • filière • année) et enseignant
/// référent.
///
/// Seules des données réellement fournies par le détail
/// (`GET /cours/:id`) sont affichées. Le favori et le contact ne sont
/// que des actions visuelles : leur retour est confié à l'écran.
class CourseBanner extends StatelessWidget {
  const CourseBanner({
    super.key,
    required this.detail,
    this.onBookmark,
    this.onContactTeacher,
  });

  final CourseDetail detail;
  final VoidCallback? onBookmark;
  final VoidCallback? onContactTeacher;

  @override
  Widget build(BuildContext context) {
    final CourseEnseignant? enseignant = detail.enseignant;
    final CourseMatiere? matiere = detail.matiere;
    final CourseClasse? classe = detail.classe;

    final String code = matiere?.code?.trim().isNotEmpty == true
        ? matiere!.code!
        : '';

    final String? classeNom = classe?.nom.trim();
    final String? filiereNom = classe?.filiere?.nom.trim();
    final String? anneeLibelle = classe?.annee?.libelle.trim();
    final List<String> rattachement = <String>[
      if (classeNom != null && classeNom.isNotEmpty) classeNom,
      if (filiereNom != null && filiereNom.isNotEmpty) filiereNom,
      if (anneeLibelle != null && anneeLibelle.isNotEmpty) anneeLibelle,
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.primary,
            AppColors.primaryContainer,
            AppColors.primarySoftDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: <Widget>[
            // Halos décoratifs (équivalent du mesh SVG de Stitch).
            Positioned(
              right: -56,
              top: -64,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 96,
              bottom: -64,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (code.isNotEmpty)
                        _BannerBadge(code: code)
                      else
                        const Spacer(),
                      const Spacer(),
                      AppIconButton(
                        icon: AppIcons.bookmark,
                        iconColor: AppColors.white,
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.14,
                        ),
                        onPressed: onBookmark,
                        tooltip: 'Mettre en favori',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail.titre,
                    style: AppTextStyles.title.copyWith(color: AppColors.white),
                  ),
                  if (rattachement.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      rattachement.join(' • '),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (enseignant != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: <Widget>[
                          AppAvatar(
                            initials: enseignant.fullName,
                            size: 40,
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Enseignant référent',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                                Text(
                                  enseignant.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppIconButton(
                            icon: AppIcons.mail,
                            iconColor: AppColors.white,
                            backgroundColor: AppColors.white.withValues(
                              alpha: 0.14,
                            ),
                            onPressed: onContactTeacher,
                            tooltip: 'Contacter l\'enseignant',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille semi-transparente avec code matière (ex. « BD301 »).
class _BannerBadge extends StatelessWidget {
  const _BannerBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            code,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
