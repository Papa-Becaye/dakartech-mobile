import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/components/app_avatar.dart';
import '../../auth/models/user_model.dart';

/// Carte de bienvenue du dashboard étudiant.
///
/// Identité de l'utilisateur authentifié : avatar avec indicateur de
/// statut, prénom, niveau de classe et année académique.
///
/// Les données proviennent de la session ([AuthController]) et du
/// [DashboardData] — rien n'est codé en dur.
class StudentWelcomeCard extends StatelessWidget {
  const StudentWelcomeCard({
    super.key,
    required this.user,
    this.classLevel,
    this.academicYear,
  });

  final UserModel? user;
  final String? classLevel;
  final String? academicYear;

  @override
  Widget build(BuildContext context) {
    final String? prenom = user?.prenom;
    final String greeting = (prenom == null || prenom.isEmpty)
        ? 'Bonjour 👋'
        : 'Bonjour, $prenom 👋';

    final String subtitleParts = [
      classLevel,
      academicYear,
    ].whereType<String>().where((String s) => s.isNotEmpty).join(' • ');
    final String subtitle = subtitleParts.isEmpty ? '' : subtitleParts;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppAvatar(initials: user?.fullName, size: 52),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.displayBold.copyWith(
                  color: AppColors.dark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: AppTextStyles.label.copyWith(color: AppColors.grayLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
