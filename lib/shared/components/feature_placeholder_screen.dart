import 'package:flutter/material.dart';

import '../../core/icons/app_icon.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Écran temporaire utilisé par le routeur tant que les écrans réels
/// des features ne sont pas développés.
///
/// Chaque route de `app_router.dart` remplacera ce placeholder par son
/// vrai écran au fil des étapes.
class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const AppIcon(
                    AppIcons.construction,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Cet écran sera développé dans une prochaine étape.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
