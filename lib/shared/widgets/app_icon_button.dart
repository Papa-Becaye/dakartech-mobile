import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Bouton icône avec zone tactile confortable (44x44 minimum).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor = AppColors.gray,
    this.backgroundColor,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color iconColor;

  /// Fond optionnel (ex. appui secondaire).
  final Color? backgroundColor;

  /// Taille de la zone tactile.
  final double size;

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: iconSize),
      color: iconColor,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: Size(size, size),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
