import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant {
  /// Bouton principal (fond plein Primary).
  primary,

  /// Bouton secondaire (contour Primary).
  secondary,

  /// Bouton texte.
  text,
}

/// Bouton réutilisable de l'application.
///
/// Accessible au doigt (hauteur minimale 48), thème centralisé.
///
/// ```dart
/// AppButton(
///   label: 'Se connecter',
///   onPressed: () {},
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Icône affichée avant le libellé.
  final IconData? icon;

  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    final ButtonStyle style = switch (variant) {
      AppButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      AppButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      AppButtonVariant.text => TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    };

    final Widget child = _AppButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      variant: variant,
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: style,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: style,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: style,
        child: child,
      ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class _AppButtonContent extends StatelessWidget {
  const _AppButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.variant,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: variant == AppButtonVariant.primary
              ? AppColors.white
              : AppColors.primary,
        ),
      );
    }

    final Widget labelWidget = Text(label, textAlign: TextAlign.center);

    if (icon == null) {
      return labelWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        labelWidget,
      ],
    );
  }
}
