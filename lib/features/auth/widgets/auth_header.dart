import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dakartech_logo.dart';

/// En-tête réutilisé par les écrans d'authentification
/// (login, forgot-password).
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.title = 'Bienvenue sur DakarTech',
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DakarTechLogo(),
        const SizedBox(height: AppSpacing.lg),
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.headline),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.gray),
          ),
        ],
      ],
    );
  }
}
