import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Logo symbolique de DakarTech (icône dans un bloc coloré).
///
/// Utilisé aussi bien dans le splash (fond blanc, icône primaire)
/// que dans les écrans login / forgot-password (fond soft, icône
/// primaire).
class DakarTechLogo extends StatelessWidget {
  const DakarTechLogo({
    super.key,
    this.size = 80,
    this.backgroundColor = AppColors.primarySoft,
    this.iconColor = AppColors.primary,
  });

  final double size;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(AppIcons.school, size: size * 0.5, color: iconColor),
    );
  }
}
