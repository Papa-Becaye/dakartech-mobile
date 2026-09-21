import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/components/app_avatar.dart';
import '../../../shared/widgets/app_icon_button.dart';
import '../../auth/widgets/dakartech_logo.dart';

/// AppBar de l'espace étudiant.
///
/// Écran cohérent pour toutes les branches du shell (header Stitch) :
/// - logo DakarTech + nom de la marque ;
/// - titre de la page (ex. « Accueil », « Cours ») ;
/// - accès aux notifications (point d'entrée uniquement, sans logique) ;
/// - avatar de l'utilisateur (mène au profil).
///
/// C'est un widget d'interface : la navigation est câblée par le
/// [StudentShell] via les callbacks.
class StudentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudentAppBar({
    super.key,
    required this.title,
    required this.onNotificationsTap,
    required this.onAvatarTap,
    this.avatarInitials,
  });

  final String title;
  final VoidCallback onNotificationsTap;
  final VoidCallback onAvatarTap;
  final String? avatarInitials;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: AppSpacing.md,
      toolbarHeight: kToolbarHeight + 4,
      title: Row(
        children: [
          const DakarTechLogo(size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.grayLight,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppIconButton(
          icon: AppIcons.notification,
          tooltip: 'Notifications',
          onPressed: onNotificationsTap,
        ),
        Tooltip(
          message: 'Votre profil',
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: AppAvatar(initials: avatarInitials, size: 34),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
