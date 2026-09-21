import 'package:flutter/widgets.dart';

import 'app_icons.dart';

/// Icône DakarTech standardisée.
///
/// Wrapper léger autour d'un [Icon] qui impose la famille Lucide
/// via [AppIcons] et utilise par défaut une taille standard
/// ([AppIconSize.sm] = 20).
///
/// ```dart
/// AppIcon(AppIcons.home, size: AppIconSize.md, color: AppColors.primary)
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.sm,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
  }
}
